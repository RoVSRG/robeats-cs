# Robeats Two-Way Sync Setup

This project uses a **full Rojo setup** with two-way synchronization between VS Code and Roblox Studio. **No build process required** - your source files work directly!

## 🚀 Quick Start

### Method 1: VS Code Task (Recommended)
1. Open the project in VS Code
2. The **"Two-Way Sync (Full Rojo)"** task will auto-start when you open the workspace
3. Or manually run it: `Ctrl+Shift+P` → "Tasks: Run Task" → "Two-Way Sync (Full Rojo)"

### Method 2: Manual Scripts
**Windows:**
```powershell
# PowerShell
./scripts/sync.ps1

# Or Batch
./scripts/sync.bat
```

**macOS/Linux:**
```bash
./scripts/sync.sh
```

**Cross-platform (Lune):**
```bash
lune run scripts/sync-launcher.luau
```

## 📁 Project Structure

```
robeats-cs-scripts/
├── src/
│   ├── client/          # StarterPlayerScripts
│   ├── server/          # ServerScriptService  
│   ├── shared/          # ReplicatedStorage
│   └── gui/             # StarterGui (synced from Studio)
├── scripts/
│   ├── sync-launcher.luau   # Main two-way sync orchestrator
│   ├── studio-watcher.luau  # Watches for Studio saves
│   └── sync.{ps1,bat,sh}    # Platform-specific launchers
└── default.project.json     # Full game hierarchy mapping
```

## 🔄 Development Workflow

### 1. Script Development (VS Code → Studio)
- Edit any `.lua` or `.luau` file in `src/`
- **Auto-syncs live** to Studio via `rojo serve`
- Full IntelliSense and autocomplete for entire game hierarchy

### 2. GUI Development (Studio → VS Code)
- Edit GUI in Roblox Studio visually
- **Save the place file** (`Ctrl+S`)
- GUI changes **auto-pull** to `src/gui/` within 2 seconds
- Changes are **auto-committed** to Git with message "Auto-sync GUI from Studio"

### 3. Full IntelliSense
- VS Code can see the **entire game hierarchy**:
  - `game.ReplicatedStorage.*` (from `src/shared/`)
  - `game.StarterGui.*` (from `src/gui/`)
  - `game.ServerScriptService.*` (from `src/server/`)
  - `game.StarterPlayerScripts.*` (from `src/client/`)

## 🛠 Technical Details

### Two-Way Sync Components
1. **Rojo Serve**: `rojo serve default.project.json --port 34872`
   - Pushes VS Code changes → Studio in real-time
2. **Studio Watcher**: `scripts/studio-watcher.luau`
   - Detects place file saves
   - Runs `rojo upload --include StarterGui` 
   - Auto-commits changes to Git

### No Build Process Needed
- ✅ **Direct development**: Your `src/` files work as-is
- ✅ **No transforms**: `require(game.ReplicatedStorage.Module)` works directly
- ✅ **No dist/ folder**: Rojo handles everything live
- ✅ **Faster workflow**: Save and see changes instantly

### Prerequisites
- **Lune** (script runner): https://github.com/lune-org/lune
- **Rojo** (sync tool): https://rojo.space/docs/installation/

## 🎯 Benefits

### For Developers
- **Best of both worlds**: Code in VS Code, design GUI in Studio
- **Live sync** in both directions
- **No build step**: Direct file editing with instant updates
- **Full type safety** and IntelliSense for entire game
- **Git-friendly** GUI files (automatically committed)

### For AI/Copilot
- **Complete project visibility**: Scripts AND GUI hierarchy
- **Better code suggestions** with full game context
- **Easier refactoring** across entire codebase

## 🔧 Troubleshooting

### Studio Watcher Not Working
1. Ensure place file exists in project root (`.rbxl` or `.rbxlx`)
2. Check that Rojo is installed and in PATH
3. Verify `src/gui/` directory exists

### Rojo Serve Failing
1. Check port 34872 isn't in use: `netstat -an | findstr 34872`
2. Ensure `default.project.json` is valid
3. Try running `rojo serve` manually first

### Git Issues
1. If auto-commits fail, check Git configuration
2. Ensure you're in a Git repository with valid remote

## 🎉 What Changed

### Removed (No Longer Needed)
- ❌ `build.project.json` - No separate build configuration
- ❌ `dist/` folder - No build artifacts
- ❌ All build scripts (`build.luau`, `build.bat`, etc.)
- ❌ Transform scripts (`transform.luau`, `watch.luau`)
- ❌ `@shared/` require transforms - Use direct references

### Simplified Workflow
- ✅ **One project file**: `default.project.json` handles everything
- ✅ **Direct editing**: Edit `src/` files, see changes in Studio instantly
- ✅ **Clean repository**: Only source files, no build artifacts
