use clap::{Parser, Subcommand};
use color_eyre::Result;
use x::cmd::{agentmd, build, ws};

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
    /// Workstream commands
    Ws(ws::Args),
}

fn main() -> Result<()> {
    color_eyre::install()?;
    let cmd = Cli::parse().subcmd;

    match cmd {
        Cmd::AgentsMd(args) => agentmd::run(args),
        Cmd::Build => build::run(),
        Cmd::Ws(args) => ws::run(args),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_ws_ls_command() {
        let cli = Cli::try_parse_from(["x", "ws", "ls"]).expect("`x ws ls` should parse");

        assert!(matches!(
            cli.subcmd,
            Cmd::Ws(ws::Args {
                subcmd: ws::Subcmd::Ls
            })
        ));
    }
}
