# Robeats CS Scripts

This project contains the source code for Robeats CS, organized for modern Roblox development with proper build tooling.

## Development Workflow

### Directory Structure

- `src/shared/` - Shared modules (maps to ReplicatedStorage)
- `src/client/` - Client-side scripts (maps to StarterPlayerScripts)
- `src/server/` - Server-side scripts (maps to ServerScriptService)

### Import System

During development, use the `@shared/` import syntax for shared modules:

```luau
local MyModule = require("@shared/MyModule")
local Utils = require("@shared/Shared/Utils")
local GameCore = require("@shared/RobeatsGameCore/RobeatsGame")
```

### Building for Roblox

#### Development Mode (with Auto-transformation)

For active development, start the file watcher for automatic transformation on save:

##### macOS/Linux

```bash
./watch
```

##### Windows

Choose one of these options:

```cmd
scripts\watch.bat           # Command Prompt
```

```powershell
.\scripts\watch.ps1         # PowerShell (recommended)
```

```cmd
lune run scripts/watch.luau # Direct Lune command
```

This will:

- Monitor all files in `src/` for changes
- Automatically transform `@shared/xxx` imports to `game.ReplicatedStorage.xxx`
- Update the corresponding files in `dist/` in real-time
- Keep running until you stop it with Ctrl+C

#### Production Build

To build a complete place file ready for Roblox Studio:

##### macOS/Linux

```bash
./build
```

##### Windows

Choose one of these options:

```cmd
scripts\build.bat           # Command Prompt
```

```powershell
.\scripts\build.ps1         # PowerShell (recommended)
```

```cmd
lune run scripts/build.luau # Direct Lune command
```

This will:

1. Transform all `@shared/xxx` imports to `game.ReplicatedStorage.xxx`
2. Convert path separators from `/` to `.` for Roblox
3. Generate a production-ready place file: `robeats-cs-built.rbxl`

### Development vs Production

**Development (src/):**

- Use `@shared/` imports for better IDE support and portability
- Cleaner, more readable code
- Better autocomplete and navigation

**Production (dist/ and built .rbxl):**

- Uses proper `game.ReplicatedStorage.xxx` syntax
- Compatible with Roblox Studio and runtime
- Generated automatically by the build process

### Tools Used

- **Rojo**: Project management and building
- **Lune**: Script transformation and build automation
- **Aftman**: Tool version management

### Getting Started

1. **Install tools**: `aftman install`
2. **Start development watcher**: `./watch` (keeps `dist/` updated automatically)
3. **Make changes in `src/`** (files are transformed instantly on save)
4. **Build for production**: `./build` (creates `robeats-cs-built.rbxl`)
5. **Sync to Roblox Studio**: Open and sync `robeats-cs-built.rbxl`

### VS Code Integration

Use **Ctrl+Shift+P** → **Tasks: Run Task** to access:

- **"Watch and Transform"** - Start the file watcher (background task)
- **"Build Production"** - Build the final .rbxl file

### Available Commands

| Command                           | Purpose                                   | Output                          |
| --------------------------------- | ----------------------------------------- | ------------------------------- |
| `./watch`                         | Development mode with auto-transformation | Updates `dist/` on file save    |
| `./build`                         | Production build                          | Creates `robeats-cs-built.rbxl` |
| `lune run scripts/transform.luau` | Manual transformation                     | Updates `dist/` once            |
| `lune run scripts/build.luau`     | Alternative build command                 | Same as `./build`               |

This setup gives you the best of both worlds: modern development experience with full Roblox compatibility.

This project includes `export.luau`, a Lune script for extracting scripts from existing Roblox place files:

1. Place your `.rbxl` file in the project root
2. Update the `PLACE_PATH` in `export.luau` to match your file name
3. Run the extraction:

```bash
lune run scripts/export.luau
```

This will extract all scripts from:

- **ReplicatedStorage** → `src/shared/`
- **StarterPlayerScripts** → `src/client/`
- **ServerScriptService** → `src/server/`

For more help, check out [the Rojo documentation](https://rojo.space/docs).
