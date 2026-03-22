use std::fs;
use std::io::ErrorKind;
use std::os::unix::fs::PermissionsExt;
use std::path::PathBuf;
use std::process::{Command, Output};
use std::time::{SystemTime, UNIX_EPOCH};

use color_eyre::Result;
use x::workstream::agent::AgentRunnerRequest;
use x::workstream::fs::{
    RunFileUpdate, clear_run_file, load_from_repo_root, update_run_file, write_run_started,
};
use x::workstream::model::{RunFile, TaskSnapshot};

const TASKS_EXAMPLE: &str = include_str!(concat!(
    env!("CARGO_MANIFEST_DIR"),
    "/../dotfiles/.agents/skills/workstreams/about/tasks.example.json"
));
const ACTIVITY_EXAMPLE: &str = include_str!(concat!(
    env!("CARGO_MANIFEST_DIR"),
    "/../dotfiles/.agents/skills/workstreams/about/activity.example.json"
));
const RUN_EXAMPLE: &str = r#"{
  "pid": 4242,
  "started_at": "2026-03-21T09:15:00Z",
  "updated_at": "2026-03-21T09:18:30Z",
  "phase": "execute",
  "iteration": 3,
  "stall_count": 1,
  "completed_tasks": 4,
  "total_tasks": 11
}
"#;

#[test]
fn loads_workstream_files_and_builds_a_task_snapshot() -> Result<()> {
    let fixture = WorkstreamFixture::new("demo")?;

    let workstream = load_from_repo_root(&fixture.repo_root, "demo")?;
    let snapshot = workstream.task_snapshot();

    assert_eq!(workstream.name, "demo");
    assert_eq!(workstream.tasks.must_read_files.len(), 5);
    assert_eq!(workstream.activity.len(), 3);
    assert_eq!(workstream.run.pid, 4242);
    assert_eq!(workstream.run.started_at, "2026-03-21T09:15:00Z");
    assert_eq!(workstream.run.updated_at, "2026-03-21T09:18:30Z");
    assert_eq!(workstream.run.phase, "execute");
    assert_eq!(workstream.run.iteration, 3);
    assert_eq!(workstream.run.stall_count, 1);
    assert_eq!(workstream.run.completed_tasks, 4);
    assert_eq!(workstream.run.total_tasks, 11);
    assert_eq!(snapshot.completed_count, 0);
    assert_eq!(snapshot.total_count, 11);
    assert_eq!(
        snapshot.undone_task_ids.into_iter().collect::<Vec<_>>(),
        vec![
            String::from("NAV-W1-TA"),
            String::from("NAV-W1-TB"),
            String::from("NAV-W2-TA"),
            String::from("NAV-W2-TB"),
            String::from("NAV-W2-TC"),
            String::from("NAV-W3-TA"),
            String::from("NAV-W3-TB"),
            String::from("NAV-W3-TC"),
            String::from("NAV-W4-TA"),
            String::from("NAV-W4-TB"),
            String::from("NAV-W4-TC"),
        ]
    );

    Ok(())
}

#[test]
fn reports_invalid_json_with_file_context() -> Result<()> {
    for file_name in ["tasks.json", "activity.json", "run.json"] {
        let fixture = WorkstreamFixture::new("demo")?;
        fixture.write_invalid_json(file_name)?;

        let error = load_from_repo_root(&fixture.repo_root, "demo")
            .expect_err("malformed JSON should fail");
        let message = error.to_string();

        assert!(
            message.contains(file_name),
            "expected error to mention {file_name}, got: {message}"
        );
        assert!(
            message.contains(".workstreams/demo"),
            "expected error to mention the workstream path, got: {message}"
        );
    }

    Ok(())
}

#[test]
fn ws_ls_summarizes_idle_workstreams() -> Result<()> {
    let fixture = WorkstreamFixture::new("demo")?;
    fixture.write_tasks_json(&sample_tasks_json(1, 3))?;
    fixture.write_activity_json(
        r#"[
  {
    "agent": "agent-1",
    "at": "2026-03-21T09:00:00Z",
    "task": "NAV-W1-TA",
    "message": "Started the first task.",
    "next_step": "Keep going"
  },
  {
    "agent": "agent-1",
    "at": "2026-03-21T09:05:00Z",
    "task": "NAV-W1-TB",
    "message": "Finished the summary row.",
    "next_step": "Review output formatting"
  }
]"#,
    )?;
    fixture.write_run_json("{}")?;

    let output = fixture.run_ws_ls()?;
    let stdout = String::from_utf8_lossy(&output.stdout);

    assert!(
        output.status.success(),
        "expected `x ws ls` to succeed, stderr was: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    assert!(
        stdout.contains("🔎 scanning workstreams in"),
        "expected stdout to include a scan log, got: {stdout}"
    );
    assert!(
        stdout.contains("📚 found 1 workstream"),
        "expected stdout to include a workstream count log, got: {stdout}"
    );
    assert!(
        stdout.contains("demo"),
        "expected stdout to include workstream name, got: {stdout}"
    );
    assert!(
        stdout.contains("idle"),
        "expected stdout to include idle status, got: {stdout}"
    );
    assert!(
        stdout.contains("1/3"),
        "expected stdout to include completed task count, got: {stdout}"
    );
    assert!(
        stdout.contains("LAST UPDATE"),
        "expected stdout to include a last-update column, got: {stdout}"
    );
    assert!(
        stdout.contains("Finished the summary row."),
        "expected stdout to include latest activity message, got: {stdout}"
    );

    Ok(())
}

#[test]
fn ws_ls_shows_duration_for_running_workstreams() -> Result<()> {
    let fixture = WorkstreamFixture::new("demo")?;
    fixture.write_run_json(&format!(
        r#"{{
  "pid": {},
  "started_at": "2026-03-21T09:00:00Z",
  "updated_at": "2026-03-21T09:05:00Z",
  "phase": "execute",
  "iteration": 2,
  "stall_count": 0,
  "completed_tasks": 1,
  "total_tasks": 3
}}"#,
        std::process::id()
    ))?;

    let output = fixture.run_ws_ls()?;
    let stdout = String::from_utf8_lossy(&output.stdout);

    assert!(output.status.success(), "expected `x ws ls` to succeed");
    assert!(stdout.contains("DURATION"));
    assert!(stdout.contains("LAST UPDATE"));
    assert!(
        stdout.contains("ago"),
        "expected stdout to include relative last-update age, got: {stdout}"
    );

    Ok(())
}

#[test]
fn ws_ls_shows_done_only_for_completed_workstreams_with_done_markers() -> Result<()> {
    let fixture = WorkstreamFixture::new("done-ws")?;
    fixture.add_workstream("complete-no-marker")?;
    fixture.write_workstream_file("done-ws", "tasks.json", &sample_tasks_json(1, 1))?;
    fixture.write_workstream_file("done-ws", "run.json", "{}")?;
    fixture.write_workstream_file("complete-no-marker", "tasks.json", &sample_tasks_json(1, 1))?;
    fixture.write_workstream_file("complete-no-marker", "run.json", "{}")?;
    fixture.write_done_marker("done-ws")?;

    let output = fixture.run_ws_ls()?;
    let stdout = String::from_utf8_lossy(&output.stdout);
    let done_row = stdout
        .lines()
        .find(|line| line.contains("done-ws"))
        .expect("expected `done-ws` row");
    let complete_without_marker_row = stdout
        .lines()
        .find(|line| line.contains("complete-no-marker"))
        .expect("expected `complete-no-marker` row");

    assert!(output.status.success(), "expected `x ws ls` to succeed");
    assert!(
        done_row.contains("\u{1b}[34mdone"),
        "expected the done status to be styled blue, got: {done_row}"
    );
    assert!(
        complete_without_marker_row.contains("idle"),
        "expected a fully complete workstream without a done marker to stay idle, got: {complete_without_marker_row}"
    );
    assert!(
        !complete_without_marker_row.contains("done"),
        "expected a fully complete workstream without a done marker to avoid the done status, got: {complete_without_marker_row}"
    );

    Ok(())
}

