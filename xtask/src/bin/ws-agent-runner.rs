use std::path::PathBuf;
use std::process::Command;

use clap::Parser;
use color_eyre::Result;
use color_eyre::eyre::eyre;
use nono::{AccessMode, CapabilitySet, Sandbox};
use x::workstream::agent::{AgentRunnerRequest, SandboxAccess};

#[derive(Parser, Debug)]
struct Cli {
    #[arg(long)]
    repo: PathBuf,
    #[arg(long)]
    prompt: String,
}

fn main() -> Result<()> {
    color_eyre::install()?;
    let cli = Cli::parse();
    let request = AgentRunnerRequest::new(cli.repo, cli.prompt);

    let support = Sandbox::support_info();
    if !support.is_supported {
        return Err(eyre!("nono sandbox unsupported: {}", support.details));
    }

    let mut capabilities = CapabilitySet::new();
    for sandbox_path in request.sandbox_paths()? {
        let access = match sandbox_path.access {
            SandboxAccess::Read => AccessMode::Read,
            SandboxAccess::ReadWrite => AccessMode::ReadWrite,
        };
        capabilities = capabilities.allow_path(&sandbox_path.path, access)?;
    }
    Sandbox::apply(&capabilities)?;

    let (program, args) = request.inner_command();
    let status = Command::new(program).args(args).status()?;
    if !status.success() {
        return Err(eyre!("{program} exited with {status}"));
    }

    Ok(())
}
