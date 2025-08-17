# RoBeats Community Server

A comprehensive monorepo containing a Roblox rhythm game with TypeScript API server, featuring modern tooling, two-way sync workflow, and extensive GUI systems.

## 🚀 Quick Start

### Prerequisites

You'll need to install these tools manually:

- **[Node.js](https://nodejs.org/)** (v18+) - For the API server and monorepo management
- **[Lune](https://github.com/lune-org/lune)** - Lua runtime for build scripts and automation
- **[Rojo](https://rojo.space/docs/installation/)** - Roblox project management and syncing
- **[Git](https://git-scm.com/)** - Version control (for submodules)

### Installation

1. **Clone the repository with submodules:**
   ```bash
   git clone --recursive https://github.com/your-repo/robeats-cs.git
   cd robeats-cs
   ```

2. **If you already cloned without `--recursive`, initialize submodules:**
   ```bash
   git submodule update --init --recursive
   ```

3. **Install dependencies:**
   ```bash
   npm install
   ```

4. **Verify tool installation:**
   ```bash
   node --version
   lune --version
   rojo --version
   ```

## 📂 Project Structure

### Core Directories

```
robeats-cs/
├── package.json           # Monorepo configuration and scripts
├── roblox/                # Roblox game source code
│   ├── src/
│   │   ├── client/        # Client-side scripts (→ StarterPlayerScripts)
│   │   ├── server/        # Server-side scripts (→ ServerScriptService)  
│   │   ├── shared/        # Shared modules (→ ReplicatedStorage)
│   │   ├── gui/           # GUI screens and components (→ StarterGui)
│   │   ├── engine/        # Core RoBeats game engine
│   │   ├── state/         # State management modules
│   │   └── workspace/     # Workspace objects and environment
│   └── build/             # Built Roblox assets
├── server/                # TypeScript API server
│   ├── src/               # Server source code
│   ├── prisma/            # Database schema and migrations
│   └── package.json       # Server dependencies
├── scripts/               # Build and automation scripts
├── plugins/               # Rojo Studio plugins
├── songs/                 # Songs submodule (song data and assets)
└── default.project.json   # Rojo project configuration
```

### Key Components

#### Roblox Game (`roblox/`)
The core rhythm game implementation:

**Engine System (`roblox/src/engine/`)**
- **AudioManager** - Music and sound effect management
- **ScoreManager** - Score calculation and hit detection  
- **NoteTrack System** - Note rendering and interaction (2D & 3D modes)
- **Effects System** - Visual effects for notes and hits
- **Replay System** - Recording and playback functionality

**State Management (`roblox/src/state/`)**
- **Options** - User preferences and game settings
- **Game** - Current game session state
- **Transient** - Temporary runtime state

**GUI System (`roblox/src/gui/screens/`)**
- **MainMenu** - Landing page with player stats and navigation
- **SongSelect** - Song browser with search, filtering, and leaderboards
- **Gameplay** - In-game HUD and scoring display
- **Options** - Settings management with real-time preview
- **Multiplayer** - Room creation and lobby management

#### API Server (`server/`)
TypeScript/Node.js backend providing:
- **Player Profiles** - User registration and statistics
- **Score Submission** - Ranked score processing and validation
- **Leaderboards** - Global and per-song rankings
- **Rating System** - Performance rating calculations
- **Redis Caching** - Fast leaderboard queries
- **PostgreSQL Database** - Persistent data storage

## 🔧 Development Workflow

### Full Development Environment

Start both the API server and Roblox development environment:

```bash
# Start everything (server + Rojo)
npm run dev

# Or start components individually:
npm run dev:server      # Start API server in development mode
npm run serve:roblox    # Start Rojo server for Studio sync
```

### Two-Way Sync Development

For active GUI development with live Studio integration:

```bash
# Start the two-way sync watcher
npm run sync

# Or use direct Lune command
lune run scripts/studio-watcher.luau
```

This workflow:
1. Starts Rojo server on port 34872
2. Monitors the place file for Studio saves
3. Automatically extracts GUI changes from Studio back to source files
4. Provides real-time sync between Studio and your codebase

#### Using Two-Way Sync

1. **Open your place file in Roblox Studio**
2. **Start the sync script** (above commands)
3. **In Studio:** Create a ScreenGui named "Dev" in StarterGui
4. **Copy elements** from StarterGui.Screens to Dev using the Workflow plugin
5. **Edit in Studio** - changes are automatically synced back to source files
6. **Check git diff** to see what changed after each Studio save

## 🔄 How Two-Way Sync Works

The system watches your place file and automatically extracts GUI changes back to source files when you save in Studio.

### Setup Requirements

**1. Install the Workflow Plugin:**
- Copy `plugins/Workflow.server.lua` to your local Studio plugins folder
- This plugin adds a "Copy to Dev" button to copy GUI elements for editing

**2. Create "Dev" ScreenGui:**
- In Studio, create a ScreenGui named "Dev" in StarterGui
- This serves as your editing workspace

**3. Stage Elements for Editing:**
- Use the Workflow plugin's "Copy to Dev" button on any element in StarterGui.Screens
- The plugin automatically sets a `__BASEPATH` attribute to track the original location

### Workflow Process

1. **Start sync:** Run the sync script to begin file watching
2. **Copy element:** Use Workflow plugin to copy GUI element to "Dev" ScreenGui  
3. **Edit in Studio:** Make changes to the copied element in "Dev"
4. **Save place file:** Studio save triggers automatic sync
5. **Check changes:** Review git diff to see what was updated in source files

### Internal Process

When you save in Studio, the system:
1. **Detects file change** (polls every 1 second, waits 2 seconds after change)
2. **Reads the place file** and finds the "Dev" ScreenGui
3. **Extracts elements** from "Dev" that have `__BASEPATH` attributes
4. **Converts to Rojo format** (instances → folders, properties → `init.meta.json`)
5. **Writes to source files** at the location specified by `__BASEPATH`
6. **Shows git diff** of what changed

### Key Points

- **Only elements in "Dev" ScreenGui get synced** - production screens are protected
- **`__BASEPATH` attribute is required** - set automatically by Workflow plugin
- **Changes go to original location** - Dev/MyButton syncs back to src/gui/screens/MainMenu/MyButton
- **Git tracks everything** - all changes show up in git diff for review
- **Scripts are preserved** - LocalScripts, ModuleScripts maintain their source code

### Build Commands

```bash
# Build server for production
npm run build:server

# Build Roblox place file  
npm run build:roblox

# Build song database
npm run build:songs

# Clean all build artifacts
npm run clean
```

### Standard Rojo Workflow

For regular development without two-way sync:

```bash
# Start Rojo server
npm run serve:roblox

# Build place file
npm run build:roblox
```

## 🎵 Songs Submodule

The `songs/` directory is a Git submodule containing:
- Song audio files and metadata  
- Chart data and difficulty information
- Custom song assets and resources

**Working with songs:**
```bash
# Update songs to latest version
git submodule update --remote songs

# Check submodule status  
git submodule status

# Commit submodule updates
git add songs
git commit -m "Update songs submodule"
```

## 📜 Scripts and Automation

### Build Scripts (`scripts/`)

- **`sync.*`** - Two-way sync setup (Windows: `.bat`/`.ps1`, Unix: `.sh`)
- **`studio-watcher.luau`** - Core two-way sync implementation
- **`songs/build-songs.luau`** - Song processing and compression

### Song Management (`scripts/songs/`)

- **`build-songs.luau`** - Process and build song databases

## 💻 Code Examples

### Working with State Management

```lua
local Options = require(game.ReplicatedStorage.State.Options)
local Transient = require(game.ReplicatedStorage.State.Transient)

-- Get/set user options
local musicVolume = Options.MusicVolume:get()
Options.MusicVolume:set(0.8)

-- Working with transient state
Transient.song.rate:set(150) -- 1.5x speed
local currentRate = Transient.song.rate:get()

-- Listen for state changes
Options.MusicVolume:subscribe(function(newVolume)
    print("Volume changed to:", newVolume)
end)
```

## 🔧 Configuration Files

### Rojo Project (`default.project.json`)
Maps source directories to Roblox services:
- `src/shared/` → `ReplicatedStorage`
- `src/client/` → `StarterPlayerScripts`  
- `src/server/` → `ServerScriptService`
- `src/gui/screens/` → `StarterGui.Screens`
- `src/workspace/` → `Workspace`

## 🐛 Troubleshooting

### Common Issues

**"Lune not found" error:**
- Make sure Lune is installed and in your PATH
- Try restarting your terminal after installation

**"Rojo connection failed" error:**
- Check if another Rojo instance is running on port 34872
- Try `rojo serve --port 34873` for alternative port

**Submodule is empty:**
- Run `git submodule update --init --recursive`
- Check if you have access to the songs repository

**Two-way sync not working:**
- Ensure you have a "Dev" ScreenGui in StarterGui
- Check that elements copied to Dev have the `__BASEPATH` attribute
- Verify the place file exists in the project root

## 🔧 Monorepo Commands

### Development
```bash
npm run dev              # Start both server and Roblox development
npm run sync             # Two-way sync for GUI development
```

### Building
```bash
npm run build:server     # Build TypeScript server
npm run build:roblox     # Build Roblox place file
npm run build:songs      # Build song database
npm run generate:types   # Generate API contracts
```

### Quality & Testing
```bash
npm run lint:server      # Lint server code
npm run test:server      # Test server code
npm run clean            # Clean all build artifacts
```

## 🚀 Deployment

The monorepo includes CI/CD pipelines that:

1. **Test & Build** - Validates both server and Roblox components
2. **Generate Types** - Ensures API contracts are synchronized
3. **Integration Tests** - Validates server/client communication
4. **Security Scanning** - Checks for vulnerabilities
5. **Automated Deployment** - Deploys to staging/production environments

## 📚 Additional Resources

- **[Rojo Documentation](https://rojo.space/docs)** - Project management and syncing
- **[Lune Documentation](https://lune-org.github.io/docs)** - Scripting and automation
- **[Fastify Documentation](https://www.fastify.io/docs/latest/)** - Server framework
- **[Prisma Documentation](https://www.prisma.io/docs)** - Database ORM