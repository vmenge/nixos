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
        stdout.contains("Finished the summary row."),
        "expected stdout to include latest activity message, got: {stdout}"
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

    assert!(output.status.success(), "expected `x ws info demo` to succeed");
    assert!(stdout.contains("🧵 workstream `demo`"));
    assert!(stdout.contains("📊 progress: 1/3 complete"));
    assert!(stdout.contains("🏃 status: idle"));
    assert!(stdout.contains("📝 activity"));
    assert!(stdout.contains("🕒 2026-03-21T09:05:00Z"));
    assert!(stdout.contains("🎯 NAV-W1-TB"));
    assert!(stdout.contains("🤖 agent-2"));
    assert!(stdout.contains("💬 Finished the summary row."));
    assert!(stdout.contains("➡️ Review output formatting"));
    assert!(
        stdout.find("2026-03-21T09:05:00Z").unwrap()
            < stdout.find("2026-03-21T09:00:00Z").unwrap()
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
fn ws_exec_fails_after_three_consecutive_no_progress_passes() -> Result<()> {
    let fixture = WorkstreamFixture::new("demo")?;
    fixture.write_tasks_json(&sample_tasks_json(0, 2))?;
    let runner = fixture.install_scripted_runner(
        "demo",
        &[
            ScriptedStep::execute(sample_tasks_json(0, 2)),
            ScriptedStep::execute(sample_tasks_json(0, 2)),
            ScriptedStep::execute(sample_tasks_json(0, 2)),
        ],
    )?;

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
        vec![
            String::from("workstream-execute demo"),
            String::from("workstream-execute demo"),
            String::from("workstream-execute demo"),
        ]
    );

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

    let output = fixture.run_ws_exec_with_runner("demo", &runner)?;
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
fn ws_exec_fails_after_three_no_net_progress_execute_review_cycles() -> Result<()> {
    let fixture = WorkstreamFixture::new("demo")?;
    fixture.write_tasks_json(&sample_tasks_json(0, 1))?;
    let runner = fixture.install_scripted_runner(
        "demo",
        &[
            ScriptedStep::execute(sample_tasks_json(1, 1)),
            ScriptedStep::review(sample_tasks_json(0, 1)),
            ScriptedStep::execute(sample_tasks_json(1, 1)),
            ScriptedStep::review(sample_tasks_json(0, 1)),
            ScriptedStep::execute(sample_tasks_json(1, 1)),
            ScriptedStep::review(sample_tasks_json(0, 1)),
        ],
    )?;

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
        vec![
            String::from("workstream-execute demo"),
            String::from("workstream-review demo"),
            String::from("workstream-execute demo"),
            String::from("workstream-review demo"),
            String::from("workstream-execute demo"),
            String::from("workstream-review demo"),
        ]
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
        self.run_ws_command_with_optional_runner("exec", name, Some(runner))
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
printf 'phase=%s iteration=%s stall=%s\n' "$phase" "$iteration" "$stall" >> "$ws/runner-state.log"
printf '%s\n' "workstream-$expected_phase {name}" >> "$ws/runner-prompts.log"

cp "$ws/runner-step-$step.json" "$ws/tasks.json"
"#
            ),
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
