use std::path::{Path, PathBuf};

use color_eyre::Result;
use color_eyre::eyre::{ContextCompat, WrapErr};

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AgentRunnerRequest {
    repo_root: PathBuf,
    prompt: String,
}

impl AgentRunnerRequest {
    pub fn new(repo_root: PathBuf, prompt: String) -> Self {
        Self { repo_root, prompt }
    }

    pub fn inner_command(&self) -> (&'static str, Vec<String>) {
        (
            "codex",
            vec![
                String::from("exec"),
                String::from("--cd"),
                self.repo_root.display().to_string(),
                String::from("--ask-for-approval"),
                String::from("never"),
                String::from("--sandbox"),
                String::from("danger-full-access"),
                self.prompt.clone(),
            ],
        )
    }

    pub fn helper_command(&self, program: &str) -> (String, Vec<String>) {
        (
            String::from(program),
            vec![
                String::from("--repo"),
                self.repo_root.display().to_string(),
                String::from("--prompt"),
                self.prompt.clone(),
            ],
        )
    }

    pub fn sandbox_paths(&self) -> Result<Vec<SandboxPath>> {
        let home_dir = std::env::var_os("HOME")
            .map(PathBuf::from)
            .context("HOME is not set for ws-agent-runner")?;

        self.sandbox_paths_with_home(&home_dir)
    }

    pub fn sandbox_paths_with_home(&self, home_dir: &Path) -> Result<Vec<SandboxPath>> {
        let mut paths = vec![SandboxPath::read_write(canonicalize_path(&self.repo_root)?)];

        if let Some(git_dir) = resolve_git_dir(&self.repo_root)? {
            paths.push(SandboxPath::read_write(git_dir.clone()));

            if let Some(common_dir) = resolve_common_git_dir(&git_dir)? {
                paths.push(SandboxPath::read_write(common_dir));
            }
        }

        for (path, access) in [
            (PathBuf::from("/tmp"), SandboxAccess::ReadWrite),
            (PathBuf::from("/nix"), SandboxAccess::Read),
            (PathBuf::from("/usr"), SandboxAccess::Read),
            (PathBuf::from("/bin"), SandboxAccess::Read),
            (PathBuf::from("/lib"), SandboxAccess::Read),
            (PathBuf::from("/lib64"), SandboxAccess::Read),
            (PathBuf::from("/etc"), SandboxAccess::Read),
            (PathBuf::from("/dev"), SandboxAccess::Read),
            (PathBuf::from("/run/current-system"), SandboxAccess::Read),
            (home_dir.join(".nix-profile"), SandboxAccess::Read),
            (home_dir.join(".local/bin"), SandboxAccess::Read),
            (home_dir.join(".codex"), SandboxAccess::ReadWrite),
        ] {
            if path.exists() {
                paths.push(SandboxPath {
                    path: canonicalize_path(&path)?,
                    access,
                });
            }
        }

        if let Some(codex_path) = resolve_codex_path() {
            paths.push(SandboxPath::read(canonicalize_path(&codex_path)?));
        }

        Ok(dedup_paths(paths))
    }
}

fn resolve_codex_path() -> Option<PathBuf> {
    let path = std::env::var_os("PATH")?;
    std::env::split_paths(&path)
        .map(|dir| dir.join("codex"))
        .find(|candidate| candidate.is_file())
}

fn resolve_git_dir(repo_root: &Path) -> Result<Option<PathBuf>> {
    let dot_git = repo_root.join(".git");
    if dot_git.is_dir() {
        return Ok(Some(canonicalize_path(&dot_git)?));
    }

    if !dot_git.is_file() {
        return Ok(None);
    }

    let contents = std::fs::read_to_string(&dot_git)
        .with_context(|| format!("failed to read {}", dot_git.display()))?;
    let git_dir = contents
        .strip_prefix("gitdir:")
        .map(str::trim)
        .context(".git file did not contain a gitdir entry")?;
    let git_dir = PathBuf::from(git_dir);

    if git_dir.is_absolute() {
        Ok(Some(canonicalize_path(&git_dir)?))
    } else {
        Ok(Some(canonicalize_path(&repo_root.join(git_dir))?))
    }
}

