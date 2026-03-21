use std::collections::BTreeSet;
use std::fs;
use std::path::PathBuf;
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
  "current_wave_id": "NAV-W2",
  "active_task_ids": [
    "NAV-W2-TA",
    "NAV-W2-TC"
  ]
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
    assert_eq!(workstream.run.current_wave_id.as_deref(), Some("NAV-W2"));
    assert_eq!(
        workstream.run.active_task_ids,
        BTreeSet::from([String::from("NAV-W2-TA"), String::from("NAV-W2-TC"),])
    );
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

struct WorkstreamFixture {
    repo_root: PathBuf,
}

impl WorkstreamFixture {
    fn new(name: &str) -> Result<Self> {
        let repo_root = make_temp_repo_root()?;
        let workstream_dir = repo_root.join(".workstreams").join(name);
        fs::create_dir_all(&workstream_dir)?;
        fs::write(workstream_dir.join("tasks.json"), TASKS_EXAMPLE)?;
        fs::write(workstream_dir.join("activity.json"), ACTIVITY_EXAMPLE)?;
        fs::write(workstream_dir.join("run.json"), RUN_EXAMPLE)?;

        Ok(Self { repo_root })
    }

    fn write_invalid_json(&self, file_name: &str) -> Result<()> {
        fs::write(
            self.repo_root
                .join(".workstreams")
                .join("demo")
                .join(file_name),
            "{ invalid json",
        )?;

        Ok(())
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
