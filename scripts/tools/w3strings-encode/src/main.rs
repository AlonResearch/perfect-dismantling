use std::env;
use std::fs;
use std::path::PathBuf;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args: Vec<String> = env::args().collect();
    if args.len() != 3 {
        return Err("usage: w3strings-encode <input.csv> <output.w3strings>".into());
    }

    let input = PathBuf::from(&args[1]);
    let output = PathBuf::from(&args[2]);
    let csv = fs::read_to_string(&input)?;
    let encoded = w3strings::encode(&csv)?;

    if let Some(parent) = output.parent() {
        fs::create_dir_all(parent)?;
    }
    fs::write(output, encoded)?;
    Ok(())
}
