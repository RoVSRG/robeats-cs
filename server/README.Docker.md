# RoBeats Server Docker Setup

This document explains how to run the RoBeats server using Docker with PostgreSQL and Valkey.

## Quick Start

1. **Copy environment template:**
   ```bash
   cp .env.docker .env
   ```

2. **Start all services:**
   ```bash
   npm run docker:up
   ```

3. **View logs:**
   ```bash
   npm run docker:logs
   ```

4. **Stop services:**
   ```bash
   npm run docker:down
   ```

## Services

- **app** - RoBeats API server (Node.js/TypeScript)
- **postgres** - PostgreSQL database
- **valkey** - Redis-compatible cache for leaderboards

## Available Scripts

| Command | Description |
|---------|-------------|
| `npm run docker:build` | Build the app container |
| `npm run docker:up` | Start all services in detached mode |
| `npm run docker:down` | Stop and remove containers |
| `npm run docker:logs` | Follow app container logs |
| `npm run docker:dev` | Start with development profile |
| `npm run docker:reset` | Full reset - destroy volumes and rebuild |
| `npm run docker:db:migrate` | Run Prisma migrations |
| `npm run docker:db:reset` | Reset database with Prisma |

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