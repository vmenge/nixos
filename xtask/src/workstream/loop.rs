use std::io::Write;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::time::{SystemTime, UNIX_EPOCH};

use color_eyre::Result;
use color_eyre::eyre::eyre;

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
        SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs()
            .to_string()
    }
}

pub struct HelperBinaryRunner {
    program: String,
}

impl HelperBinaryRunner {
    pub fn from_env() -> Self {
        Self {
            program: std::env::var("X_WS_AGENT_RUNNER_BIN")
                .unwrap_or_else(|_| String::from("ws-agent-runner")),
        }
    }
}

impl StepRunner for HelperBinaryRunner {
    fn run_step(&self, request: StepRequest<'_>) -> Result<()> {
        let agent_request = AgentRunnerRequest::new(
            request.repo_root.to_path_buf(),
            request.phase.prompt(request.workstream_name),
        );
        let (program, args) = agent_request.helper_command(&self.program);
        let status = Command::new(&program).args(&args).status()?;
        if !status.success() {
            return Err(eyre!("{program} exited with {status}"));
        }

        Ok(())
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
    let mut run = write_run_started(
        &workstream.dir,
        std::process::id(),
        phase.as_str(),
        &clock.now(),
        &snapshot,
    )?;
    let mut clear_on_drop = RunFileCleaner::new(workstream.dir.clone());

    loop {
        let before = snapshot.clone();
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
                let stall_count = if progressed { 0 } else { run.stall_count + 1 };
                run =
                    update_pass_state(&workstream.dir, &run, phase, clock, stall_count, &snapshot)?;

                if !snapshot.undone_task_ids.is_empty() {
                    writeln!(
                        output,
                        "remaining undone tasks after execute: {}",
                        join_task_ids(&snapshot)
                    )?;
                }

                if !progressed && stall_count >= MAX_CONSECUTIVE_STALLS {
                    return Err(eyre!(
                        "no progress after {stall_count} consecutive execute passes"
                    ));
                }

                if snapshot.undone_task_ids.is_empty() {
                    phase = StepPhase::Review;
                    run = transition_phase(&workstream.dir, &run, phase, clock, &snapshot)?;
                }
            }
            StepPhase::Review => {
                run = update_pass_state(&workstream.dir, &run, phase, clock, 0, &snapshot)?;

                if snapshot.undone_task_ids.is_empty() {
                    clear_run_file(&workstream.dir)?;
                    clear_on_drop.disarm();
                    return Ok(());
                }

                writeln!(
                    output,
                    "review introduced new undone tasks: {}",
                    join_task_ids(&snapshot)
                )?;
                phase = StepPhase::Execute;
                run = transition_phase(&workstream.dir, &run, phase, clock, &snapshot)?;
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
