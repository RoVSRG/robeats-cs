import 'dotenv/config';
import { createClient as createValkeyClient } from 'redis';
import { Pool } from 'pg';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '#prisma';

async function connectToValkey() {
  // Initialize Valkey client from environment variables
  const tlsEnv = process.env.VALKEY_TLS;
  const defaultHost = process.env.VALKEY_HOST || '127.0.0.1';
  const defaultPort = process.env.VALKEY_PORT || '6379';
  const username = process.env.VALKEY_USERNAME || '';
  const password = process.env.VALKEY_PASSWORD || '';
  const dbIndex = process.env.VALKEY_DB
    ? Number(process.env.VALKEY_DB)
    : undefined;
  const explicitUrl = process.env.VALKEY_URL;
  const rejectUnauthorizedEnv = process.env.VALKEY_TLS_REJECT_UNAUTHORIZED;

  // Infer TLS
  let useTls =
    typeof tlsEnv === 'string'
      ? tlsEnv.toLowerCase() === 'true' || tlsEnv === '1'
      : undefined;
  if (useTls === undefined) {
    useTls =
      (explicitUrl && explicitUrl.startsWith('rediss://')) ||
      defaultPort === '25061';
  }

  // Default rejectUnauthorized
  const rejectUnauthorized =
    typeof rejectUnauthorizedEnv === 'string'
      ? !(
          rejectUnauthorizedEnv.toLowerCase() === 'false' ||
          rejectUnauthorizedEnv === '0'
        )
      : !defaultHost.includes('ondigitalocean.com');

  const connectionScheme = useTls ? 'rediss' : 'redis';
  const userPart = username ? `${encodeURIComponent(username)}` : '';
  const passPart = password ? `:${encodeURIComponent(password)}` : '';
  const atPart = userPart || passPart ? '@' : '';
  const portPart = defaultPort ? `:${defaultPort}` : '';
  const url =
    explicitUrl ||
    `${connectionScheme}://${userPart}${passPart}${atPart}${defaultHost}${portPart}`;

  const valkey = createValkeyClient({
    url,
    username: username || undefined,
    password: password || undefined,
    database: dbIndex,
    // Provide a full socket options object regardless, to satisfy exactOptionalPropertyTypes
    socket: useTls ? { tls: true, rejectUnauthorized } : { tls: false },
  } as any);

  valkey.on('error', (err: unknown) => {
    console.error('Valkey client error:', err);
  });

  return valkey;
}

(async () => {
  try {
    const pool = new Pool({
      connectionString: process.env.DATABASE_URL,
    });
    const prisma = new PrismaClient({
      adapter: new PrismaPg(pool),
    });
    await prisma.$connect();
    console.log('Connected to the database successfully (Prisma)');

    const valkey = await connectToValkey();

    try {
      await (valkey as any).connect();
      console.log('Connected to Valkey');
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : String(err);
      console.error('Failed to connect to Valkey:', message);
    }

    console.log('Importing app module...');
    const { start } = await import('./app.js');
    console.log('Starting application...');
    await start(prisma as any, valkey as any);
    console.log('Application started successfully');
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : String(error);
    console.error('Error starting application:', message);
    process.exit(1);
  }
})();
