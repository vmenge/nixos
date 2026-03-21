use std::collections::BTreeSet;
use std::path::PathBuf;

use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct TasksFile {
    #[serde(default)]
    pub must_read_files: Vec<PathBuf>,
    #[serde(default)]
    pub waves: Vec<Wave>,
}

impl TasksFile {
    pub fn snapshot(&self) -> TaskSnapshot {
        let mut completed_count = 0;
        let mut total_count = 0;
        let mut undone_task_ids = BTreeSet::new();

        for task in self.waves.iter().flat_map(|wave| wave.checklist.iter()) {
            total_count += 1;

            if task.done {
                completed_count += 1;
            } else {
                undone_task_ids.insert(task.id.clone());
            }
        }

        TaskSnapshot {
            completed_count,
            total_count,
            undone_task_ids,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Wave {
    pub id: String,
    pub name: String,
    #[serde(default)]
    pub review_gate: Vec<String>,
    #[serde(default)]
    pub checklist: Vec<Task>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Task {
    pub id: String,
    pub name: String,
    pub category: TaskCategory,
    pub description: String,
    #[serde(default)]
    pub acceptance_criteria: Vec<String>,
    #[serde(default)]
    pub verification: Vec<String>,
    #[serde(default)]
    pub steps: Vec<String>,
    #[serde(default)]
    pub done: bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum TaskCategory {
    Setup,
    Feature,
    Testing,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TaskSnapshot {
    pub completed_count: usize,
    pub total_count: usize,
    pub undone_task_ids: BTreeSet<String>,
}

pub type ActivityFile = Vec<ActivityEntry>;

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ActivityEntry {
    pub agent: String,
    pub at: String,
    pub task: String,
    pub message: String,
    pub next_step: String,
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct RunFile {
    #[serde(default)]
    pub pid: u32,
    #[serde(default)]
    pub started_at: String,
    #[serde(default)]
    pub updated_at: String,
    #[serde(default)]
    pub phase: String,
    #[serde(default)]
    pub iteration: usize,
    #[serde(default)]
    pub stall_count: usize,
    #[serde(default)]
    pub completed_tasks: usize,
    #[serde(default)]
    pub total_tasks: usize,
}
