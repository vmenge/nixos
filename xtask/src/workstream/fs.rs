use std::fs;
use std::path::{Path, PathBuf};
use std::time::{SystemTime, UNIX_EPOCH};

use color_eyre::Result;
use color_eyre::eyre::{ContextCompat, WrapErr};
use serde::de::DeserializeOwned;
use serde::Serialize;

use crate::workstream::model::{ActivityFile, RunFile, TaskSnapshot, TasksFile};

const WORKSTREAMS_DIR: &str = ".workstreams";

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct LoadedWorkstream {
    pub name: String,
    pub dir: PathBuf,
    pub tasks: TasksFile,
    pub activity: ActivityFile,
    pub run: RunFile,
}

impl LoadedWorkstream {
    pub fn task_snapshot(&self) -> TaskSnapshot {
        self.tasks.snapshot()
    }
}

pub fn load_from_repo_root(repo_root: &Path, workstream_name: &str) -> Result<LoadedWorkstream> {
    load_from_dir(&repo_root.join(WORKSTREAMS_DIR).join(workstream_name))
}

pub fn load_from_dir(workstream_dir: &Path) -> Result<LoadedWorkstream> {
    let name = workstream_dir
        .file_name()
        .and_then(|value| value.to_str())
        .map(str::to_owned)
        .wrap_err_with(|| {
            format!(
                "workstream path does not end with a valid name: {}",
                workstream_dir.display()
            )
        })?;

    Ok(LoadedWorkstream {
        name,
        dir: workstream_dir.to_path_buf(),
        tasks: read_json_file(&workstream_dir.join("tasks.json"))?,
        activity: read_optional_json_file(&workstream_dir.join("activity.json"))?,
        run: read_optional_json_file(&workstream_dir.join("run.json"))?,
    })
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RunFileUpdate {
    pub phase: String,
    pub updated_at: String,
    pub iteration: usize,
    pub stall_count: usize,
    pub completed_tasks: usize,
    pub total_tasks: usize,
}

pub fn write_run_started(
    workstream_dir: &Path,
    pid: u32,
    phase: &str,
    started_at: &str,
    snapshot: &TaskSnapshot,
) -> Result<RunFile> {
    let run = RunFile {
        pid,
        started_at: started_at.to_owned(),
        updated_at: started_at.to_owned(),
        phase: phase.to_owned(),
        iteration: 0,
        stall_count: 0,
        completed_tasks: snapshot.completed_count,
        total_tasks: snapshot.total_count,
    };

    write_run_file(workstream_dir, &run)?;

    Ok(run)
}

pub fn update_run_file(
    workstream_dir: &Path,
    current: &RunFile,
    update: RunFileUpdate,
) -> Result<RunFile> {
    let run = RunFile {
        pid: current.pid,
        started_at: current.started_at.clone(),
        updated_at: update.updated_at,
        phase: update.phase,
        iteration: update.iteration,
        stall_count: update.stall_count,
        completed_tasks: update.completed_tasks,
        total_tasks: update.total_tasks,
    };

    write_run_file(workstream_dir, &run)?;

    Ok(run)
}

pub fn clear_run_file(workstream_dir: &Path) -> Result<()> {
    let run_path = run_file_path(workstream_dir);

    match fs::remove_file(&run_path) {
        Ok(()) => Ok(()),
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => Ok(()),
        Err(error) => Err(error).wrap_err_with(|| format!("failed to remove {}", run_path.display())),
    }
}

fn write_run_file(workstream_dir: &Path, run: &RunFile) -> Result<()> {
    write_json_file(&run_file_path(workstream_dir), run)
}

fn run_file_path(workstream_dir: &Path) -> PathBuf {
    workstream_dir.join("run.json")
}

fn read_optional_json_file<T>(path: &Path) -> Result<T>
where
    T: DeserializeOwned + Default,
{
    match fs::read_to_string(path) {
        Ok(contents) => parse_json(&contents, path),
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => Ok(T::default()),
        Err(error) => Err(error).wrap_err_with(|| format!("failed to read {}", path.display())),
    }
}

fn read_json_file<T>(path: &Path) -> Result<T>
where
    T: DeserializeOwned,
{
    let contents =
        fs::read_to_string(path).wrap_err_with(|| format!("failed to read {}", path.display()))?;

    parse_json(&contents, path)
}

fn parse_json<T>(contents: &str, path: &Path) -> Result<T>
where
    T: DeserializeOwned,
{
    serde_json::from_str(contents).wrap_err_with(|| format!("failed to parse {}", path.display()))
}

fn write_json_file<T>(path: &Path, value: &T) -> Result<()>
where
    T: Serialize,
{
    let contents = serde_json::to_string_pretty(value)
        .wrap_err_with(|| format!("failed to serialize {}", path.display()))?;
    let temp_path = path.with_extension(format!(
        "tmp-{}-{}",
        std::process::id(),
        SystemTime::now().duration_since(UNIX_EPOCH)?.as_nanos()
    ));
    fs::write(&temp_path, format!("{contents}\n"))
        .wrap_err_with(|| format!("failed to write {}", temp_path.display()))?;
    fs::rename(&temp_path, path)
        .wrap_err_with(|| format!("failed to replace {}", path.display()))?;

    Ok(())
}