#[test]
fn ws_ls_prefers_running_and_stale_lock_statuses_over_done_markers() -> Result<()> {
    let fixture = WorkstreamFixture::new("running")?;
    fixture.add_workstream("stale")?;
    fixture.write_workstream_file("running", "tasks.json", &sample_tasks_json(1, 1))?;
    fixture.write_workstream_file(
        "running",
        "run.json",
        &format!(
            r#"{{
  "pid": {},
  "phase": "execute"
}}"#,
            std::process::id()
        ),
    )?;
    fixture.write_workstream_file("stale", "tasks.json", &sample_tasks_json(1, 1))?;
    fixture.write_workstream_file(
        "stale",
        "run.json",
        r#"{
  "pid": 4242,
  "phase": "review"
}"#,
    )?;
    fixture.write_done_marker("running")?;
    fixture.write_done_marker("stale")?;

    let output = fixture.run_ws_ls()?;
    let stdout = String::from_utf8_lossy(&output.stdout);
    let running_row = stdout
        .lines()
        .find(|line| line.contains("running"))
        .expect("expected `running` row");
    let stale_row = stdout
        .lines()
        .find(|line| line.contains("stale"))
        .expect("expected `stale` row");

    assert!(output.status.success(), "expected `x ws ls` to succeed");
    assert!(
        running_row.contains("running:execute"),
        "expected a live execute lock to stay running, got: {running_row}"
    );
    assert!(
        stale_row.contains("stale-lock"),
        "expected a dead lock to stay stale-lock, got: {stale_row}"
    );
    assert!(
        !running_row.contains("done") && !stale_row.contains("done"),
        "expected done markers to be ignored for active or stale locks, got: {running_row} / {stale_row}"
    );

    Ok(())
}

#[test]
fn ws_ls_truncates_the_latest_activity_message() -> Result<()> {
    let fixture = WorkstreamFixture::new("demo")?;
    fixture.write_activity_json(
        r#"[
  {
    "agent": "agent-1",
    "at": "2026-03-21T09:10:00Z",
    "task": "NAV-W1-TA",
    "message": "This activity message is intentionally long so the listing needs to truncate it for a compact summary row.",
    "next_step": "Keep the output readable"
  }
]"#,
    )?;
    fixture.write_run_json("{}")?;

    let output = fixture.run_ws_ls()?;
    let stdout = String::from_utf8_lossy(&output.stdout);

    assert!(
        output.status.success(),
        "expected `x ws ls` to succeed, stderr was: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    assert!(
        stdout.contains("This activity message is intentionally long..."),
        "expected stdout to include a truncated activity message, got: {stdout}"
    );
    assert!(
        !stdout.contains(
            "This activity message is intentionally long so the listing needs to truncate it for a compact summary row."
        ),
        "expected stdout to omit the full activity message, got: {stdout}"
    );

    Ok(())
}

#[test]
fn ws_ls_keeps_broken_workstreams_local_to_their_row() -> Result<()> {
    let fixture = WorkstreamFixture::new("healthy")?;
    fixture.add_workstream("broken")?;
    fixture.write_workstream_file("broken", "tasks.json", "{ definitely not valid json")?;

    let output = fixture.run_ws_ls()?;
    let stdout = String::from_utf8_lossy(&output.stdout);

    assert!(
        output.status.success(),
        "expected `x ws ls` to succeed, stderr was: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    assert!(
        stdout.contains("healthy"),
        "expected stdout to include the healthy workstream, got: {stdout}"
    );
    assert!(
        stdout.contains("broken"),
        "expected stdout to include the broken workstream name, got: {stdout}"
    );
    assert!(
        stdout.contains("error"),
        "expected stdout to include an error status for the broken row, got: {stdout}"
    );

    Ok(())
}

#[test]
fn ws_info_shows_pretty_activity_view() -> Result<()> {
    let fixture = WorkstreamFixture::new("demo")?;
    fixture.write_tasks_json(&sample_tasks_json(1, 3))?;
    fixture.write_activity_json(
        r#"[
  {
    "agent": "agent-1",
    "at": "2026-03-21T09:00:00Z",
    "task": "NAV-W1-TA",
    "message": "Started the first task.",
    "next_step": "Keep going"
  },
  {
    "agent": "agent-2",
    "at": "2026-03-21T09:05:00Z",
    "task": "NAV-W1-TB",
    "message": "Finished the summary row.",
    "next_step": "Review output formatting"
  }
]"#,
    )?;
    fixture.write_run_json("{}")?;

    let output = fixture.run_ws_info("demo")?;
    let stdout = String::from_utf8_lossy(&output.stdout);

    assert!(
        output.status.success(),
        "expected `x ws info demo` to succeed"
    );
    assert!(stdout.contains("📝 activity"));
    assert!(stdout.contains("🕒 2026-03-21T09:00:00Z  🎯 NAV-W1-TA  🤖 agent-1"));
    assert!(stdout.contains("💬 Started the first task."));
    assert!(stdout.contains("➡️ Keep going"));
    assert!(stdout.contains("🕒 2026-03-21T09:05:00Z  🎯 NAV-W1-TB  🤖 agent-2"));
    assert!(stdout.contains("💬 Finished the summary row."));
    assert!(stdout.contains("➡️ Review output formatting"));
    assert!(stdout.contains("────────────────────────"));
    assert!(stdout.contains("🧵 workstream `demo`"));
    assert!(stdout.contains("📊 progress: 1/3 complete"));
    assert!(stdout.contains("🏃 status: idle"));
    assert!(stdout.contains("⏱️ duration:"));
    assert!(stdout.contains("🕓 last update:"));
    assert!(
        stdout.find("2026-03-21T09:00:00Z").unwrap() < stdout.find("2026-03-21T09:05:00Z").unwrap()
    );
    assert!(
        stdout.find("────────────────────────").unwrap()
            > stdout.find("2026-03-21T09:05:00Z").unwrap()
    );

    Ok(())
}

#[test]
fn ws_rm_deletes_a_stopped_workstream_directory() -> Result<()> {
    let fixture = WorkstreamFixture::new("demo")?;
    fixture.write_run_json("{}")?;

    let output = fixture.run_ws_rm("demo")?;
    let stdout = String::from_utf8_lossy(&output.stdout);

    assert!(
        output.status.success(),
        "expected `x ws rm demo` to succeed, stderr was: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    assert!(
        !fixture.workstream_dir("demo").exists(),
        "expected workstream directory to be removed"
    );
    assert!(
        stdout.contains("🗑️ removing workstream `demo`"),
        "expected stdout to include a remove start log, got: {stdout}"
    );
    assert!(
        stdout.contains("✅ removed workstream `demo`"),
        "expected stdout to include a remove success log, got: {stdout}"
    );

    Ok(())
}

