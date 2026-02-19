use clap::{Parser, Subcommand};
use color_eyre::Result;
use x::cmd::{agentmd, build};

#[derive(Parser, Debug)]
pub struct Cli {
    #[command(subcommand)]
    subcmd: Cmd,
}

#[derive(Subcommand, Debug)]
enum Cmd {
    /// Creates an AGENTS.override.md symlink on cwd based on given source (defaults to ~/.agents/AGENTS.md)
    AgentsMd(agentmd::Args),
    /// Builds xtask in debug mode
    Build,
}

fn main() -> Result<()> {
    color_eyre::install()?;
    let cmd = Cli::parse().subcmd;

    match cmd {
        Cmd::AgentsMd(args) => agentmd::run(args),
        Cmd::Build => build::run(),
    }
}
