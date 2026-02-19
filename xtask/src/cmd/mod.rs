use color_eyre::{eyre::eyre, Result};
use std::path::Path;
use std::process::{Command, Stdio};

pub mod agentmd;
pub mod build;

pub(crate) fn cmd(args: &[&str]) -> Result<()> {
    let (program, rest) = args.split_first().ok_or_else(|| eyre!("empty cmd"))?;
    let mut command = Command::new(program);
    command.args(rest);
    run_command(program, &mut command)
}

pub(crate) fn cmd_in(args: &[&str], dir: &Path) -> Result<()> {
    let (program, rest) = args.split_first().ok_or_else(|| eyre!("empty cmd"))?;
    let mut command = Command::new(program);
    command.args(rest);
    command.current_dir(dir);
    run_command(program, &mut command)
}

fn run_command(program: &str, command: &mut Command) -> Result<()> {
    command
        .stdin(Stdio::inherit())
        .stdout(Stdio::inherit())
        .stderr(Stdio::inherit());

    let status = command.status()?;
    if !status.success() {
        return Err(eyre!("{program} exited with {status}"));
    }

    Ok(())
}
