<img src="assets/logo.png" style="width: 100%; margin-bottom: -60px"/>

### The natural successor to the skill-based rhythm game. 🎵

## Prerequisites

Before setting up the project, ensure you have the following installed:

### Required Software

- **Node.js 18+** - JavaScript runtime
- **Docker & Docker Compose** - For running the backend services
- **Git** - Version control (with submodule support)

### Optional but Recommended

- **Roblox Studio** - For testing the game client
- **Visual Studio Code** - Recommended editor with Nx extension

## Project Structure

This is an Nx monorepo containing several packages:

### Core Packages

- **`packages/backend/`** - Fastify API server with Prisma ORM
  - Database: PostgreSQL
  - Cache: Valkey (Redis-compatible)
  - API documentation: OpenAPI/Swagger UI
- **`packages/cli/`** - Command-line interface tool built with Ink
- **`packages/sdk/`** - TypeScript library for generating Roblox Lua SDK
- **`packages/game/`** - Roblox game client code
- **`packages/songs/`** - Song data processing and management
- **`packages/tooling/`** - Development tools and file watchers

### Tools & Configuration

- **`tools/`** - Vendored CLI tools (Rojo, Lune)
- **`default.project.json`** - Rojo project configuration for Roblox
- **`nx.json`** - Nx workspace configuration

## Quick Setup

### Windows (PowerShell)

```powershell
# Run the automated setup script
.\setup.ps1
```

The setup script will:

- ✅ Validate Node.js version (18+ required)
- ✅ Initialize git submodules
- ✅ Download and install Rojo (v7.5.1) and Lune (v0.10.1)
- ✅ Install npm dependencies
- ✅ Build song data
- ✅ Start Docker containers (if Docker is available)

## Manual Setup (Alternative)

If you prefer to set up manually:

1. **Install Node.js 18+**

   ```bash
   # Verify version
   node --version  # Should be 18.0.0 or higher
   ```

2. **Clone and initialize submodules**

   ```bash
   git submodule update --init --recursive
   ```

3. **Install dependencies**

   ```bash
   npm install
   ```

4. **Download tools manually**
   ```bash
   # The setup script handles this automatically
   # But you can manually download from:
   # - Rojo: https://github.com/rojo-rbx/rojo/releases
   # - Lune: https://github.com/lune-org/lune/releases
   ```

## Environment Configuration

### Backend Environment Variables

Create `packages/backend/.env.local` (development) or `packages/backend/.env` (production):

```bash
# Database
DATABASE_URL=postgresql://robeats:robeats_password_change_in_production@db:5432/robeats?schema=public

# Cache (Valkey/Redis)
VALKEY_HOST=valkey
VALKEY_PORT=6379

# API Security
API_KEY=dev_change_me

# Environment
NODE_ENV=development
```

For production, use managed services:

```bash
DATABASE_URL=postgresql://user:password@managed-db-host:25060/robeats?schema=public
VALKEY_HOST=managed-valkey-host
VALKEY_PORT=25061
VALKEY_TLS=true
NODE_ENV=production
```

## Development Workflow

### Start the Full Development Stack

```bash
# Start backend API + database + cache
npm run dev:backend

# In another terminal, start the game server
npm run serve:game

# Or run everything concurrently
npm run dev:game
```

### Database Management

```bash
# Run database migrations
npm run db:migrate

# View database in browser
npm run db:studio

# Reset database (development only)
npx prisma migrate reset --force
```

### Building

```bash
# Build all packages
npm run build

# Build specific packages
npm run build:backend
npm run build:game
npm run build:songs
npm run build:sdk
```

### Development Commands

```bash
# Start file watchers
nx run tooling:watch
```

## Docker Commands

### Backend Development

```bash
# Start full local stack (API + Postgres + Valkey)
npm run dev:up

# View logs
npm run dev:logs

# Stop containers
npm run down

# Rebuild containers
npm run rebuild
```

### Production

```bash
# Start production API only
npm run up

# View production logs
npm run logs
```

## Roblox Development

### Using Rojo

Rojo synchronizes your game files with Roblox Studio:

```bash
# Serve game for live development
npm run serve:game

# Build game file
npm run build:game
```

### Studio Setup

1. Open Roblox Studio
2. Connect to Rojo server (usually `localhost:34872`)
3. The game structure will be automatically synced

## API Documentation

Once the backend is running:

- **API Docs**: http://localhost:3000/docs (Swagger UI)
- **Health Check**: http://localhost:3000/

## Troubleshooting

### Run Diagnostics

```bash
# Check system requirements and configuration
node scripts/doctor.mjs
```

### Common Issues

**"Node version too old"**

- Update to Node.js 18+ from https://nodejs.org

**"Docker not found"**

- Install Docker Desktop
- Ensure Docker daemon is running

**"Database connection failed"**

- Check if containers are running: `docker compose ps`
- Verify DATABASE_URL in environment files
- Run migrations: `npm run db:migrate`

**"Rojo/Lune not found"**

- Run setup script again: `npm run setup`
- Or manually download from GitHub releases and place binaries within tools/bin

**"Submodules not initialized"**

```bash
git submodule update --init --recursive
```

### Logs and Debugging

```bash
# View all service logs
docker compose logs

# View specific service logs
docker compose logs api
docker compose logs db
docker compose logs valkey

# View Nx build output
nx run backend:build --verbose
```

## Development Tips

- Use `npm run dev:game` for concurrent development
- The tooling watcher (`nx run tooling:watch`) monitors changes to any place file at the root directory and extracts the contents of a ScreenGui named Dev into game/gui.
- SDK generation requires the backend to be running
- Database schema changes require migrations
- Test game changes in Roblox Studio with Rojo sync

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `npm run test`
5. Build all packages: `npm run build`
6. Submit a pull request

## License

MIT License - see individual package licenses for details.
