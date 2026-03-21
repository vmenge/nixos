use std::fs;
use std::io;
use std::path::Path;

use color_eyre::{Result, eyre::eyre};

use crate::workstream::fs::{load_from_dir, load_from_repo_root};
use crate::workstream::r#loop::{HelperBinaryRunner, SystemClock, run_workstream_loop};

const ACTIVITY_SUMMARY_LIMIT: usize = 46;
const ANSI_RESET: &str = "\x1b[0m";
const ANSI_BOLD: &str = "\x1b[1m";
const ANSI_GREEN: &str = "\x1b[32m";
const ANSI_YELLOW: &str = "\x1b[33m";
const ANSI_RED: &str = "\x1b[31m";

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
    println!("🔎 scanning workstreams in {}", workstreams_dir.display());
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
    println!(
        "📚 found {} workstream{}",
        rows.len(),
        if rows.len() == 1 { "" } else { "s" }
    );

    for line in format_ls_table(&rows) {
        println!("{line}");
    }

    Ok(())
}

fn run_rm(process_probe: &dyn ProcessProbe, workstream_name: &str) -> Result<()> {
    let repo_root = std::env::current_dir()?;
    println!("🗑️ removing workstream `{workstream_name}`");
    let workstream = load_from_repo_root(&repo_root, workstream_name)?;

    if has_live_run_lock(&workstream.run.phase, workstream.run.pid, process_probe) {
        println!(
            "🚫 refusing to remove `{workstream_name}` because pid {} is still live",
            workstream.run.pid
        );
        return Err(eyre!(
            "refusing to remove workstream `{workstream_name}` because workstream `{workstream_name}` is running with live pid {}",
            workstream.run.pid
        ));
    }

    fs::remove_dir_all(&workstream.dir)?;
    println!("✅ removed workstream `{workstream_name}`");
    Ok(())
}

fn run_exec(workstream_name: &str) -> Result<()> {
    let repo_root = std::env::current_dir()?;
    println!("🚀 starting workstream `{workstream_name}`");
    let workstream = load_from_repo_root(&repo_root, workstream_name)?;
    if has_live_run_lock(&workstream.run.phase, workstream.run.pid, &ProcFsProbe) {
        println!(
            "🚫 refusing to start `{workstream_name}` because pid {} already holds the lock",
            workstream.run.pid
        );
        return Err(eyre!(
            "refusing to start workstream `{workstream_name}` because it already has a live run.json lock for pid {}",
            workstream.run.pid
        ));
    }

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

fn format_ls_table(rows: &[ListRow]) -> Vec<String> {
    let name_width = rows
        .iter()
        .map(|row| row.name.len())
        .max()
        .unwrap_or(0)
        .max("NAME".len());
    let status_width = rows
        .iter()
        .map(|row| row.status.len())
        .max()
        .unwrap_or(0)
        .max("STATUS".len());
    let done_width = rows
        .iter()
        .map(|row| row.completed.len())
        .max()
        .unwrap_or(0)
        .max("DONE".len());

    let mut lines = vec![format!(
        "{}  {}  {}  {}",
        style_bold_cell(format!("{:<name_width$}", "NAME")),
        style_bold_cell(format!("{:<status_width$}", "STATUS")),
        style_bold_cell(format!("{:<done_width$}", "DONE")),
        style_bold_cell(String::from("LAST ACTIVITY"))
    )];

    for row in rows {
        let name = format!("{:<name_width$}", row.name);
        let status = format!("{:<status_width$}", row.status);
        let done = format!("{:<done_width$}", row.completed);
        lines.push(format!(
            "{}  {}  {}  {}",
            name,
            style_status_cell(&status),
            style_done_cell(&done),
            row.last_activity
        ));
    }

    lines
}

fn style_bold_cell(text: String) -> String {
    format!("{ANSI_BOLD}{text}{ANSI_RESET}")
}

fn style_status_cell(text: &str) -> String {
    let trimmed = text.trim();
    match trimmed {
        "idle" => format!("{ANSI_GREEN}{text}{ANSI_RESET}"),
        "running:execute" | "running:review" => {
            format!("{ANSI_BOLD}{ANSI_YELLOW}{text}{ANSI_RESET}")
        }
        "stale-lock" | "error" => format!("{ANSI_BOLD}{ANSI_RED}{text}{ANSI_RESET}"),
        _ => text.to_owned(),
    }
}

fn style_done_cell(text: &str) -> String {
    if is_complete_done_cell(text) {
        text.to_owned()
    } else {
        format!("{ANSI_BOLD}{text}{ANSI_RESET}")
    }
}

fn is_complete_done_cell(text: &str) -> bool {
    let trimmed = text.trim();
    let Some((completed, total)) = trimmed.split_once('/') else {
        return false;
    };

    completed == total
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

    #[test]
    fn formats_ws_ls_table_with_padded_columns() {
        let rows = vec![
            ListRow {
                name: String::from("alpha"),
                status: String::from("idle"),
                completed: String::from("1/3"),
                last_activity: String::from("short note"),
            },
            ListRow {
                name: String::from("demo-long"),
                status: String::from("running:execute"),
                completed: String::from("12/120"),
                last_activity: String::from("a much longer activity summary"),
            },
        ];

        let lines = format_ls_table(&rows);

        assert_eq!(
            lines[0],
            "\u{1b}[1mNAME     \u{1b}[0m  \u{1b}[1mSTATUS         \u{1b}[0m  \u{1b}[1mDONE  \u{1b}[0m  \u{1b}[1mLAST ACTIVITY\u{1b}[0m"
        );
        assert_eq!(
            lines[1],
            "alpha      \u{1b}[32midle           \u{1b}[0m  \u{1b}[1m1/3   \u{1b}[0m  short note"
        );
        assert_eq!(
            lines[2],
            "demo-long  \u{1b}[1m\u{1b}[33mrunning:execute\u{1b}[0m  \u{1b}[1m12/120\u{1b}[0m  a much longer activity summary"
        );
    }

    #[test]
    fn styles_error_and_stale_statuses_in_red() {
        assert_eq!(
            style_status_cell("stale-lock"),
            "\u{1b}[1m\u{1b}[31mstale-lock\u{1b}[0m"
        );
        assert_eq!(
            style_status_cell("error"),
            "\u{1b}[1m\u{1b}[31merror\u{1b}[0m"
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
