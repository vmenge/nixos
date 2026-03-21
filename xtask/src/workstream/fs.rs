use std::fs;
use std::path::{Path, PathBuf};

use color_eyre::Result;
use color_eyre::eyre::{ContextCompat, WrapErr};
use serde::de::DeserializeOwned;

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
