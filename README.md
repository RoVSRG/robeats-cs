# Robeats CS Scripts

A Roblox project for Robeats-related scripts and utilities, built with [Rojo](https://github.com/rojo-rbx/rojo) 7.4.4.

## Getting Started

To build the place from scratch, use:

```bash
rojo build -o "robeats-cs-scripts.rbxlx"
```

Next, open `robeats-cs-scripts.rbxlx` in Roblox Studio and start the Rojo server:

```bash
rojo serve
```

## Script Extraction

This project includes `export.luau`, a Lune script for extracting scripts from existing Roblox place files:

1. Place your `.rbxl` file in the project root
2. Update the `PLACE_PATH` in `export.luau` to match your file name
3. Run the extraction:

```bash
lune run export.luau
```

This will extract all scripts from:

- **ReplicatedStorage** → `src/shared/`
- **StarterPlayerScripts** → `src/client/`
- **ServerScriptService** → `src/server/`

For more help, check out [the Rojo documentation](https://rojo.space/docs).
