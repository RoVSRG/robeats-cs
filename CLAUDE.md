# RoBeats Community Server - Codebase Documentation

## Project Overview

This is a RoBeats Community Server project built with Roblox Studio, featuring a rhythm game with custom song support, multiplayer functionality, and extensive GUI systems.

## Directory Structure

### Root Level

- `RoBeats Community Server.rbxl` - Main Roblox place file
- `default.project.json` - Rojo project configuration
- `sourcemap.json` - Source mapping for debugging
- `SYNC_SETUP.md` - Documentation for sync setup
- `README.md` - Project documentation

### `/scripts/` - Build and Development Scripts

- `studio-watcher.luau` - **Auto-sync script that pulls GUI changes from Studio**
- `sync.bat/ps1/sh` - Platform-specific sync scripts
- `test.luau` - Testing utilities
- `unwind.luau` - Cleanup utilities
- `songs/` - Song processing scripts
  - `build-songs.luau` - Song compilation
  - `compression.luau` - Audio compression utilities
  - `conversion.luau` - Format conversion

### `/src/` - Main Source Code

#### `/src/client/` - Client-side Scripts

- `Main.client.lua` - Primary client initialization
- `GuiScaling.client.lua` - UI scaling management
- `TagHandler.client.lua` - Instance tag handling

#### `/src/engine/` - Game Engine Core

- `RobeatsGame.lua` - Main game logic controller
- `AudioManager.lua` - Audio playback and synchronization
- `ScoreManager.lua` - Score calculation and tracking
- `SFXManager.lua` - Sound effects system
- `Replay.lua` - Replay recording/playback
- `ObjectPool.lua` - Object pooling for performance
- `Effects/` - Visual effects system
- `Enums/` - Game enumerations (GameSlot, Grade, Mods, etc.)
- `NoteTrack/` - Note tracking and button systems
- `NoteTypes/` - Different note type implementations
- `Types/` - Type definitions

#### `/src/gui/` - **AUTO-GENERATED GUI Files**

**� IMPORTANT: This directory is auto-populated by `studio-watcher.luau`**

Structure:

- `screens/` - All game screens (auto-synced from Studio)
  - `MainMenu/` - Main menu interface
  - `SongSelect/` - Song selection screen
  - `Gameplay/` - In-game UI elements
  - `Options/` - Settings and configuration
  - `Changelog/` - Update notifications
  - `GlobalRanking/` - Leaderboards
  - `Initialize/` - Loading screens
  - `YourScores/` - Player score history

Each screen contains:

- `init.meta.json` - Rojo metadata for UI properties
- `.client.lua` - Client-side GUI logic scripts
- Nested folders for UI hierarchies with their own metadata

#### `/src/remotes/` - Network Communication

- `events/` - RemoteEvent definitions
- `functions/` - RemoteFunction definitions

#### `/src/server/` - Server-side Logic

- `Multiplayer.server.lua` - Multiplayer room management
- `SongStreamer.server.lua` - Song data streaming
- `ScoreSubmission.server.lua` - Score validation and storage
- `PlayerBus.server.lua` - Player data management
- Additional server utilities

#### `/src/shared/` - Shared Libraries

- `SongDatabase.lua` - Song metadata and management
- `Countries.lua` - Country/region data
- `Libraries/` - Utility libraries (compression, time, signals, etc.)
- `Modules/` - Game modules (effects, screen management)
- `Serialization/` - Data serialization systems
- `Shared/` - Common utilities

#### `/src/skins/` - Visual Themes

- `.rbxm` files - Roblox model files for different UI skins
- `init.lua` - Skin loading system

#### `/src/state/` - State Management

- `Game.lua` - Game state controller
- `Options.lua` - Settings state
- `Transient.lua` - Temporary state data

### `/songs/` - Song Content (Git Submodule)

**Git submodule** containing a massive collection of rhythm game songs, each with:

- `metadata.yml` - Song information (title, artist, BPM, etc.)
- `objects.yml` - Note timing and chart data

## Studio-Watcher System

### How `scripts/studio-watcher.luau` Works

The studio-watcher is a critical development tool that enables two-way sync between Roblox Studio and the file system for GUI development.

#### Key Features:

1. **File Monitoring** - Watches `.rbxl/.rbxlx` files for changes (1-second intervals, 2-second debounce)
2. **Auto-Export** - Extracts GUI from Studio's `StarterGui.Dev` to `src/gui/screens/`
3. **Rojo Compatibility** - Serializes Roblox instances to Rojo-compatible JSON format
4. **Cross-platform** - Handles Windows filename restrictions and sanitization

#### Workflow:

1. **Studio Setup**: Create a `ScreenGui` named "Dev" in `StarterGui`
2. **Path Attribution**: Set `__BASEPATH` attribute on Dev ScreenGui (e.g., `game.StarterGui.Screens.MainMenu`)
3. **Auto-Sync**: When Studio saves, watcher detects changes and exports to filesystem
4. **File Structure**: Creates `init.meta.json` files with UI properties and `.client.lua` for scripts

#### Export Process:

- **Instance Serialization** - Converts Roblox objects to JSON with proper typing
- **Property Handling** - Serializes Color3, Vector3, UDim2, Enums, etc. in Rojo format
- **Script Export** - LocalScripts � `.client.lua`, ModuleScripts � `.lua`, Scripts � `.server.lua`
- **Cleanup** - Removes orphaned directories when instances are deleted in Studio
- **Git Integration** - Shows diff summary after sync operations

#### File Naming:

- Sanitizes Windows-invalid characters (`< > : " | ? *`)
- Handles reserved Windows names (CON, PRN, AUX, etc.)
- Preserves original hierarchy and relationships

### Two-Way Sync Benefits:

- **Visual Editing** - Use Studio's visual editor for GUI layout
- **Code Management** - Scripts remain in filesystem for version control
- **Team Collaboration** - Multiple developers can work on GUI and code separately
- **Asset Management** - Images and UI elements managed through Studio's asset system

## Development Workflow

1. Edit GUI visually in Studio under `StarterGui.Dev`
2. Studio-watcher auto-exports changes to `src/gui/screens/`
3. Git tracks all changes for version control
4. Rojo syncs filesystem back to Studio for testing

## Important Notes

- `src/gui/` is auto-generated - **DO NOT EDIT MANUALLY**
- All GUI changes should be made in Studio under `StarterGui.Dev`
- Use proper `__BASEPATH` attributes for correct export paths
- Studio-watcher requires the place file to be in project root