#[test]
fn ws_rm_refuses_to_delete_a_live_workstream_directory() -> Result<()> {
    let fixture = WorkstreamFixture::new("demo")?;
    fixture.write_run_json(&format!(
        r#"{{
  "pid": {},
  "phase": "execute"
}}"#,
        std::process::id()
    ))?;

    let output = fixture.run_ws_rm("demo")?;
    let stderr = String::from_utf8_lossy(&output.stderr);

    assert!(
        !output.status.success(),
        "expected `x ws rm demo` to fail for a live workstream"
    );
    assert!(
        fixture.workstream_dir("demo").exists(),
        "expected workstream directory to remain in place"
    );
    assert!(
        stderr.contains("workstream `demo` is running"),
        "expected stderr to clearly say the workstream is running, got: {stderr}"
    );

    Ok(())
}

#[test]
fn ws_rejects_workstream_names_that_escape_the_workstreams_directory() -> Result<()> {
    let fixture = WorkstreamFixture::new("demo")?;
    let runner = fixture
        .install_scripted_runner("demo", &[ScriptedStep::review(sample_tasks_json(0, 0))])?;

    for (subcommand, name) in [
        ("rm", "../demo"),
        ("exec", "nested/demo"),
        ("exec", "/tmp/demo"),
    ] {
        let output =
            fixture.run_ws_command_with_optional_runner(subcommand, name, Some(&runner))?;
        let stderr = String::from_utf8_lossy(&output.stderr);

        assert!(
            !output.status.success(),
            "expected `x ws {subcommand} {name}` to fail"
        );
        assert!(
            stderr.contains("single directory name under .workstreams"),
            "expected stderr to explain invalid workstream naming, got: {stderr}"
        );
    }

    assert!(
        fixture.logged_prompts("demo")?.is_empty(),
        "expected invalid exec names to fail before invoking the runner"
    );

    Ok(())
}

#[test]
fn ws_exec_refuses_to_start_when_a_live_lock_already_exists() -> Result<()> {
    let fixture = WorkstreamFixture::new("demo")?;
    fixture.write_run_json(&format!(
        r#"{{
  "pid": {},
  "phase": "review"
}}"#,
        std::process::id()
    ))?;
    let runner = fixture
        .install_scripted_runner("demo", &[ScriptedStep::review(sample_tasks_json(1, 1))])?;

    let output = fixture.run_ws_exec_with_runner("demo", &runner)?;
    let stderr = String::from_utf8_lossy(&output.stderr);

    assert!(
        !output.status.success(),
        "expected `x ws exec demo` to fail when the workstream is already running"
    );
    assert!(
        stderr.contains("already has a live run.json lock"),
        "expected stderr to mention the live lock, got: {stderr}"
    );
    assert_eq!(
        fixture.logged_prompts("demo")?,
        Vec::<String>::new(),
        "expected a live lock to prevent any runner invocation"
    );

    Ok(())
}

#[test]
fn agent_runner_builds_the_required_inner_codex_command() {
    let request = AgentRunnerRequest::new(
        PathBuf::from("/repo/project"),
        String::from("Execute the next workstream step."),
    );
    let (program, args) = request.inner_command();

    assert_eq!(program, "codex");
    assert_eq!(
        args,
        vec![
            String::from("--ask-for-approval"),
            String::from("never"),
            String::from("exec"),
            String::from("--cd"),
            String::from("/repo/project"),
            String::from("--sandbox"),
            String::from("danger-full-access"),
            String::from("Execute the next workstream step."),
        ]
    );
}

#[test]
fn agent_runner_builds_the_required_inner_claude_command() {
    let request = AgentRunnerRequest::new(
        PathBuf::from("/repo/project"),
        String::from("Execute the next workstream step."),
    );
    let (program, args) = request.claude_command();

    assert_eq!(program, "claude");
    assert_eq!(
        args,
        vec![
            String::from("--dangerously-skip-permissions"),
            String::from("-p"),
            String::from("--add-dir"),
            String::from("/repo/project"),
            String::from("Execute the next workstream step."),
        ]
    );
}

#[test]
fn run_file_lifecycle_writes_updates_and_clears_state() -> Result<()> {
    let fixture = WorkstreamFixture::new("demo")?;
    let workstream_dir = fixture.workstream_dir("demo");
    let snapshot = TaskSnapshot {
        completed_count: 2,
        total_count: 5,
        undone_task_ids: Default::default(),
    };

    let started = write_run_started(
        &workstream_dir,
        4242,
        "execute",
        "2026-03-21T10:00:00Z",
        &snapshot,
    )?;

    assert_eq!(
        started,
        RunFile {
            pid: 4242,
            started_at: String::from("2026-03-21T10:00:00Z"),
            updated_at: String::from("2026-03-21T10:00:00Z"),
            phase: String::from("execute"),
            iteration: 0,
            stall_count: 0,
            completed_tasks: 2,
            total_tasks: 5,
        }
    );
    assert_eq!(
        load_from_repo_root(&fixture.repo_root, "demo")?.run,
        started
    );

    let updated = update_run_file(
        &workstream_dir,
        &started,
        RunFileUpdate {
            phase: String::from("execute"),
            updated_at: String::from("2026-03-21T10:04:00Z"),
            iteration: 3,
            stall_count: 1,
            completed_tasks: 4,
            total_tasks: 5,
        },
    )?;

    assert_eq!(
        updated,
        RunFile {
            updated_at: String::from("2026-03-21T10:04:00Z"),
            iteration: 3,
            stall_count: 1,
            completed_tasks: 4,
            ..started.clone()
        }
    );
    assert_eq!(
        load_from_repo_root(&fixture.repo_root, "demo")?.run,
        updated
    );

    clear_run_file(&workstream_dir)?;
    assert!(!workstream_dir.join("run.json").exists());
    assert_eq!(
        load_from_repo_root(&fixture.repo_root, "demo")?.run,
        RunFile::default()
    );

    Ok(())
}

#[test]
fn run_file_update_can_transition_between_phases() -> Result<()> {
    let fixture = WorkstreamFixture::new("demo")?;
    let workstream_dir = fixture.workstream_dir("demo");
    let snapshot = TaskSnapshot {
        completed_count: 1,
        total_count: 5,
        undone_task_ids: Default::default(),
    };

    let started = write_run_started(
        &workstream_dir,
        4242,
        "execute",
        "2026-03-21T10:00:00Z",
        &snapshot,
    )?;

    let updated = update_run_file(
        &workstream_dir,
        &started,
        RunFileUpdate {
            phase: String::from("review"),
            updated_at: String::from("2026-03-21T10:05:00Z"),
            iteration: 1,
            stall_count: 0,
            completed_tasks: 5,
            total_tasks: 5,
        },
    )?;

    assert_eq!(updated.phase, "review");
    assert_eq!(
        load_from_repo_root(&fixture.repo_root, "demo")?.run.phase,
        "review"
    );

    Ok(())
}

