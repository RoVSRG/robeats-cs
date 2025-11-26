# Docker Setup (Single Compose File)

All environments now use a single `docker-compose.yml` file. The same file can:

1. Run only the API container (production / managed services)
2. Run API + local Postgres + local Valkey (local dev stack)

Behavior is controlled purely by environment variables and provided `.env` files.

## Environment Files

- `.env` – baseline / production (managed DB + Valkey hostnames)
- `.env.local` – local overrides (optional; ignored if absent)

In local dev you typically set:

```
LOCAL_STACK=true
DATABASE_URL=postgresql://robeats:robeats_password_change_in_production@db:5432/robeats?schema=public
VALKEY_HOST=valkey
VALKEY_PORT=6379
API_KEY=dev_change_me
```

When `LOCAL_STACK=true`, the app will attempt to use bundled `db` and `valkey` services (they are always defined; you supply the env to treat them as your target). For production, omit `LOCAL_STACK` and supply managed service hostnames in `.env`.

## Quick Commands (Backend package)

```bash
# Start full local stack (API + Postgres + Valkey)
npm run up

# Tail logs
npm run logs

# One-off migration
npm run db:migrate

# Stop & remove
npm run down

# Rebuild image (no cache)
npm run rebuild
```

To run against production-style managed services locally (no local DB containers):

```bash
docker compose up -d --build
```

Ensure your `.env` contains the managed `DATABASE_URL`, `VALKEY_*` values.

## Local Development Flow

1. Copy `.env.example` to `.env.local` (and adjust if desired)
2. `npm run up`
3. After containers healthy: `npm run db:migrate` (if schema changed)
4. Visit http://localhost:3000/docs
5. `npm run logs` (tail API logs)
6. `npm run down` when finished

## Ports

- 3000 – API
- 5432 – Postgres (local dev only)
- 6379 – Valkey (local dev only)

## Health Checks

Automatic HTTP probe on `/` for API. Postgres and Valkey define health checks when running locally.

## Migrations & Prisma Client

Application container runs with pre-built artifacts. For schema changes:

```bash
# Inside backend package
npx prisma migrate dev       # (if you exec into container)
# or
npm run db:migrate           # one-off in ephemeral API container
```

## Switching Environments

| Scenario                      | Command                |
| ----------------------------- | ---------------------- |
| Local full stack              | `npm run up`           |
| Local rebuild                 | `npm run rebuild`      |
| Local stop/remove             | `npm run down`         |
| Prod-like (managed DB/Valkey) | `docker compose up -d` |

## Troubleshooting

```bash
docker compose ps
docker compose logs api
docker compose logs db
docker compose logs valkey
```

If API cannot connect, verify `DATABASE_URL` and `VALKEY_*` values inside the running container:

```bash
docker compose exec api env | findstr DATABASE_URL
```

## Security / Production Checklist

- Rotate `API_KEY`
- Use managed TLS endpoints (Valkey/Postgres) and set `VALKEY_TLS=true`
- Set `NODE_ENV=production`
- Place secrets in managed secret store (not `.env` committed)

## Sample `.env` (managed services)

```
DATABASE_URL=postgresql://user:password@managed-db-host:25060/robeats?schema=public
VALKEY_HOST=managed-valkey-host
VALKEY_PORT=25061
VALKEY_TLS=true
API_KEY=change_me
```

## Sample `.env.local` (dev containers)

```
DATABASE_URL=postgresql://robeats:robeats_password_change_in_production@db:5432/robeats?schema=public
VALKEY_HOST=valkey
VALKEY_PORT=6379
API_KEY=dev_change_me
```

View API docs: http://localhost:3000/docs
