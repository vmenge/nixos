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
    Rm,
    /// Execute a workstream
    Exec,
}

pub fn run(args: Args) -> Result<()> {
    match args.subcmd {
        Subcmd::Ls => not_implemented("ws ls"),
        Subcmd::Rm => not_implemented("ws rm"),
        Subcmd::Exec => not_implemented("ws exec"),
    }
}

fn not_implemented(command: &str) -> Result<()> {
    Err(eyre!("{command} not implemented"))
}