#[test]
fn ws_exec_repeats_execute_when_progress_is_made_but_work_remains() -> Result<()> {
    let fixture = WorkstreamFixture::new("demo")?;
    fixture.write_tasks_json(&sample_tasks_json(0, 3))?;
    let runner = fixture.install_scripted_runner(
        "demo",
        &[
            ScriptedStep::execute(sample_tasks_json(1, 3)),
            ScriptedStep::execute(sample_tasks_json(3, 3)),
            ScriptedStep::review(sample_tasks_json(3, 3)),
        ],
    )?;

    let output = fixture.run_ws_exec_with_runner("demo", &runner)?;
    let stdout = String::from_utf8_lossy(&output.stdout);

    assert!(
        output.status.success(),
        "expected `x ws exec demo` to succeed, stderr was: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    assert_eq!(
        fixture.logged_prompts("demo")?,
        vec![
            String::from("workstream-execute demo"),
            String::from("workstream-execute demo"),
            String::from("workstream-review demo"),
        ]
    );
    assert_eq!(
        fixture.logged_run_states("demo")?,
        vec![
            String::from("phase=execute iteration=0 stall=0"),
            String::from("phase=execute iteration=1 stall=0"),
            String::from("phase=review iteration=2 stall=0"),
        ]
    );
    assert!(
        stdout.contains("remaining undone tasks"),
        "expected stdout to mention unfinished work after the first execute pass, got: {stdout}"
    );

    Ok(())
}

#[test]
fn ws_exec_triggers_review_after_execute_reaches_all_done() -> Result<()> {
    let fixture = WorkstreamFixture::new("demo")?;
    fixture.write_tasks_json(&sample_tasks_json(0, 2))?;
    let runner = fixture.install_scripted_runner(
        "demo",
        &[
            ScriptedStep::execute(sample_tasks_json(2, 2)),
            ScriptedStep::review(sample_tasks_json(2, 2)),
        ],
    )?;

    let output = fixture.run_ws_exec_with_runner("demo", &runner)?;

    assert!(
        output.status.success(),
        "expected `x ws exec demo` to succeed, stderr was: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    assert_eq!(
        fixture.logged_prompts("demo")?,
        vec![
            String::from("workstream-execute demo"),
            String::from("workstream-review demo"),
        ]
    );
    assert_eq!(
        fixture.logged_run_states("demo")?,
        vec![
            String::from("phase=execute iteration=0 stall=0"),
            String::from("phase=review iteration=1 stall=0"),
        ]
    );

    Ok(())
}

#[test]
fn ws_exec_exits_success_when_review_keeps_all_tasks_done() -> Result<()> {
    let fixture = WorkstreamFixture::new("demo")?;
    fixture.write_tasks_json(&sample_tasks_json(0, 1))?;
    let runner = fixture.install_scripted_runner(
        "demo",
        &[
            ScriptedStep::execute(sample_tasks_json(1, 1)),
            ScriptedStep::review(sample_tasks_json(1, 1)),
        ],
    )?;

    let output = fixture.run_ws_exec_with_runner("demo", &runner)?;
    let stdout = String::from_utf8_lossy(&output.stdout);

    assert!(
        output.status.success(),
        "expected `x ws exec demo` to succeed, stderr was: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    assert!(
        !fixture.workstream_dir("demo").join("run.json").exists(),
        "expected run.json to be cleared after a successful review"
    );
    assert!(
        fixture.workstream_dir("demo").join("done").exists(),
        "expected a successful review to create the done marker"
    );
    assert_eq!(fixture.logged_prompts("demo")?.len(), 2);
    assert!(
        stdout.contains("🚀 starting workstream `demo`"),
        "expected stdout to include the exec start log, got: {stdout}"
    );
    assert!(
        stdout.contains("🤖 launching execute agent for `demo`"),
        "expected stdout to include an execute launch log, got: {stdout}"
    );
    assert!(
        stdout.contains("🧪 all tasks are done; starting review"),
        "expected stdout to include the review transition log, got: {stdout}"
    );
    assert!(
        stdout.contains("🤖 launching review agent for `demo`"),
        "expected stdout to include a review launch log, got: {stdout}"
    );
    assert!(
        stdout.contains("workstream `demo` completed after review"),
        "expected stdout to include a completion message after review, got: {stdout}"
    );

    Ok(())
}

#[test]
fn ws_exec_writes_done_marker_after_successful_review() -> Result<()> {
    let fixture = WorkstreamFixture::new("demo")?;
    fixture.write_tasks_json(&sample_tasks_json(0, 1))?;
    let runner = fixture.install_scripted_runner(
        "demo",
        &[
            ScriptedStep::execute(sample_tasks_json(1, 1)),
            ScriptedStep::review(sample_tasks_json(1, 1)),
        ],
    )?;

    let output = fixture.run_ws_exec_with_runner("demo", &runner)?;

    assert!(
        output.status.success(),
        "expected `x ws exec demo` to succeed, stderr was: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    assert!(
        fixture.workstream_dir("demo").join("done").exists(),
        "expected a done marker after successful review completion"
    );
    assert!(
        !fixture.workstream_dir("demo").join("run.json").exists(),
        "expected run.json to be cleared after writing the done marker"
    );

    Ok(())
}

#[test]
fn ws_exec_clears_stale_done_marker_before_rerun() -> Result<()> {
    let fixture = WorkstreamFixture::new("demo")?;
    fixture.write_tasks_json(&sample_tasks_json(0, 1))?;
    fixture.write_done_marker("demo")?;
    let runner = fixture.install_scripted_runner(
        "demo",
        &[
            ScriptedStep::execute(sample_tasks_json(0, 1)),
            ScriptedStep::execute(sample_tasks_json(0, 1)),
            ScriptedStep::execute(sample_tasks_json(0, 1)),
        ],
    )?;

    let output =
        fixture.run_ws_exec_with_runner_and_args("demo", &runner, &["--stall-limit", "3"])?;

    assert!(
        !output.status.success(),
        "expected the rerun fixture to fail after the scripted stalls"
    );
    assert_eq!(
        fixture.logged_done_states("demo")?,
        vec![
            String::from("missing"),
            String::from("missing"),
            String::from("missing"),
        ]
    );
    assert!(
        !fixture.workstream_dir("demo").join("done").exists(),
        "expected the stale done marker to stay cleared after the rerun starts"
    );

    Ok(())
}

#[test]
fn ws_exec_restarts_execution_when_review_adds_new_undone_tasks() -> Result<()> {
    let fixture = WorkstreamFixture::new("demo")?;
    fixture.write_tasks_json(&sample_tasks_json(0, 2))?;
    let runner = fixture.install_scripted_runner(
        "demo",
        &[
            ScriptedStep::execute(sample_tasks_json(2, 2)),
            ScriptedStep::review(sample_tasks_json_with_done(&[
                ("NAV-W1-T0", true),
                ("NAV-W1-T1", false),
            ])),
            ScriptedStep::execute(sample_tasks_json(2, 2)),
            ScriptedStep::review(sample_tasks_json(2, 2)),
        ],
    )?;

    let output = fixture.run_ws_exec_with_runner("demo", &runner)?;
    let stdout = String::from_utf8_lossy(&output.stdout);

    assert!(
        output.status.success(),
        "expected `x ws exec demo` to succeed, stderr was: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    assert_eq!(
        fixture.logged_prompts("demo")?,
        vec![
            String::from("workstream-execute demo"),
            String::from("workstream-review demo"),
            String::from("workstream-execute demo"),
            String::from("workstream-review demo"),
        ]
    );
    assert_eq!(
        fixture.logged_run_states("demo")?,
        vec![
            String::from("phase=execute iteration=0 stall=0"),
            String::from("phase=review iteration=1 stall=0"),
            String::from("phase=execute iteration=2 stall=0"),
            String::from("phase=review iteration=3 stall=0"),
        ]
    );
    assert!(
        stdout.contains("NAV-W1-T1"),
        "expected stdout to print newly undone tasks from review, got: {stdout}"
    );

    Ok(())
}

