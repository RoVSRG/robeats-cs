import fastify from 'fastify';
import type { FastifyInstance } from 'fastify';
// import './types/fastify.js';
import fastifyCors from '@fastify/cors';
import fastifySwagger from '@fastify/swagger';
import fastifySwaggerUI from '@fastify/swagger-ui';

// Keep NodeNext-style explicit extensions for runtime ESM resolution
import scoresRoutes from './routes/scores.js';
import playersRoutes from './routes/players.js';
import type { PrismaClient } from '#prisma';

export interface StartOptions {
  prisma: PrismaClient;
  valkey: {
    isOpen?: boolean;
    quit: () => Promise<void>;
    zAdd: (
      key: string,
      entries: Array<{ score: number; value: string }>
    ) => Promise<void>;
    del: (key: string) => Promise<number>;
  };
}

async function seedLeaderboard(
  prisma: StartOptions['prisma'],
  valkey: StartOptions['valkey']
): Promise<void> {
  const LEADERBOARD_KEY = 'leaderboard:players:rating';

  try {
    console.log('Starting leaderboard seeding...');
    const rows = await prisma.player.findMany({
      where: { allowed: true },
      select: { user_id: true, rating: true },
    });

    if (Array.isArray(rows) && rows.length > 0) {
      await valkey.del(LEADERBOARD_KEY);

      const chunkSize = 1000;
      for (let i = 0; i < rows.length; i += chunkSize) {
        const chunk = rows.slice(i, i + chunkSize);
        const entries = chunk.map((r) => ({
          score: Number(r.rating) || 0,
          value: String(r.user_id),
        }));

        if (entries.length > 0) {
          await valkey.zAdd(LEADERBOARD_KEY, entries);
        }
      }
      console.log(`✓ Seeded Valkey leaderboard with ${rows.length} players`);
    } else {
      console.log('No players found to seed Valkey leaderboard');
    }
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    console.error('✗ Error seeding Valkey leaderboard:', message);
    throw err;
  }
}

export async function start(
  prisma: StartOptions['prisma'],
  valkey: StartOptions['valkey']
): Promise<void> {
  const app: FastifyInstance = fastify({
    // logger: true,
  });

  if (!valkey) {
    throw new Error('Valkey client not provided to start(db, valkey)');
  }

  // Ensure clean shutdown
  app.addHook('onClose', async () => {
    try {
      if ((valkey as any)?.isOpen) {
        await valkey.quit();
      }
      await prisma.$disconnect();
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : String(err);
      console.error('Error closing Valkey client:', message);
    }
  });

  // API Key middleware - check all requests for api_key query parameter
  app.addHook('preHandler', async (request, reply) => {
    // Skip API key check for the root health check endpoint (ignore query string)
    const pathOnly = request.url?.split('?')[0] || '';
    if (pathOnly === '/') {
      request.log.info('Skipping API key check for health check endpoint');
      return;
    }

    const apiKey = (request.query as any).api_key as string | undefined;
    const validApiKey = process.env.API_KEY;

    if (!apiKey || apiKey !== validApiKey) {
      return reply.code(404).send({ error: 'Not found' });
    }
  });

  // Decorate for downstream routes
  (app as any).valkey = valkey;
  (app as any).prisma = prisma;

  await app.register(scoresRoutes as any, {
    prisma,
    kv: valkey,
    prefix: '/scores',
  });
  await app.register(playersRoutes as any, {
    prisma,
    kv: valkey,
    prefix: '/players',
  });

  // Add reply decorators for consistent response structure
  app.decorateReply('success', function (data: any = {}) {
    return this.send({ success: true, ...data });
  });

  app.decorateReply('error', function (error: string, status: number = 500) {
    return this.status(status).send({ success: false, error });
  });

  await app.register(fastifyCors, {
    origin: true,
  });

  // Register Swagger plugin
  await app.register(fastifySwagger, {
    openapi: {
      openapi: '3.0.0',
      info: {
        title: 'Robeats API',
        description: 'API for Robeats score submission and leaderboards',
        version: '1.0.0',
      },
      servers: [
        {
          url: 'http://localhost:3000',
          description: 'Development server',
        },
      ],
    },
  });

  // Register Swagger UI
  await app.register(fastifySwaggerUI, {
    routePrefix: '/docs',
    uiConfig: {
      docExpansion: 'full',
      deepLinking: false,
    },
    uiHooks: {
      onRequest: function (request: any, reply: any, next: any) { next() },
      preHandler: function (request: any, reply: any, next: any) { next() }
    },
    staticCSP: true,
    transformStaticCSP: (header: any) => header,
    transformSpecification: (swaggerObject: any, request: any, reply: any) => { return swaggerObject },
    transformSpecificationClone: true
  });

  app.get('/', async (_req, reply) => {
    return reply.send({ status: 'ok1' });
  });

  app.listen({ port: 3000, host: '0.0.0.0' }, (err, address) => {
    if (err) {
      app.log.error(err);
      process.exit(1);
    }
    app.log.info(`Server listening at ${address}`);

    // Start leaderboard seeding in background after server is ready
    Promise.resolve()
      .then(() => seedLeaderboard(prisma, valkey))
      .catch((error) => {
        const message = error instanceof Error ? error.message : String(error);
        console.error('Background seeding failed:', message);
      });
  });
}