fn resolve_common_git_dir(git_dir: &Path) -> Result<Option<PathBuf>> {
    let common_dir_path = git_dir.join("commondir");
    if !common_dir_path.is_file() {
        return Ok(None);
    }

    let contents = std::fs::read_to_string(&common_dir_path)
        .with_context(|| format!("failed to read {}", common_dir_path.display()))?;
    let relative = contents.trim();
    if relative.is_empty() {
        return Ok(None);
    }

    let common_dir = PathBuf::from(relative);
    if common_dir.is_absolute() {
        Ok(Some(canonicalize_path(&common_dir)?))
    } else {
        Ok(Some(canonicalize_path(&git_dir.join(common_dir))?))
    }
}

fn canonicalize_path(path: &Path) -> Result<PathBuf> {
    std::fs::canonicalize(path)
        .with_context(|| format!("failed to canonicalize {}", path.display()))
}

fn dedup_paths(paths: Vec<SandboxPath>) -> Vec<SandboxPath> {
    let mut deduped = Vec::new();
    for path in paths {
        if !deduped
            .iter()
            .any(|candidate: &SandboxPath| candidate.path == path.path)
        {
            deduped.push(path);
        }
    }

    deduped
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SandboxAccess {
    Read,
    ReadWrite,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SandboxPath {
    pub path: PathBuf,
    pub access: SandboxAccess,
}

impl SandboxPath {
    fn read(path: PathBuf) -> Self {
        Self {
            path,
            access: SandboxAccess::Read,
        }
    }

    fn read_write(path: PathBuf) -> Self {
        Self {
            path,
            access: SandboxAccess::ReadWrite,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;
    use std::time::{SystemTime, UNIX_EPOCH};

    #[test]
    fn sandbox_paths_include_worktree_git_metadata() -> Result<()> {
        let fixture = AgentFixture::new()?;
        let request = AgentRunnerRequest::new(fixture.repo_root.clone(), String::from("prompt"));
        let sandbox_paths = request.sandbox_paths_with_home(&fixture.home_dir)?;

        assert!(
            sandbox_paths.contains(&SandboxPath::read_write(fs::canonicalize(
                &fixture.repo_root
            )?))
        );
        assert!(
            sandbox_paths.contains(&SandboxPath::read_write(fs::canonicalize(
                &fixture.git_dir
            )?))
        );
        assert!(
            sandbox_paths.contains(&SandboxPath::read_write(fs::canonicalize(
                &fixture.common_git_dir
            )?))
        );

        Ok(())
    }

    #[test]
    fn sandbox_paths_skip_missing_optional_user_paths() -> Result<()> {
        let fixture = AgentFixture::new()?;
        let request = AgentRunnerRequest::new(fixture.repo_root.clone(), String::from("prompt"));
        let sandbox_paths = request.sandbox_paths_with_home(&fixture.home_dir)?;

        assert!(
            !sandbox_paths
                .iter()
                .any(|entry| entry.path == fixture.home_dir.join(".nix-profile"))
        );
        assert!(
            !sandbox_paths
                .iter()
                .any(|entry| entry.path == fixture.home_dir.join(".local/bin"))
        );
        assert!(
            !sandbox_paths
                .iter()
                .any(|entry| entry.path == fixture.home_dir.join(".codex"))
        );

        Ok(())
    }

    struct AgentFixture {
        root: PathBuf,
        repo_root: PathBuf,
        home_dir: PathBuf,
        git_dir: PathBuf,
        common_git_dir: PathBuf,
    }

    impl AgentFixture {
        fn new() -> Result<Self> {
            let root = std::env::temp_dir().join(format!(
                "xtask-agent-{}-{}",
                std::process::id(),
                SystemTime::now().duration_since(UNIX_EPOCH)?.as_nanos()
            ));
            let repo_root = root.join("repo");
            let home_dir = root.join("home");
            let common_git_dir = root.join("git-common");
            let git_dir = common_git_dir.join("worktrees/demo");

            fs::create_dir_all(&repo_root)?;
            fs::create_dir_all(&home_dir)?;
            fs::create_dir_all(&git_dir)?;
            fs::write(
                repo_root.join(".git"),
                format!("gitdir: {}\n", git_dir.display()),
            )?;
            fs::write(git_dir.join("commondir"), "../..")?;

            Ok(Self {
                root,
                repo_root,
                home_dir,
                git_dir,
                common_git_dir,
            })
        }
    }

    impl Drop for AgentFixture {
        fn drop(&mut self) {
            let _ = fs::remove_dir_all(&self.root);
        }
    }
}