#[test]
fn ws_exec_fails_after_ten_consecutive_no_progress_passes_by_default() -> Result<()> {
    let fixture = WorkstreamFixture::new("demo")?;
    fixture.write_tasks_json(&sample_tasks_json(0, 2))?;
    let steps = repeated_execute_steps(10, sample_tasks_json(0, 2));
    let runner = fixture.install_scripted_runner("demo", &steps)?;

    let output = fixture.run_ws_exec_with_runner("demo", &runner)?;
    let stderr = String::from_utf8_lossy(&output.stderr);

    assert!(
        !output.status.success(),
        "expected `x ws exec demo` to fail after repeated stalls"
    );
    assert!(
        stderr.contains("workstream `demo` stalled"),
        "expected stderr to mention the stalled workstream, got: {stderr}"
    );
    assert!(
        stderr.contains("NAV-W1-T0, NAV-W1-T1"),
        "expected stderr to include remaining undone task ids, got: {stderr}"
    );
    assert_eq!(
        fixture.logged_prompts("demo")?,
        repeated_execute_prompts(10)
    );

    Ok(())
}

#[test]
fn ws_exec_honors_explicit_stall_limit_for_execute_stalls() -> Result<()> {
    let fixture = WorkstreamFixture::new("demo")?;
    fixture.write_tasks_json(&sample_tasks_json(0, 2))?;
    let steps = repeated_execute_steps(4, sample_tasks_json(0, 2));
    let runner = fixture.install_scripted_runner("demo", &steps)?;

    let output =
        fixture.run_ws_exec_with_runner_and_args("demo", &runner, &["--stall-limit", "4"])?;
    let stderr = String::from_utf8_lossy(&output.stderr);

    assert!(
        !output.status.success(),
        "expected `x ws exec demo --stall-limit 4` to fail after four repeated stalls"
    );
    assert!(
        stderr.contains("stalled after 4 consecutive execute passes"),
        "expected stderr to mention the explicit stall limit, got: {stderr}"
    );
    assert_eq!(fixture.logged_prompts("demo")?, repeated_execute_prompts(4));

    Ok(())
}

#[test]
fn ws_exec_resets_the_stall_counter_after_progress() -> Result<()> {
    let fixture = WorkstreamFixture::new("demo")?;
    fixture.write_tasks_json(&sample_tasks_json(0, 3))?;
    let runner = fixture.install_scripted_runner(
        "demo",
        &[
            ScriptedStep::execute(sample_tasks_json(0, 3)),
            ScriptedStep::execute(sample_tasks_json(1, 3)),
            ScriptedStep::execute(sample_tasks_json(1, 3)),
            ScriptedStep::execute(sample_tasks_json(1, 3)),
            ScriptedStep::execute(sample_tasks_json(1, 3)),
        ],
    )?;

    let output =
        fixture.run_ws_exec_with_runner_and_args("demo", &runner, &["--stall-limit", "3"])?;
    let stderr = String::from_utf8_lossy(&output.stderr);

    assert!(
        !output.status.success(),
        "expected `x ws exec demo` to fail only after stalls resume"
    );
    assert!(
        stderr.contains("workstream `demo` stalled"),
        "expected stderr to mention stalled progress, got: {stderr}"
    );
    assert_eq!(
        fixture.logged_run_states("demo")?,
        vec![
            String::from("phase=execute iteration=0 stall=0"),
            String::from("phase=execute iteration=1 stall=1"),
            String::from("phase=execute iteration=2 stall=0"),
            String::from("phase=execute iteration=3 stall=1"),
            String::from("phase=execute iteration=4 stall=2"),
        ]
    );

    Ok(())
}

#[test]
fn ws_exec_fails_after_ten_no_net_progress_execute_review_cycles_by_default() -> Result<()> {
    let fixture = WorkstreamFixture::new("demo")?;
    fixture.write_tasks_json(&sample_tasks_json(0, 1))?;
    let steps = repeated_no_net_progress_cycles(10);
    let runner = fixture.install_scripted_runner("demo", &steps)?;

    let output = fixture.run_ws_exec_with_runner("demo", &runner)?;
    let stderr = String::from_utf8_lossy(&output.stderr);

    assert!(
        !output.status.success(),
        "expected `x ws exec demo` to fail after repeated execute/review oscillation"
    );
    assert!(
        stderr.contains("no net progress"),
        "expected stderr to describe the no-net-progress livelock, got: {stderr}"
    );
    assert_eq!(
        fixture.logged_prompts("demo")?,
        repeated_execute_review_prompts(10)
    );

    Ok(())
}

#[test]
fn ws_exec_honors_explicit_stall_limit_for_execute_review_cycles() -> Result<()> {
    let fixture = WorkstreamFixture::new("demo")?;
    fixture.write_tasks_json(&sample_tasks_json(0, 1))?;
    let steps = repeated_no_net_progress_cycles(2);
    let runner = fixture.install_scripted_runner("demo", &steps)?;

    let output =
        fixture.run_ws_exec_with_runner_and_args("demo", &runner, &["--stall-limit", "2"])?;
    let stderr = String::from_utf8_lossy(&output.stderr);

    assert!(
        !output.status.success(),
        "expected `x ws exec demo --stall-limit 2` to fail after two no-net-progress cycles"
    );
    assert!(
        stderr.contains("made no net progress after 2 execute/review cycles"),
        "expected stderr to mention the explicit no-net-progress limit, got: {stderr}"
    );
    assert_eq!(
        fixture.logged_prompts("demo")?,
        repeated_execute_review_prompts(2)
    );

    Ok(())
}

#[test]
fn ws_queue_runs_workstreams_serially_in_argv_order() -> Result<()> {
    let fixture = WorkstreamFixture::new("alpha")?;
    fixture.add_workstream("beta")?;
    fixture.add_workstream("gamma")?;
    fixture.write_workstream_file("alpha", "tasks.json", &sample_tasks_json(0, 1))?;
    fixture.write_workstream_file("beta", "tasks.json", &sample_tasks_json(0, 1))?;
    fixture.write_workstream_file("gamma", "tasks.json", &sample_tasks_json(0, 1))?;
    let runner = fixture.install_queue_scripted_runner(&[
        (
            "alpha",
            &[
                ScriptedStep::execute(sample_tasks_json(1, 1)),
                ScriptedStep::review(sample_tasks_json(1, 1)),
            ],
        ),
        (
            "beta",
            &[
                ScriptedStep::execute(sample_tasks_json(1, 1)),
                ScriptedStep::review(sample_tasks_json(1, 1)),
            ],
        ),
        (
            "gamma",
            &[
                ScriptedStep::execute(sample_tasks_json(1, 1)),
                ScriptedStep::review(sample_tasks_json(1, 1)),
            ],
        ),
    ])?;

    let output =
        fixture.run_ws_queue_with_runner_and_args(&["alpha", "beta", "gamma"], &runner, &[])?;
    let stdout = String::from_utf8_lossy(&output.stdout);

    assert!(
        output.status.success(),
        "expected `x ws queue run alpha beta gamma --agent codex` to succeed, stderr was: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    assert_eq!(
        fixture.logged_global_order()?,
        vec![
            String::from("alpha:execute"),
            String::from("alpha:review"),
            String::from("beta:execute"),
            String::from("beta:review"),
            String::from("gamma:execute"),
            String::from("gamma:review"),
        ]
    );
    assert!(
        stdout.contains("queue completed 3/3 workstreams"),
        "expected stdout to include a success summary, got: {stdout}"
    );

    Ok(())
}

