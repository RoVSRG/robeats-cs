# Docker Setup Guide

This project now supports full containerization with seamless switching between local and production databases.

## Architecture

- **Base Configuration** (`docker-compose.yml`): Contains the core app service definition
- **Local Development** (`docker-compose.local.yml`): Adds PostgreSQL and Valkey containers
- **Production** (`docker-compose.prod.yml`): Connects to DigitalOcean managed databases

## Environment Files

- **`.env`**: Production credentials (DigitalOcean databases) - **DO NOT COMMIT**
- **`.env.local`**: Local development overrides
- **`.env.docker`**: Container-specific settings

## Quick Start

### Local Development (with local databases)
```bash
# Start local containers (PostgreSQL + Valkey + App)
npm run docker:local

# Push database schema
npm run docker:db:push:local

# View logs
npm run docker:local:logs

# Stop containers
npm run docker:local:down
```

### Production Mode (with DigitalOcean databases)
```bash
# Start production container (connects to DO databases)
npm run docker:prod

# View logs  
npm run docker:prod:logs

# Stop container
npm run docker:prod:down
```

### Development with Hot Reload
```bash
# Start with volume mounting for development
npm run docker:local:dev
```

## Available Scripts

### Simplified Commands
- `npm run docker:local` - Start local development (PostgreSQL + Valkey + App)
- `npm run docker:prod` - Start production (App only, connects to DO databases)
- `npm run docker:dev` - Development mode with hot reload
- `npm run docker:down` - Stop all containers
- `npm run docker:build` - Build containers
- `npm run docker:reset` - Reset with fresh build
- `npm run docker:db:push` - Push database schema (auto-detects environment)
- `npm run docker:db:migrate` - Run database migrations (auto-detects environment)

### Logging
- `npm run docker:local:logs` - View local app logs
- `npm run docker:prod:logs` - View production app logs

## Development Workflow

### Production Mode (Default)
```bash
npm run docker:up
```
Builds optimized container, persistent data.

### Development Mode
```bash
npm run docker:dev
```
Uses bind mounts for live code reloading.

### Database Operations
```bash
# Run migrations
npm run docker:db:migrate

# Reset database
npm run docker:db:reset
```

## Environment Configuration

Edit `.env` file with your configuration:

```env
# Database
DATABASE_URL=postgresql://robeats:your_password@postgres:5432/robeats

# Valkey
VALKEY_HOST=valkey
VALKEY_PORT=6379

# Security
API_KEY=your_secure_api_key_change_in_production
```

## Ports

- **3000** - API Server
- **5432** - PostgreSQL (exposed for external tools)
- **6379** - Valkey (exposed for external tools)

## Health Checks

All services include health checks:
- **postgres** - `pg_isready`
- **valkey** - `valkey-cli ping`
- **app** - HTTP GET to `/`

## Volumes

Persistent data volumes:
- `postgres_data` - Database files
- `valkey_data` - Cache persistence (optional)

## Troubleshooting

### Container won't start
```bash
# Check service status
docker-compose ps

# View all logs
docker-compose logs

# Reset everything
npm run docker:reset
```

### Database connection issues
```bash
# Check PostgreSQL logs
docker-compose logs postgres

# Verify database is ready
docker-compose exec postgres pg_isready -U robeats
```

### Valkey connection issues
```bash
# Check Valkey logs
docker-compose logs valkey

# Test Valkey connection
docker-compose exec valkey valkey-cli ping
```

### App container issues
```bash
# Check app logs
npm run docker:logs

# Run shell in app container
docker-compose exec app sh
```

## Production Deployment

1. **Security:** Change default passwords and API keys
2. **Environment:** Set `NODE_ENV=production`
3. **TLS:** Configure HTTPS reverse proxy (nginx/traefik)
4. **Monitoring:** Add logging and metrics collection
5. **Backup:** Set up PostgreSQL backups

## Manual Testing

Once services are running:

```bash
# Health check
curl http://localhost:3000/

# Expected: {"status":"ok"}
```

For API testing with proper authentication, use the API_KEY from your .env file:

```bash
curl "http://localhost:3000/players/join?api_key=your_api_key_here" \
  -H "Content-Type: application/json" \
  -d '{"userId":123,"name":"TestUser"}'
```