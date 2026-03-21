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

    #[test]
    fn parses_ws_rm_command_with_workstream_name() {
        let cli =
            Cli::try_parse_from(["x", "ws", "rm", "demo"]).expect("`x ws rm demo` should parse");

        assert!(matches!(
            cli.subcmd,
            Cmd::Ws(ws::Args {
                subcmd: ws::Subcmd::Rm(ws::TargetArgs { workstream_name })
            }) if workstream_name == "demo"
        ));
    }

    #[test]
    fn parses_ws_info_command_with_workstream_name() {
        let cli = Cli::try_parse_from(["x", "ws", "info", "demo"])
            .expect("`x ws info demo` should parse");

        assert!(matches!(
            cli.subcmd,
            Cmd::Ws(ws::Args {
                subcmd: ws::Subcmd::Info(ws::TargetArgs { workstream_name })
            }) if workstream_name == "demo"
        ));
    }

    #[test]
    fn parses_ws_exec_command_with_default_stall_limit() {
        let cli = Cli::try_parse_from(["x", "ws", "exec", "demo", "--agent", "codex"])
            .expect("`x ws exec demo --agent codex` should parse");

        assert!(matches!(
            cli.subcmd,
            Cmd::Ws(ws::Args {
                subcmd: ws::Subcmd::Exec(ws::ExecArgs {
                    workstream_name,
                    agent,
                    unsafe_mode,
                    stall_limit,
                })
            }) if workstream_name == "demo"
                && agent == ws::AgentArg::Codex
                && !unsafe_mode
                && stall_limit == 10
        ));
    }

    #[test]
    fn parses_ws_exec_command_with_explicit_stall_limit() {
        let cli = Cli::try_parse_from([
            "x",
            "ws",
            "exec",
            "demo",
            "--agent",
            "codex",
            "--stall-limit",
            "4",
        ])
        .expect("`x ws exec demo --agent codex --stall-limit 4` should parse");

        assert!(matches!(
            cli.subcmd,
            Cmd::Ws(ws::Args {
                subcmd: ws::Subcmd::Exec(ws::ExecArgs {
                    workstream_name,
                    agent,
                    unsafe_mode,
                    stall_limit,
                })
            }) if workstream_name == "demo"
                && agent == ws::AgentArg::Codex
                && !unsafe_mode
                && stall_limit == 4
        ));
    }

    #[test]
    fn parses_ws_queue_run_command_with_default_stall_limit() {
        let cli = Cli::try_parse_from([
            "x", "ws", "queue", "run", "alpha", "beta", "--agent", "codex",
        ])
        .expect("`x ws queue run alpha beta --agent codex` should parse");

        assert!(matches!(
            cli.subcmd,
            Cmd::Ws(ws::Args {
                subcmd: ws::Subcmd::Queue(ws::QueueArgs {
                    subcmd: ws::QueueSubcmd::Run(ws::QueueRunArgs {
                        workstream_names,
                        agent,
                        stall_limit,
                        unsafe_mode,
                    })
                })
            }) if workstream_names == vec![String::from("alpha"), String::from("beta")]
                && agent == ws::AgentArg::Codex
                && stall_limit == 10
                && !unsafe_mode
        ));
    }

    #[test]
    fn parses_ws_queue_run_command_with_explicit_options() {
        let cli = Cli::try_parse_from([
            "x",
            "ws",
            "queue",
            "run",
            "alpha",
            "--agent",
            "claude",
            "--stall-limit",
            "4",
            "--unsafe",
        ])
        .expect("`x ws queue run alpha --agent claude --stall-limit 4 --unsafe` should parse");

        assert!(matches!(
            cli.subcmd,
            Cmd::Ws(ws::Args {
                subcmd: ws::Subcmd::Queue(ws::QueueArgs {
                    subcmd: ws::QueueSubcmd::Run(ws::QueueRunArgs {
                        workstream_names,
                        agent,
                        stall_limit,
                        unsafe_mode,
                    })
                })
            }) if workstream_names == vec![String::from("alpha")]
                && agent == ws::AgentArg::Claude
                && stall_limit == 4
                && unsafe_mode
        ));
    }
}