#[test]
fn ws_queue_stops_on_first_failed_workstream_and_reports_summary() -> Result<()> {
    let fixture = WorkstreamFixture::new("alpha")?;
    fixture.add_workstream("beta")?;
    fixture.add_workstream("gamma")?;
    fixture.write_workstream_file("alpha", "tasks.json", &sample_tasks_json(0, 1))?;
    fixture.write_workstream_file("beta", "tasks.json", &sample_tasks_json(0, 1))?;
    fixture.write_workstream_file("gamma", "tasks.json", &sample_tasks_json(0, 1))?;
    let runner = fixture.install_queue_scripted_runner(&[
        (
            "alpha",
            &[
                ScriptedStep::execute(sample_tasks_json(1, 1)),
                ScriptedStep::review(sample_tasks_json(1, 1)),
            ],
        ),
        (
            "beta",
            &[
                ScriptedStep::execute(sample_tasks_json(0, 1)),
                ScriptedStep::execute(sample_tasks_json(0, 1)),
            ],
        ),
        (
            "gamma",
            &[
                ScriptedStep::execute(sample_tasks_json(1, 1)),
                ScriptedStep::review(sample_tasks_json(1, 1)),
            ],
        ),
    ])?;

    let output = fixture.run_ws_queue_with_runner_and_args(
        &["alpha", "beta", "gamma"],
        &runner,
        &["--stall-limit", "2"],
    )?;
    let stdout = String::from_utf8_lossy(&output.stdout);
    let stderr = String::from_utf8_lossy(&output.stderr);

    assert!(
        !output.status.success(),
        "expected queue execution to fail when a queued workstream stalls"
    );
    assert!(
        stderr.contains("queue failed after completing 1 of 3 workstreams"),
        "expected stderr to include the partial completion count, got: {stderr}"
    );
    assert!(
        stderr.contains("failed workstream: beta"),
        "expected stderr to identify the failed workstream, got: {stderr}"
    );
    assert!(
        stderr.contains("completed workstreams: alpha"),
        "expected stderr to list completed workstreams, got: {stderr}"
    );
    assert_eq!(
        fixture.logged_global_order()?,
        vec![
            String::from("alpha:execute"),
            String::from("alpha:review"),
            String::from("beta:execute"),
            String::from("beta:execute"),
        ]
    );
    assert!(
        fixture.logged_prompts("gamma")?.is_empty(),
        "expected the queue to stop before starting gamma"
    );
    assert!(
        stdout.contains("🚀 queue starting"),
        "expected stdout to include the queue start log, got: {stdout}"
    );

    Ok(())
}

#[test]
fn ws_queue_passes_through_explicit_stall_limit() -> Result<()> {
    let fixture = WorkstreamFixture::new("alpha")?;
    fixture.write_workstream_file("alpha", "tasks.json", &sample_tasks_json(0, 1))?;
    let steps = repeated_execute_steps(4, sample_tasks_json(0, 1));
    let runner = fixture.install_queue_scripted_runner(&[("alpha", &steps)])?;

    let output =
        fixture.run_ws_queue_with_runner_and_args(&["alpha"], &runner, &["--stall-limit", "4"])?;
    let stderr = String::from_utf8_lossy(&output.stderr);

    assert!(
        !output.status.success(),
        "expected queue execution to fail once the explicit stall limit is reached"
    );
    assert!(
        stderr.contains("stalled after 4 consecutive execute passes"),
        "expected stderr to reflect the explicit queue stall limit, got: {stderr}"
    );
    assert_eq!(
        fixture.logged_global_order()?,
        vec![
            String::from("alpha:execute"),
            String::from("alpha:execute"),
            String::from("alpha:execute"),
            String::from("alpha:execute"),
        ]
    );

    Ok(())
}

#[test]
fn ws_queue_rejects_invalid_names_before_runner_invocation() -> Result<()> {
    let fixture = WorkstreamFixture::new("alpha")?;
    let runner = fixture.install_queue_scripted_runner(&[(
        "alpha",
        &[ScriptedStep::review(sample_tasks_json(1, 1))],
    )])?;

    let output = fixture.run_ws_queue_with_runner_and_args(&["alpha", "../beta"], &runner, &[])?;
    let stderr = String::from_utf8_lossy(&output.stderr);

    assert!(
        !output.status.success(),
        "expected invalid queue names to fail before execution starts"
    );
    assert!(
        stderr.contains("single directory name under .workstreams"),
        "expected stderr to explain the invalid workstream naming, got: {stderr}"
    );
    assert!(
        fixture.logged_prompts("alpha")?.is_empty(),
        "expected invalid queue names to fail before any runner invocation"
    );
    assert!(
        fixture.logged_global_order()?.is_empty(),
        "expected invalid queue names to avoid any queue runner side effects"
    );

    Ok(())
}

#[test]
fn ws_ls_shows_done_status_for_completed_workstreams_with_done_marker() -> Result<()> {
    let fixture = WorkstreamFixture::new("demo")?;
    fixture.write_tasks_json(&sample_tasks_json(1, 1))?;
    fixture.write_run_json("{}")?;
    fixture.write_done_marker("demo")?;

    let output = fixture.run_ws_ls()?;
    let stdout = String::from_utf8_lossy(&output.stdout);

    assert!(output.status.success(), "expected `x ws ls` to succeed");
    assert!(
        stdout.contains("\u{1b}[34mdone"),
        "expected stdout to render done status in blue, got: {stdout}"
    );
    assert!(
        !stdout.contains("\u{1b}[32midle"),
        "expected stdout to show done instead of idle, got: {stdout}"
    );

    Ok(())
}

#[test]
fn ws_ls_keeps_fully_complete_workstreams_idle_without_done_marker() -> Result<()> {
    let fixture = WorkstreamFixture::new("demo")?;
    fixture.write_tasks_json(&sample_tasks_json(1, 1))?;
    fixture.write_run_json("{}")?;

    let output = fixture.run_ws_ls()?;
    let stdout = String::from_utf8_lossy(&output.stdout);

    assert!(output.status.success(), "expected `x ws ls` to succeed");
    assert!(
        stdout.contains("\u{1b}[32midle"),
        "expected stdout to keep fully complete workstreams idle without the done marker, got: {stdout}"
    );
    assert!(
        !stdout.contains("\u{1b}[34mdone"),
        "expected stdout to omit done without the marker, got: {stdout}"
    );

    Ok(())
}

#[test]
fn ws_ls_keeps_running_status_even_with_done_marker() -> Result<()> {
    let fixture = WorkstreamFixture::new("demo")?;
    fixture.write_tasks_json(&sample_tasks_json(1, 1))?;
    fixture.write_done_marker("demo")?;
    fixture.write_run_json(&format!(
        r#"{{
  "pid": {},
  "phase": "execute"
}}"#,
        std::process::id()
    ))?;

    let output = fixture.run_ws_ls()?;
    let stdout = String::from_utf8_lossy(&output.stdout);

    assert!(output.status.success(), "expected `x ws ls` to succeed");
    assert!(
        stdout.contains("running:execute"),
        "expected a live run lock to keep the running status, got: {stdout}"
    );
    assert!(
        !stdout.contains("\u{1b}[34mdone"),
        "expected running status to override done, got: {stdout}"
    );

    Ok(())
}

