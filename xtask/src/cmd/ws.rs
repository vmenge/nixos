use color_eyre::{Result, eyre::eyre};

#[derive(clap::Args, Debug)]
pub struct Args {
    #[command(subcommand)]
    pub subcmd: Subcmd,
}

#[derive(clap::Subcommand, Debug)]
pub enum Subcmd {
    /// List workstreams
    Ls,
    /// Remove a workstream
    Rm(TargetArgs),
    /// Execute a workstream
    Exec(TargetArgs),
}

#[derive(clap::Args, Debug)]
pub struct TargetArgs {
    pub workstream_name: String,
}

pub fn run(args: Args) -> Result<()> {
    match args.subcmd {
        Subcmd::Ls => not_implemented("ws ls"),
        Subcmd::Rm(TargetArgs { workstream_name }) => {
            not_implemented(&format!("ws rm {workstream_name}"))
        }
        Subcmd::Exec(TargetArgs { workstream_name }) => {
            not_implemented(&format!("ws exec {workstream_name}"))
        }
    }
}

fn not_implemented(command: &str) -> Result<()> {
    Err(eyre!("{command} not implemented"))
}
