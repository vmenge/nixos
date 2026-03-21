use std::io::Write;
use std::path::{Path, PathBuf};
use std::process::Command;

use color_eyre::Result;
use color_eyre::eyre::eyre;
use time::OffsetDateTime;
use time::format_description::well_known::Rfc3339;

use crate::workstream::agent::AgentRunnerRequest;
use crate::workstream::fs::{
    RunFileUpdate, clear_run_file, load_from_repo_root, update_run_file, write_run_started,
};
use crate::workstream::model::{RunFile, TaskSnapshot};

const EXECUTE_PHASE: &str = "execute";
const REVIEW_PHASE: &str = "review";
const MAX_CONSECUTIVE_STALLS: usize = 3;

pub trait StepRunner {
    fn run_step(&self, request: StepRequest<'_>) -> Result<()>;
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum StepPhase {
    Execute,
    Review,
}

impl StepPhase {
    fn as_str(self) -> &'static str {
        match self {
            Self::Execute => EXECUTE_PHASE,
            Self::Review => REVIEW_PHASE,
        }
    }

    fn prompt(self, workstream_name: &str) -> String {
        format!("workstream-{} {workstream_name}", self.as_str())
    }
}

pub struct StepRequest<'a> {
    pub repo_root: &'a Path,
    pub workstream_name: &'a str,
    pub phase: StepPhase,
}

pub trait Clock {
    fn now(&mut self) -> String;
}

pub struct SystemClock;

impl Clock for SystemClock {
    fn now(&mut self) -> String {
        OffsetDateTime::now_utc()
            .replace_nanosecond(0)
            .unwrap_or_else(|_| OffsetDateTime::UNIX_EPOCH)
            .format(&Rfc3339)
            .unwrap_or_else(|_| String::from("1970-01-01T00:00:00Z"))
    }
}

pub struct HelperBinaryRunner {
    command: HelperCommand,
}

impl HelperBinaryRunner {
    pub fn from_env() -> Self {
        Self {
            command: discover_helper_command(
                std::env::var("X_WS_AGENT_RUNNER_BIN").ok().as_deref(),
                &std::env::current_exe().unwrap_or_else(|_| PathBuf::from("x")),
                Path::new(env!("CARGO_MANIFEST_DIR")),
            ),
        }
    }
}