#[test]
fn ws_ls_keeps_stale_lock_status_even_with_done_marker() -> Result<()> {
    let fixture = WorkstreamFixture::new("demo")?;
    fixture.write_tasks_json(&sample_tasks_json(1, 1))?;
    fixture.write_done_marker("demo")?;
    fixture.write_run_json(
        r#"{
  "pid": 4242,
  "phase": "review"
}"#,
    )?;

    let output = fixture.run_ws_ls()?;
    let stdout = String::from_utf8_lossy(&output.stdout);

    assert!(output.status.success(), "expected `x ws ls` to succeed");
    assert!(
        stdout.contains("stale-lock"),
        "expected a stale lock to keep the stale-lock status, got: {stdout}"
    );
    assert!(
        !stdout.contains("\u{1b}[34mdone"),
        "expected stale-lock status to override done, got: {stdout}"
    );

    Ok(())
}

struct WorkstreamFixture {
    repo_root: PathBuf,
}

impl WorkstreamFixture {
    fn new(name: &str) -> Result<Self> {
        let repo_root = make_temp_repo_root()?;
        let fixture = Self { repo_root };
        fixture.add_workstream(name)?;

        Ok(fixture)
    }

    fn write_invalid_json(&self, file_name: &str) -> Result<()> {
        self.write_workstream_file("demo", file_name, "{ invalid json")?;

        Ok(())
    }

    fn write_tasks_json(&self, contents: &str) -> Result<()> {
        self.write_workstream_file("demo", "tasks.json", contents)?;

        Ok(())
    }

    fn write_activity_json(&self, contents: &str) -> Result<()> {
        self.write_workstream_file("demo", "activity.json", contents)?;

        Ok(())
    }

    fn write_run_json(&self, contents: &str) -> Result<()> {
        self.write_workstream_file("demo", "run.json", contents)?;

        Ok(())
    }

    fn write_done_marker(&self, name: &str) -> Result<()> {
        fs::write(self.workstream_dir(name).join("done"), "")?;

        Ok(())
    }

    fn run_ws_ls(&self) -> Result<Output> {
        Ok(Command::new(env!("CARGO_BIN_EXE_x"))
            .args(["ws", "ls"])
            .current_dir(&self.repo_root)
            .output()?)
    }

    fn run_ws_rm(&self, name: &str) -> Result<Output> {
        Ok(Command::new(env!("CARGO_BIN_EXE_x"))
            .args(["ws", "rm", name])
            .current_dir(&self.repo_root)
            .output()?)
    }

    fn run_ws_command_with_optional_runner(
        &self,
        subcommand: &str,
        name: &str,
        runner: Option<&PathBuf>,
    ) -> Result<Output> {
        let mut command = Command::new(env!("CARGO_BIN_EXE_x"));
        command
            .args(["ws", subcommand, name])
            .args(if subcommand == "exec" {
                &["--agent", "codex"][..]
            } else {
                &[][..]
            })
            .current_dir(&self.repo_root);

        if let Some(runner) = runner {
            command.env("X_WS_AGENT_RUNNER_BIN", runner);
        }

        Ok(command.output()?)
    }

    fn run_ws_info(&self, name: &str) -> Result<Output> {
        self.run_ws_command_with_optional_runner("info", name, None)
    }

    fn run_ws_exec_with_runner(&self, name: &str, runner: &PathBuf) -> Result<Output> {
        self.run_ws_exec_with_runner_and_args(name, runner, &[])
    }

    fn run_ws_exec_with_runner_and_args(
        &self,
        name: &str,
        runner: &PathBuf,
        extra_args: &[&str],
    ) -> Result<Output> {
        let mut command = Command::new(env!("CARGO_BIN_EXE_x"));
        command
            .args(["ws", "exec", name, "--agent", "codex"])
            .args(extra_args)
            .current_dir(&self.repo_root)
            .env("X_WS_AGENT_RUNNER_BIN", runner);

        Ok(command.output()?)
    }

    fn run_ws_queue_with_runner_and_args(
        &self,
        names: &[&str],
        runner: &PathBuf,
        extra_args: &[&str],
    ) -> Result<Output> {
        let mut command = Command::new(env!("CARGO_BIN_EXE_x"));
        command
            .args(["ws", "queue", "run"])
            .args(names)
            .args(["--agent", "codex"])
            .args(extra_args)
            .current_dir(&self.repo_root)
            .env("X_WS_AGENT_RUNNER_BIN", runner);

        Ok(command.output()?)
    }

    fn add_workstream(&self, name: &str) -> Result<()> {
        let workstream_dir = self.workstream_dir(name);
        fs::create_dir_all(&workstream_dir)?;
        fs::write(workstream_dir.join("tasks.json"), TASKS_EXAMPLE)?;
        fs::write(workstream_dir.join("activity.json"), ACTIVITY_EXAMPLE)?;
        fs::write(workstream_dir.join("run.json"), RUN_EXAMPLE)?;

        Ok(())
    }

    fn write_workstream_file(&self, name: &str, file_name: &str, contents: &str) -> Result<()> {
        fs::write(self.workstream_dir(name).join(file_name), contents)?;

        Ok(())
    }

    fn install_scripted_runner(&self, name: &str, steps: &[ScriptedStep]) -> Result<PathBuf> {
        let workstream_dir = self.workstream_dir(name);
        for (index, step) in steps.iter().enumerate() {
            let step_number = index + 1;
            fs::write(
                workstream_dir.join(format!("runner-step-{step_number}.json")),
                &step.tasks_json,
            )?;
            fs::write(
                workstream_dir.join(format!("runner-step-{step_number}.phase")),
                step.phase,
            )?;
        }

        let runner_path = self.repo_root.join("fake-ws-agent-runner.sh");
        fs::write(
            &runner_path,
            format!(
                r#"#!/bin/sh
set -eu

repo=""
prompt=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo)
      repo="$2"
      shift 2
      ;;
    --prompt)
      prompt="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

ws="$repo/.workstreams/{name}"
count_file="$ws/runner-count"
step=1
if [ -f "$count_file" ]; then
  step=$(($(cat "$count_file") + 1))
fi
printf '%s' "$step" > "$count_file"

expected_phase=$(cat "$ws/runner-step-$step.phase")
case "$prompt" in
  *"workstream-$expected_phase {name}"*) ;;
  *)
    echo "unexpected prompt: $prompt" >&2
    exit 1
    ;;
esac

run_file="$ws/run.json"
phase=$(sed -n 's/.*"phase": "\(.*\)".*/\1/p' "$run_file")
iteration=$(sed -n 's/.*"iteration": \([0-9][0-9]*\).*/\1/p' "$run_file")
stall=$(sed -n 's/.*"stall_count": \([0-9][0-9]*\).*/\1/p' "$run_file")
done_marker="missing"
if [ -f "$ws/done" ]; then
  done_marker="present"
fi
printf 'phase=%s iteration=%s stall=%s\n' "$phase" "$iteration" "$stall" >> "$ws/runner-state.log"
printf '%s\n' "workstream-$expected_phase {name}" >> "$ws/runner-prompts.log"
printf '%s\n' "$done_marker" >> "$ws/runner-done.log"

