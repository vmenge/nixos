use std::ffi::OsString;
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
                String::from("--ask-for-approval"),
                String::from("never"),
                String::from("exec"),
                String::from("--cd"),
                self.repo_root.display().to_string(),
                String::from("--sandbox"),
                String::from("danger-full-access"),
                self.prompt.clone(),
            ],
        )
    }

    pub fn claude_command(&self) -> (&'static str, Vec<String>) {
        (
            "claude",
            vec![
                String::from("--dangerously-skip-permissions"),
                String::from("-p"),
                String::from("--add-dir"),
                self.repo_root.display().to_string(),
                self.prompt.clone(),
            ],
        )
    }

    pub fn helper_command(&self, program: &str) -> (String, Vec<String>) {
        (String::from(program), self.helper_args())
    }

    pub fn helper_args(&self) -> Vec<String> {
        vec![
            String::from("--repo"),
            self.repo_root.display().to_string(),
            String::from("--prompt"),
            self.prompt.clone(),
        ]
    }

    pub fn sandbox_paths(&self) -> Result<Vec<SandboxPath>> {
        let home_dir = std::env::var_os("HOME")
            .map(PathBuf::from)
            .context("HOME is not set for workstream runner")?;

        self.sandbox_paths_with_home(&home_dir)
    }

    pub fn sandbox_paths_with_home(&self, home_dir: &Path) -> Result<Vec<SandboxPath>> {
        let dotfiles_dir = home_dir.join("nixos/dotfiles");
        let git_config_dir = home_dir.join(".config/git");
        let cache_home_dir = xdg_cache_home(home_dir);
        let git_home_dir = home_dir.join(".git");
        self.sandbox_paths_with_home_and_path(
            home_dir,
            std::env::var_os("PATH"),
            vec![
                Some((home_dir.to_path_buf(), SandboxAccess::Read)),
                if dotfiles_dir.exists() {
                    Some((dotfiles_dir, SandboxAccess::Read))
                } else {
                    None
                },
                if git_config_dir.exists() {
                    Some((git_config_dir, SandboxAccess::Read))
                } else {
                    None
                },
                if cache_home_dir.exists() {
                    Some((cache_home_dir, SandboxAccess::ReadWrite))
                } else {
                    None
                },
                if git_home_dir.exists() {
                    Some((git_home_dir, SandboxAccess::Read))
                } else {
                    None
                },
            ]
            .into_iter()
            .flatten()
            .collect(),
        )
    }

    fn sandbox_paths_with_home_and_path(
        &self,
        home_dir: &Path,
        path_env: Option<OsString>,
        extra_paths: Vec<(PathBuf, SandboxAccess)>,
    ) -> Result<Vec<SandboxPath>> {
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

        for (path, access) in extra_paths {
            paths.push(SandboxPath {
                path: canonicalize_path(&path)?,
                access,
            });
        }

        if let Some(codex_dir) = resolve_codex_dir(path_env) {
            paths.push(SandboxPath::read(canonicalize_path(&codex_dir)?));
        }

        Ok(dedup_paths(paths))
    }
}

fn resolve_codex_dir(path_env: Option<OsString>) -> Option<PathBuf> {
    let path_env = path_env?;
    std::env::split_paths(&path_env)
        .map(|dir| dir.join("codex"))
        .find(|candidate| candidate.is_file())
        .and_then(|candidate| candidate.parent().map(Path::to_path_buf))
}

fn xdg_cache_home(home_dir: &Path) -> PathBuf {
    std::env::var_os("XDG_CACHE_HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|| home_dir.join(".cache"))
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

    #[test]
    fn sandbox_paths_allow_codex_parent_directory_not_executable() -> Result<()> {
        let fixture = AgentFixture::new()?;
        let request = AgentRunnerRequest::new(fixture.repo_root.clone(), String::from("prompt"));
        let custom_bin_dir = fixture.root.join("custom-bin");
        fs::create_dir_all(&custom_bin_dir)?;
        fs::write(custom_bin_dir.join("codex"), "#!/bin/sh\n")?;

        let sandbox_paths = request.sandbox_paths_with_home_and_path(
            &fixture.home_dir,
            Some(std::env::join_paths([custom_bin_dir.clone()])?),
            Vec::new(),
        )?;
        let codex_path = fs::canonicalize(custom_bin_dir.join("codex"))?;

        assert!(sandbox_paths.contains(&SandboxPath::read(fs::canonicalize(
            &custom_bin_dir
        )?)));
        assert!(
            !sandbox_paths
                .iter()
                .any(|entry| entry.path == codex_path)
        );

        Ok(())
    }

    #[test]
    fn sandbox_paths_include_repo_dotfiles_when_present() -> Result<()> {
        let fixture = AgentFixture::new()?;
        let request = AgentRunnerRequest::new(fixture.repo_root.clone(), String::from("prompt"));
        let repo_dotfiles = fixture.home_dir.join("nixos/dotfiles");
        fs::create_dir_all(&repo_dotfiles)?;

        let sandbox_paths = request.sandbox_paths_with_home_and_path(
            &fixture.home_dir,
            None,
            vec![(repo_dotfiles.clone(), SandboxAccess::Read)],
        )?;

        assert!(sandbox_paths.contains(&SandboxPath {
            path: fs::canonicalize(repo_dotfiles)?,
            access: SandboxAccess::Read,
        }));

        Ok(())
    }

    #[test]
    fn sandbox_paths_include_git_config_directories_when_present() -> Result<()> {
        let fixture = AgentFixture::new()?;
        let request = AgentRunnerRequest::new(fixture.repo_root.clone(), String::from("prompt"));
        let git_config_dir = fixture.home_dir.join(".config/git");
        let git_home_dir = fixture.home_dir.join(".git");
        fs::create_dir_all(&git_config_dir)?;
        fs::create_dir_all(&git_home_dir)?;

        let sandbox_paths = request.sandbox_paths_with_home(&fixture.home_dir)?;

        assert!(sandbox_paths.contains(&SandboxPath {
            path: fs::canonicalize(git_config_dir)?,
            access: SandboxAccess::Read,
        }));
        assert!(sandbox_paths.contains(&SandboxPath {
            path: fs::canonicalize(git_home_dir)?,
            access: SandboxAccess::Read,
        }));

        Ok(())
    }

    #[test]
    fn sandbox_paths_include_cache_home_when_present() -> Result<()> {
        let fixture = AgentFixture::new()?;
        let request = AgentRunnerRequest::new(fixture.repo_root.clone(), String::from("prompt"));
        let cache_home_dir = fixture.home_dir.join(".cache");
        fs::create_dir_all(&cache_home_dir)?;

        let sandbox_paths = request.sandbox_paths_with_home(&fixture.home_dir)?;

        assert!(sandbox_paths.contains(&SandboxPath {
            path: fs::canonicalize(cache_home_dir)?,
            access: SandboxAccess::ReadWrite,
        }));

        Ok(())
    }

    #[test]
    fn sandbox_paths_include_home_directory_when_present() -> Result<()> {
        let fixture = AgentFixture::new()?;
        let request = AgentRunnerRequest::new(fixture.repo_root.clone(), String::from("prompt"));

        let sandbox_paths = request.sandbox_paths_with_home(&fixture.home_dir)?;

        assert!(sandbox_paths.contains(&SandboxPath {
            path: fs::canonicalize(&fixture.home_dir)?,
            access: SandboxAccess::Read,
        }));

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
