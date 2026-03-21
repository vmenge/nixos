use std::fs;
use std::path::PathBuf;
use std::process::{Command, Output};
use std::time::{SystemTime, UNIX_EPOCH};

use color_eyre::Result;
use x::workstream::fs::load_from_repo_root;

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
fn ws_rm_deletes_a_stopped_workstream_directory() -> Result<()> {
    let fixture = WorkstreamFixture::new("demo")?;
    fixture.write_run_json("{}")?;

    let output = fixture.run_ws_rm("demo")?;

    assert!(
        output.status.success(),
        "expected `x ws rm demo` to succeed, stderr was: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    assert!(
        !fixture.workstream_dir("demo").exists(),
        "expected workstream directory to be removed"
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
        stderr.contains("running"),
        "expected stderr to mention the running workstream, got: {stderr}"
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
    let mut tasks = Vec::new();
    for index in 0..total_count {
        let done = index < completed_count;
        tasks.push(format!(
            r#"{{
          "id": "NAV-W1-T{index}",
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
        tasks.join(",")
    )
}