cp "$ws/runner-step-$step.json" "$ws/tasks.json"
"#
            ),
        )?;
        let mut permissions = fs::metadata(&runner_path)?.permissions();
        permissions.set_mode(0o755);
        fs::set_permissions(&runner_path, permissions)?;

        Ok(runner_path)
    }

    fn install_queue_scripted_runner(
        &self,
        workstreams: &[(&str, &[ScriptedStep])],
    ) -> Result<PathBuf> {
        for (name, steps) in workstreams {
            let workstream_dir = self.workstream_dir(name);
            for (index, step) in steps.iter().enumerate() {
                let step_number = index + 1;
                fs::write(
                    workstream_dir.join(format!("runner-step-{step_number}.json")),
                    &step.tasks_json,
                )?;
                fs::write(
                    workstream_dir.join(format!("runner-step-{step_number}.phase")),
                    step.phase,
                )?;
            }
        }

        let runner_path = self.repo_root.join("fake-ws-queue-runner.sh");
        fs::write(
            &runner_path,
            r#"#!/bin/sh
set -eu

repo=""
prompt=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo)
      repo="$2"
      shift 2
      ;;
    --prompt)
      prompt="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

phase=$(printf '%s' "$prompt" | sed -n 's/^workstream-\([^ ]*\) .*/\1/p')
name=""

for ws_dir in "$repo"/.workstreams/*; do
  candidate=$(basename "$ws_dir")
  case "$prompt" in
    "workstream-$phase $candidate"*)
      name="$candidate"
      break
      ;;
  esac
done

if [ -z "$phase" ] || [ -z "$name" ]; then
  echo "unexpected prompt: $prompt" >&2
  exit 1
fi

ws="$repo/.workstreams/$name"
count_file="$ws/runner-count"
step=1
if [ -f "$count_file" ]; then
  step=$(($(cat "$count_file") + 1))
fi
printf '%s' "$step" > "$count_file"

expected_phase=$(cat "$ws/runner-step-$step.phase")
case "$prompt" in
  "workstream-$expected_phase $name"*) ;;
  *)
    echo "unexpected prompt: $prompt" >&2
    exit 1
    ;;
esac

run_file="$ws/run.json"
run_phase=$(sed -n 's/.*"phase": "\(.*\)".*/\1/p' "$run_file")
iteration=$(sed -n 's/.*"iteration": \([0-9][0-9]*\).*/\1/p' "$run_file")
stall=$(sed -n 's/.*"stall_count": \([0-9][0-9]*\).*/\1/p' "$run_file")
printf 'phase=%s iteration=%s stall=%s\n' "$run_phase" "$iteration" "$stall" >> "$ws/runner-state.log"
printf '%s\n' "workstream-$expected_phase $name" >> "$ws/runner-prompts.log"
printf '%s:%s\n' "$name" "$expected_phase" >> "$repo/runner-global.log"

cp "$ws/runner-step-$step.json" "$ws/tasks.json"
"#,
        )?;
        let mut permissions = fs::metadata(&runner_path)?.permissions();
        permissions.set_mode(0o755);
        fs::set_permissions(&runner_path, permissions)?;

        Ok(runner_path)
    }

    fn logged_prompts(&self, name: &str) -> Result<Vec<String>> {
        self.read_log_lines(name, "runner-prompts.log")
    }

    fn logged_run_states(&self, name: &str) -> Result<Vec<String>> {
        self.read_log_lines(name, "runner-state.log")
    }

    fn logged_done_states(&self, name: &str) -> Result<Vec<String>> {
        self.read_log_lines(name, "runner-done.log")
    }

    fn logged_global_order(&self) -> Result<Vec<String>> {
        let path = self.repo_root.join("runner-global.log");
        match fs::read_to_string(path) {
            Ok(contents) => Ok(contents.lines().map(str::to_owned).collect()),
            Err(error) if error.kind() == ErrorKind::NotFound => Ok(Vec::new()),
            Err(error) => Err(error.into()),
        }
    }

    fn read_log_lines(&self, name: &str, file_name: &str) -> Result<Vec<String>> {
        let path = self.workstream_dir(name).join(file_name);
        match fs::read_to_string(path) {
            Ok(contents) => Ok(contents.lines().map(str::to_owned).collect()),
            Err(error) if error.kind() == ErrorKind::NotFound => Ok(Vec::new()),
            Err(error) => Err(error.into()),
        }
    }

    fn workstream_dir(&self, name: &str) -> PathBuf {
        self.repo_root.join(".workstreams").join(name)
    }
}

impl Drop for WorkstreamFixture {
    fn drop(&mut self) {
        let _ = fs::remove_dir_all(&self.repo_root);
    }
}

fn make_temp_repo_root() -> Result<PathBuf> {
    let unique = format!(
        "xtask-ws-{}-{}",
        std::process::id(),
        SystemTime::now().duration_since(UNIX_EPOCH)?.as_nanos()
    );
    let path = std::env::temp_dir().join(unique);
    fs::create_dir_all(&path)?;

    Ok(path)
}

fn sample_tasks_json(completed_count: usize, total_count: usize) -> String {
    let tasks = (0..total_count)
        .map(|index| {
            let done = index < completed_count;
            (format!("NAV-W1-T{index}"), done)
        })
        .collect::<Vec<_>>();

    sample_tasks_json_with_done(
        &tasks
            .iter()
            .map(|(id, done)| (id.as_str(), *done))
            .collect::<Vec<_>>(),
    )
}

fn sample_tasks_json_with_done(tasks: &[(&str, bool)]) -> String {
    let mut entries = Vec::new();
    for (index, (id, done)) in tasks.iter().enumerate() {
        entries.push(format!(
            r#"{{
          "id": "{id}",
          "name": "Task {index}",
          "category": "feature",
          "description": "Task {index} description",
          "acceptance_criteria": [],
          "verification": [],
          "steps": [],
          "done": {done}
        }}"#
        ));
    }

    format!(
        r#"{{
  "must_read_files": [],
  "waves": [
    {{
      "id": "NAV-W1",
      "name": "Wave 1",
      "review_gate": [],
      "checklist": [
        {}
      ]
        }}
  ]
}}"#,
        entries.join(",")
    )
}

struct ScriptedStep {
    phase: &'static str,
    tasks_json: String,
}

impl ScriptedStep {
    fn execute(tasks_json: String) -> Self {
        Self {
            phase: "execute",
            tasks_json,
        }
    }

    fn review(tasks_json: String) -> Self {
        Self {
            phase: "review",
            tasks_json,
        }
    }
}

fn repeated_execute_steps(count: usize, tasks_json: String) -> Vec<ScriptedStep> {
    (0..count)
        .map(|_| ScriptedStep::execute(tasks_json.clone()))
        .collect()
}

fn repeated_no_net_progress_cycles(count: usize) -> Vec<ScriptedStep> {
    let mut steps = Vec::with_capacity(count * 2);
    for _ in 0..count {
        steps.push(ScriptedStep::execute(sample_tasks_json(1, 1)));
        steps.push(ScriptedStep::review(sample_tasks_json(0, 1)));
    }

    steps
}

fn repeated_execute_prompts(count: usize) -> Vec<String> {
    (0..count)
        .map(|_| String::from("workstream-execute demo"))
        .collect()
}

fn repeated_execute_review_prompts(count: usize) -> Vec<String> {
    let mut prompts = Vec::with_capacity(count * 2);
    for _ in 0..count {
        prompts.push(String::from("workstream-execute demo"));
        prompts.push(String::from("workstream-review demo"));
    }

    prompts
}