impl StepRunner for HelperBinaryRunner {
    fn run_step(&self, request: StepRequest<'_>) -> Result<()> {
        let agent_request = AgentRunnerRequest::new(
            request.repo_root.to_path_buf(),
            request.phase.prompt(request.workstream_name),
        );
        let status = Command::new(&self.command.program)
            .args(&self.command.base_args)
            .args(agent_request.helper_args())
            .status()?;
        if !status.success() {
            return Err(eyre!(
                "{} exited with {status}",
                self.command.program.display()
            ));
        }

        Ok(())
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
struct HelperCommand {
    program: PathBuf,
    base_args: Vec<String>,
}

fn discover_helper_command(
    explicit_program: Option<&str>,
    current_exe: &Path,
    manifest_dir: &Path,
) -> HelperCommand {
    if let Some(program) = explicit_program {
        return HelperCommand {
            program: PathBuf::from(program),
            base_args: Vec::new(),
        };
    }

    if let Some(parent) = current_exe.parent() {
        let sibling = parent.join("ws-agent-runner");
        if sibling.is_file() {
            return HelperCommand {
                program: sibling,
                base_args: Vec::new(),
            };
        }
    }

    HelperCommand {
        program: PathBuf::from("cargo"),
        base_args: vec![
            String::from("run"),
            String::from("--quiet"),
            String::from("--manifest-path"),
            manifest_dir.join("Cargo.toml").display().to_string(),
            String::from("--features"),
            String::from("ws-agent-runner"),
            String::from("--bin"),
            String::from("ws-agent-runner"),
            String::from("--"),
        ],
    }
}

pub fn run_workstream_loop(
    repo_root: &Path,
    workstream_name: &str,
    runner: &dyn StepRunner,
    clock: &mut dyn Clock,
    output: &mut dyn Write,
) -> Result<()> {
    let workstream = load_from_repo_root(repo_root, workstream_name)?;
    let mut snapshot = workstream.task_snapshot();
    let mut phase = next_phase(&snapshot);
    let mut cycle_start = snapshot.clone();
    let mut run = write_run_started(
        &workstream.dir,
        std::process::id(),
        phase.as_str(),
        &clock.now(),
        &snapshot,
    )?;
    let mut clear_on_drop = RunFileCleaner::new(workstream.dir.clone());
    writeln!(
        output,
        "🧭 phase={} iteration={} done={}/{}",
        phase.as_str(),
        run.iteration,
        snapshot.completed_count,
        snapshot.total_count
    )?;

    loop {
        let before = snapshot.clone();
        writeln!(
            output,
            "🤖 launching {} agent for `{}`",
            phase.as_str(),
            workstream_name
        )?;
        runner.run_step(StepRequest {
            repo_root,
            workstream_name,
            phase,
        })?;

        let workstream = load_from_repo_root(repo_root, workstream_name)?;
        snapshot = workstream.task_snapshot();

        match phase {
            StepPhase::Execute => {
                let progressed = snapshot.undone_task_ids != before.undone_task_ids;
                let stall_count = if snapshot.undone_task_ids.is_empty() {
                    run.stall_count
                } else if progressed {
                    0
                } else {
                    run.stall_count + 1
                };
                run =
                    update_pass_state(&workstream.dir, &run, phase, clock, stall_count, &snapshot)?;

                if !snapshot.undone_task_ids.is_empty() {
                    writeln!(
                        output,
                        "📊 remaining undone tasks after execute: {}",
                        join_task_ids(&snapshot)
                    )?;
                }

                if !progressed && stall_count >= MAX_CONSECUTIVE_STALLS {
                    return Err(eyre!(
                        "workstream `{workstream_name}` stalled after {stall_count} consecutive execute passes; remaining undone tasks: {}",
                        join_task_ids(&snapshot)
                    ));
                }

                if snapshot.undone_task_ids.is_empty() {
                    writeln!(output, "🧪 all tasks are done; starting review")?;
                    phase = StepPhase::Review;
                    run = transition_phase(&workstream.dir, &run, phase, clock, &snapshot)?;
                    writeln!(
                        output,
                        "🧭 phase={} iteration={} done={}/{}",
                        phase.as_str(),
                        run.iteration,
                        snapshot.completed_count,
                        snapshot.total_count
                    )?;
                } else {
                    cycle_start = snapshot.clone();
                }
            }
            StepPhase::Review => {
                if snapshot.undone_task_ids.is_empty() {
                    update_pass_state(&workstream.dir, &run, phase, clock, 0, &snapshot)?;
                    writeln!(
                        output,
                        "✅ workstream `{workstream_name}` completed after review"
                    )?;
                    clear_run_file(&workstream.dir)?;
                    clear_on_drop.disarm();
                    return Ok(());
                }

                let made_net_progress = snapshot.completed_count > cycle_start.completed_count;
                let stall_count = if made_net_progress {
                    0
                } else {
                    run.stall_count + 1
                };
                run =
                    update_pass_state(&workstream.dir, &run, phase, clock, stall_count, &snapshot)?;
                writeln!(
                    output,
                    "🔁 review introduced new undone tasks: {}",
                    join_task_ids(&snapshot)
                )?;
                if !made_net_progress && stall_count >= MAX_CONSECUTIVE_STALLS {
                    return Err(eyre!(
                        "workstream `{workstream_name}` made no net progress after {stall_count} execute/review cycles; remaining undone tasks: {}",
                        join_task_ids(&snapshot)
                    ));
                }
                phase = StepPhase::Execute;
                run = transition_phase(&workstream.dir, &run, phase, clock, &snapshot)?;
                writeln!(
                    output,
                    "🧭 phase={} iteration={} done={}/{}",
                    phase.as_str(),
                    run.iteration,
                    snapshot.completed_count,
                    snapshot.total_count
                )?;
                cycle_start = snapshot.clone();
            }
        }
    }
}

fn next_phase(snapshot: &TaskSnapshot) -> StepPhase {
    if snapshot.undone_task_ids.is_empty() {
        StepPhase::Review
    } else {
        StepPhase::Execute
    }
}

fn update_pass_state(
    workstream_dir: &Path,
    current: &RunFile,
    phase: StepPhase,
    clock: &mut dyn Clock,
    stall_count: usize,
    snapshot: &TaskSnapshot,
) -> Result<RunFile> {
    update_run_file(
        workstream_dir,
        current,
        RunFileUpdate {
            phase: String::from(phase.as_str()),
            updated_at: clock.now(),
            iteration: current.iteration + 1,
            stall_count,
            completed_tasks: snapshot.completed_count,
            total_tasks: snapshot.total_count,
        },
    )
}

fn transition_phase(
    workstream_dir: &Path,
    current: &RunFile,
    phase: StepPhase,
    clock: &mut dyn Clock,
    snapshot: &TaskSnapshot,
) -> Result<RunFile> {
    update_run_file(
        workstream_dir,
        current,
        RunFileUpdate {
            phase: String::from(phase.as_str()),
            updated_at: clock.now(),
            iteration: current.iteration,
            stall_count: current.stall_count,
            completed_tasks: snapshot.completed_count,
            total_tasks: snapshot.total_count,
        },
    )
}

fn join_task_ids(snapshot: &TaskSnapshot) -> String {
    snapshot
        .undone_task_ids
        .iter()
        .cloned()
        .collect::<Vec<_>>()
        .join(", ")
}

struct RunFileCleaner {
    workstream_dir: PathBuf,
    armed: bool,
}

impl RunFileCleaner {
    fn new(workstream_dir: PathBuf) -> Self {
        Self {
            workstream_dir,
            armed: true,
        }
    }

    fn disarm(&mut self) {
        self.armed = false;
    }
}

impl Drop for RunFileCleaner {
    fn drop(&mut self) {
        if self.armed {
            let _ = clear_run_file(&self.workstream_dir);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;

    #[test]
    fn helper_discovery_prefers_explicit_override() -> Result<()> {
        let fixture = LoopFixture::new()?;

        let command = discover_helper_command(
            Some("/tmp/custom-runner"),
            &fixture.current_exe,
            &fixture.manifest_dir,
        );

        assert_eq!(command.program, PathBuf::from("/tmp/custom-runner"));
        assert!(command.base_args.is_empty());

        Ok(())
    }

    #[test]
    fn helper_discovery_uses_sibling_helper_when_present() -> Result<()> {
        let fixture = LoopFixture::new()?;
        let sibling = fixture
            .current_exe
            .parent()
            .unwrap()
            .join("ws-agent-runner");
        fs::write(&sibling, "#!/bin/sh\n")?;

        let command = discover_helper_command(None, &fixture.current_exe, &fixture.manifest_dir);

        assert_eq!(command.program, sibling);
        assert!(command.base_args.is_empty());

        Ok(())
    }

    #[test]
    fn helper_discovery_falls_back_to_cargo_run() -> Result<()> {
        let fixture = LoopFixture::new()?;

        let command = discover_helper_command(None, &fixture.current_exe, &fixture.manifest_dir);

        assert_eq!(command.program, PathBuf::from("cargo"));
        assert_eq!(
            command.base_args,
            vec![
                String::from("run"),
                String::from("--quiet"),
                String::from("--manifest-path"),
                fixture
                    .manifest_dir
                    .join("Cargo.toml")
                    .display()
                    .to_string(),
                String::from("--features"),
                String::from("ws-agent-runner"),
                String::from("--bin"),
                String::from("ws-agent-runner"),
                String::from("--"),
            ]
        );

        Ok(())
    }

    #[test]
    fn system_clock_now_uses_rfc3339_utc_format() {
        let mut clock = SystemClock;
        let timestamp = clock.now();

        assert!(
            looks_like_rfc3339_utc(&timestamp),
            "expected RFC3339 UTC timestamp, got: {timestamp}"
        );
    }

    fn looks_like_rfc3339_utc(timestamp: &str) -> bool {
        let bytes = timestamp.as_bytes();
        if bytes.len() != 20 {
            return false;
        }

        matches_separator(bytes, 4, b'-')
            && matches_separator(bytes, 7, b'-')
            && matches_separator(bytes, 10, b'T')
            && matches_separator(bytes, 13, b':')
            && matches_separator(bytes, 16, b':')
            && matches_separator(bytes, 19, b'Z')
            && digits(bytes, &[0, 1, 2, 3, 5, 6, 8, 9, 11, 12, 14, 15, 17, 18])
    }

    fn matches_separator(bytes: &[u8], index: usize, expected: u8) -> bool {
        bytes.get(index).copied() == Some(expected)
    }

    fn digits(bytes: &[u8], indexes: &[usize]) -> bool {
        indexes
            .iter()
            .all(|index| bytes.get(*index).is_some_and(u8::is_ascii_digit))
    }

    struct LoopFixture {
        root: PathBuf,
        current_exe: PathBuf,
        manifest_dir: PathBuf,
    }

    impl LoopFixture {
        fn new() -> Result<Self> {
            let root = std::env::temp_dir().join(format!(
                "xtask-loop-{}-{}",
                std::process::id(),
                std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)?
                    .as_nanos()
            ));
            let current_exe = root.join("target/debug/x");
            let manifest_dir = root.join("xtask");
            fs::create_dir_all(current_exe.parent().unwrap())?;
            fs::create_dir_all(&manifest_dir)?;
            fs::write(manifest_dir.join("Cargo.toml"), "[package]\nname = \"x\"\n")?;

            Ok(Self {
                root,
                current_exe,
                manifest_dir,
            })
        }
    }

    impl Drop for LoopFixture {
        fn drop(&mut self) {
            let _ = fs::remove_dir_all(&self.root);
        }
    }
}
