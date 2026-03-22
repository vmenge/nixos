use std::io::Write;
use std::path::{Path, PathBuf};
use std::process::Command;

use color_eyre::Result;
use color_eyre::eyre::eyre;
use time::OffsetDateTime;
use time::format_description::well_known::Rfc3339;

use crate::workstream::agent::{AgentRunnerRequest, SandboxAccess};
use crate::workstream::fs::{
    RunFileUpdate, clear_done_marker, clear_run_file, load_from_repo_root, update_run_file,
    write_done_marker, write_run_started,
};
use crate::workstream::model::{RunFile, TaskSnapshot};

const EXECUTE_PHASE: &str = "execute";
const REVIEW_PHASE: &str = "review";
pub const DEFAULT_STALL_LIMIT: usize = 10;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AgentKind {
    Codex,
    Claude,
}

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
        let base = format!("workstream-{} {workstream_name}", self.as_str());
        match self {
            Self::Execute => base,
            Self::Review => format!(
                "{base}. If the review passes and all tasks remain done, commit any remaining tracked closeout changes before outputting <promise>COMPLETE</promise>."
            ),
        }
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

pub struct NonoRunner {
    override_program: Option<PathBuf>,
    agent: AgentKind,
    unsafe_mode: bool,
}

impl NonoRunner {
    pub fn from_env(agent: AgentKind, unsafe_mode: bool) -> Self {
        Self {
            override_program: std::env::var("X_WS_AGENT_RUNNER_BIN")
                .ok()
                .map(PathBuf::from),
            agent,
            unsafe_mode,
        }
    }
}

impl StepRunner for NonoRunner {
    fn run_step(&self, request: StepRequest<'_>) -> Result<()> {
        let agent_request = AgentRunnerRequest::new(
            request.repo_root.to_path_buf(),
            request.phase.prompt(request.workstream_name),
        );
        let (program, args) = match self.agent {
            AgentKind::Codex => agent_request.inner_command(),
            AgentKind::Claude => agent_request.claude_command(),
        };
        let status = if self.unsafe_mode {
            println!("⚠️ unsafe mode enabled");
            println!("🚫 nono sandbox skipped");
            Command::new(program)
                .args(args)
                .current_dir(request.repo_root)
                .status()?
        } else if let Some(program) = &self.override_program {
            Command::new(program)
                .args(agent_request.helper_args())
                .status()?
        } else {
            let mut command = Command::new("nono");
            command.arg("run").arg("--silent");
            command
                .arg("--allow-file")
                .arg("/nix/var/nix/daemon-socket/socket")
                .arg("--allow")
                .arg("/tmp")
                .arg("--write-file")
                .arg("/dev/null")
                .arg("--allow-command")
                .arg("git");

            for sandbox_path in agent_request.sandbox_paths()? {
                let (flag, path) = match sandbox_path.access {
                    SandboxAccess::Read => ("--read", sandbox_path.path),
                    SandboxAccess::ReadWrite => ("--allow", sandbox_path.path),
                };
                command.arg(flag).arg(path);
            }

            command
                .arg("--")
                .arg(program)
                .args(args)
                .current_dir(request.repo_root)
                .status()?
        };
        if !status.success() {
            return Err(eyre!("nono exited with {status}"));
        }

        Ok(())
    }
}

pub fn run_workstream_loop(
    repo_root: &Path,
    workstream_name: &str,
    stall_limit: usize,
    runner: &dyn StepRunner,
    clock: &mut dyn Clock,
    output: &mut dyn Write,
) -> Result<()> {
    let workstream = load_from_repo_root(repo_root, workstream_name)?;
    clear_done_marker(&workstream.dir)?;
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

                if !progressed && stall_count >= stall_limit {
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
                    write_done_marker(&workstream.dir)?;
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
                if !made_net_progress && stall_count >= stall_limit {
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
    use std::os::unix::fs::PermissionsExt;

    #[test]
    fn nono_runner_prefers_explicit_override_runner() {
        let original = std::env::var_os("X_WS_AGENT_RUNNER_BIN");
        unsafe { std::env::set_var("X_WS_AGENT_RUNNER_BIN", "/tmp/fake-runner") };

        let runner = NonoRunner::from_env(AgentKind::Codex, false);

        assert_eq!(
            runner.override_program,
            Some(PathBuf::from("/tmp/fake-runner"))
        );
        assert_eq!(runner.agent, AgentKind::Codex);
        assert!(!runner.unsafe_mode);

        match original {
            Some(value) => unsafe { std::env::set_var("X_WS_AGENT_RUNNER_BIN", value) },
            None => unsafe { std::env::remove_var("X_WS_AGENT_RUNNER_BIN") },
        }
    }

    #[test]
    fn nono_runner_uses_direct_nono_by_default() {
        let original = std::env::var_os("X_WS_AGENT_RUNNER_BIN");
        unsafe { std::env::remove_var("X_WS_AGENT_RUNNER_BIN") };

        let runner = NonoRunner::from_env(AgentKind::Claude, true);

        assert_eq!(runner.override_program, None);
        assert_eq!(runner.agent, AgentKind::Claude);
        assert!(runner.unsafe_mode);

        if let Some(value) = original {
            unsafe { std::env::set_var("X_WS_AGENT_RUNNER_BIN", value) };
        }
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

    #[test]
    fn review_prompt_requires_committed_closeout_before_complete() {
        let prompt = StepPhase::Review.prompt("demo");

        assert!(prompt.starts_with("workstream-review demo"));
        assert!(prompt.contains("commit any remaining tracked closeout changes"));
        assert!(prompt.contains("<promise>COMPLETE</promise>"));
        assert_eq!(StepPhase::Execute.prompt("demo"), "workstream-execute demo");
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

    #[test]
    fn helper_override_runner_can_be_executable_file() -> Result<()> {
        let root = std::env::temp_dir().join(format!("xtask-loop-override-{}", std::process::id()));
        fs::create_dir_all(&root)?;
        let script = root.join("runner.sh");
        fs::write(&script, "#!/bin/sh\nexit 0\n")?;
        let mut permissions = fs::metadata(&script)?.permissions();
        permissions.set_mode(0o755);
        fs::set_permissions(&script, permissions)?;

        let request = AgentRunnerRequest::new(root.clone(), String::from("prompt"));
        let status = Command::new(&script).args(request.helper_args()).status()?;

        assert!(status.success());
        let _ = fs::remove_dir_all(&root);

        Ok(())
    }
}
