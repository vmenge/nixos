use std::fs;
use std::io;
use std::path::Path;

use color_eyre::{Result, eyre::eyre};

use crate::workstream::fs::{load_from_dir, load_from_repo_root};
use crate::workstream::r#loop::{HelperBinaryRunner, SystemClock, run_workstream_loop};

const ACTIVITY_SUMMARY_LIMIT: usize = 46;

#[derive(clap::Args, Debug)]
pub struct Args {
    #[command(subcommand)]
    pub subcmd: Subcmd,
}

#[derive(clap::Subcommand, Debug)]
pub enum Subcmd {
    /// List workstreams
    Ls,
    /// Remove a workstream
    Rm(TargetArgs),
    /// Execute a workstream
    Exec(TargetArgs),
}

#[derive(clap::Args, Debug)]
pub struct TargetArgs {
    pub workstream_name: String,
}

pub fn run(args: Args) -> Result<()> {
    match args.subcmd {
        Subcmd::Ls => run_ls(&ProcFsProbe),
        Subcmd::Rm(TargetArgs { workstream_name }) => run_rm(&ProcFsProbe, &workstream_name),
        Subcmd::Exec(TargetArgs { workstream_name }) => run_exec(&workstream_name),
    }
}

fn run_ls(process_probe: &dyn ProcessProbe) -> Result<()> {
    let repo_root = std::env::current_dir()?;
    let mut rows = Vec::new();
    let workstreams_dir = repo_root.join(".workstreams");
    if workstreams_dir.exists() {
        for entry in fs::read_dir(&workstreams_dir)? {
            let entry = entry?;
            let path = entry.path();
            if !path.is_dir() {
                continue;
            }

            match load_from_dir(&path) {
                Ok(workstream) => {
                    let snapshot = workstream.task_snapshot();
                    rows.push(ListRow {
                        name: workstream.name,
                        status: String::from(classify_status(
                            &workstream.run.phase,
                            workstream.run.pid,
                            process_probe,
                        )),
                        completed: format!("{}/{}", snapshot.completed_count, snapshot.total_count),
                        last_activity: latest_activity_message(&workstream.activity),
                    });
                }
                Err(error) => rows.push(ListRow {
                    name: entry.file_name().to_string_lossy().into_owned(),
                    status: String::from("error"),
                    completed: String::from("-"),
                    last_activity: truncate_summary(&error.to_string()),
                }),
            }
        }
    }

    rows.sort_by(|left, right| left.name.cmp(&right.name));

    println!("NAME\tSTATUS\tDONE\tLAST ACTIVITY");
    for row in rows {
        println!(
            "{}\t{}\t{}\t{}",
            row.name, row.status, row.completed, row.last_activity
        );
    }

    Ok(())
}

fn run_rm(process_probe: &dyn ProcessProbe, workstream_name: &str) -> Result<()> {
    let repo_root = std::env::current_dir()?;
    let workstream = load_from_repo_root(&repo_root, workstream_name)?;

    if has_live_run_lock(&workstream.run.phase, workstream.run.pid, process_probe) {
        return Err(eyre!(
            "refusing to remove workstream `{workstream_name}` because workstream `{workstream_name}` is running with live pid {}",
            workstream.run.pid
        ));
    }

    fs::remove_dir_all(&workstream.dir)?;
    Ok(())
}

fn run_exec(workstream_name: &str) -> Result<()> {
    let repo_root = std::env::current_dir()?;
    let runner = HelperBinaryRunner::from_env();
    let mut clock = SystemClock;
    let stdout = io::stdout();
    let mut output = stdout.lock();

    run_workstream_loop(
        &repo_root,
        workstream_name,
        &runner,
        &mut clock,
        &mut output,
    )
}

fn latest_activity_message(activity: &[crate::workstream::model::ActivityEntry]) -> String {
    activity
        .iter()
        .max_by(|left, right| left.at.cmp(&right.at))
        .map(|entry| truncate_summary(&entry.message))
        .unwrap_or_else(|| String::from("-"))
}

fn classify_status(phase: &str, pid: u32, process_probe: &dyn ProcessProbe) -> &'static str {
    match phase {
        "execute" if pid != 0 && process_probe.is_alive(pid) => "running:execute",
        "review" if pid != 0 && process_probe.is_alive(pid) => "running:review",
        "execute" | "review" if pid != 0 => "stale-lock",
        _ => "idle",
    }
}

fn has_live_run_lock(phase: &str, pid: u32, process_probe: &dyn ProcessProbe) -> bool {
    matches!(
        classify_status(phase, pid, process_probe),
        "running:execute" | "running:review"
    )
}

fn truncate_summary(message: &str) -> String {
    if message.chars().count() <= ACTIVITY_SUMMARY_LIMIT {
        return message.to_owned();
    }

    let mut truncated = message
        .chars()
        .take(ACTIVITY_SUMMARY_LIMIT.saturating_sub(3))
        .collect::<String>();
    truncated.push_str("...");
    truncated
}

struct ListRow {
    name: String,
    status: String,
    completed: String,
    last_activity: String,
}

trait ProcessProbe {
    fn is_alive(&self, pid: u32) -> bool;
}

struct ProcFsProbe;

impl ProcessProbe for ProcFsProbe {
    fn is_alive(&self, pid: u32) -> bool {
        pid != 0 && Path::new("/proc").join(pid.to_string()).exists()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn classifies_execute_phase_as_running_when_pid_is_alive() {
        assert_eq!(
            classify_status("execute", 4242, &FakeProcessProbe::alive()),
            "running:execute"
        );
    }

    #[test]
    fn classifies_review_phase_as_running_when_pid_is_alive() {
        assert_eq!(
            classify_status("review", 4242, &FakeProcessProbe::alive()),
            "running:review"
        );
    }

    #[test]
    fn classifies_dead_in_progress_pid_as_stale_lock() {
        assert_eq!(
            classify_status("execute", 4242, &FakeProcessProbe::dead()),
            "stale-lock"
        );
    }

    struct FakeProcessProbe {
        alive: bool,
    }

    impl FakeProcessProbe {
        fn alive() -> Self {
            Self { alive: true }
        }

        fn dead() -> Self {
            Self { alive: false }
        }
    }

    impl ProcessProbe for FakeProcessProbe {
        fn is_alive(&self, _pid: u32) -> bool {
            self.alive
        }
    }
}
