When developing in Rust:
1. Avoid fully qualifying functions. Prefer qualifying only by the preceding module. e.g: `fs::write()`. Only qualify more than that when ambiguous.
2. Avoid fully qualifying types, prefer using `use` statements to import types unless they are ambiguous.
