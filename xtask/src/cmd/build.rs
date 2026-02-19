use std::path::Path;

use color_eyre::Result;

use crate::cmd::cmd_in;

const XTASK_DIR: &str = env!("CARGO_MANIFEST_DIR");

pub fn run() -> Result<()> {
    cmd_in(&["cargo", "build"], Path::new(XTASK_DIR))?;

    println!("Build completed successfully (debug mode)");

    Ok(())
}
