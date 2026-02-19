use color_eyre::{eyre::eyre, Result};

use crate::cmd::cmd;

#[derive(clap::Args, Debug)]
pub struct Args {
    /// Source md file name under ~/.agents/ (defaults to AGENTS.md)
    #[arg(default_value = "AGENTS.md")]
    pub md_file: String,
}

pub fn run(args: Args) -> Result<()> {
    let Args { md_file } = args;
    let home = std::env::var("HOME").map_err(|_| eyre!("HOME not set"))?;
    let source = format!("{home}/.agents/{md_file}");

    cmd(&["ln", "-sf", &source, "AGENTS.override.md"])?;

    println!("Symlinked AGENTS.override.md -> {source}");

    Ok(())
}
