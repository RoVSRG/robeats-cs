import type { FastifyPluginAsync } from 'fastify';
// import '../types/fastify.js';
import type { PrismaClient } from '#prisma';
import {
  getPlayerProfile,
  upsertPlayer,
  formatPlayerProfile,
  updateLeaderboard,
  getPlayerRank,
} from '../database/queries.js';
import {
  PlayerJoinSchema,
  PlayerProfileQuerySchema,
} from '../contracts/player-contracts.js';

const playersRoutes: FastifyPluginAsync<
  { prisma: PrismaClient; kv: any } & { prefix?: string }
> = async (app, opts) => {
  const prisma = opts.prisma;
  const kv = opts.kv || (app as any).valkey;
  const LEADERBOARD_KEY = 'leaderboard:players:rating';

  app.post('/join', async (req, reply) => {
    const parsed = PlayerJoinSchema.safeParse((req as any).body);
    if (!parsed.success) {
      return reply.error(parsed.error.message || 'Validation failed', 400);
    }

    const { userId, name } = parsed.data;

    try {
      await upsertPlayer(prisma, userId, name);

      // Sync leaderboard entry in Valkey with current DB rating
      try {
        const row = await getPlayerProfile(prisma, userId);
        const rating = Number(row?.rating ?? 0);
        await updateLeaderboard(kv, LEADERBOARD_KEY, userId, rating);
      } catch (e: any) {
        (req as any).log.error(
          e,
          'Failed to upsert player into Valkey leaderboard'
        );
      }

      return reply.success();
    } catch (err: any) {
      (req as any).log.error(err);
      return reply.error(err.message, 500);
    }
  });

  // GET /players/top - top 100 players by rating, enriched with profile data
  app.get('/top', async (req, reply) => {
    try {
      const entries = await kv.zRangeWithScores(LEADERBOARD_KEY, 0, 99, {
        REV: true,
      });

      if (!entries || entries.length === 0) {
        return reply.success({ players: [] });
      }

      const userIds = entries
        .map((e: any) => Number(e.value))
        .filter((id: number) => Number.isFinite(id));

      const rows = await prisma.player.findMany({
        where: {
          allowed: true,
          user_id: { in: userIds.map((id: number) => BigInt(id)) },
        },
        select: {
          user_id: true,
          name: true,
          rating: true,
          accuracy: true,
          play_count: true,
        },
      });

      const metaByUserId = new Map(
        rows.map((r: any) => [Number(r.user_id), r])
      );

      const players = entries.map((entry: any, index: number) => {
        const userId = Number(entry.value);
        const meta = metaByUserId.get(userId);
        return {
          userId,
          name: meta?.name ?? null,
          rating: Number(entry.score), // from leaderboard
          rank: index + 1,
          accuracy: meta?.accuracy ?? null,
          playCount: meta?.play_count ?? null,
        };
      });

      return reply.success({ players });
    } catch (err: any) {
      (req as any).log.error(err);
      return reply.error(err.message, 500);
    }
  });

  // GET /players?userId=xxx - profile with calculated rank
  app.get('/', async (req, reply) => {
    const parsed = PlayerProfileQuerySchema.safeParse((req as any).query);
    if (!parsed.success) {
      return reply.error(parsed.error.message || 'Validation failed', 400);
    }

    const userId = parseInt(parsed.data.userId);

    try {
      const profile = await getPlayerProfile(prisma, userId);
      if (!profile) {
        return reply.error('Player not found', 404);
      }

      const rating = Number(profile.rating ?? 0);
      // Ensure leaderboard reflects current rating
      try {
        await updateLeaderboard(kv, LEADERBOARD_KEY, userId, rating);
      } catch (e: any) {
        (req as any).log.error(
          e,
          'Failed to ensure leaderboard entry in Valkey'
        );
      }

      const rank = await getPlayerRank(kv, LEADERBOARD_KEY, userId);

      const safeProfile = formatPlayerProfile(profile);
      return reply.success({ profile: { ...safeProfile, rank } });
    } catch (err: any) {
      (req as any).log.error(err);
      return reply.error(err.message, 500);
    }
  });
};

export default playersRoutes;
