import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';

import { calculateOverallRating } from '../calculator/rating.js';
import { calculateAverageAccuracy } from '../calculator/accuracy.js';

import type { PrismaClient } from '#prisma';

import {
  getBestScore,
  getLeaderboard,
  getUserBestScores,
  upsertPlayer,
  updatePlayerRating,
  formatPlayerProfile,
  updateLeaderboard,
  getPlayerRank,
} from '../database/queries.js';

const scoresRoutes: FastifyPluginAsync<
  { prisma: PrismaClient; kv: any } & { prefix?: string }
> = async (app, opts) => {
  const prisma = opts.prisma; // provided from app
  const kv = opts.kv || (app as any).valkey;

  const GLOBAL_LEADERBOARD_KEY = 'leaderboard:players:rating';

  app.get('/leaderboard', async (req, reply) => {
    const parsed = z
      .object({
        hash: z.string().min(1),
        userId: z.string().transform((val) => parseInt(val)),
      })
      .safeParse((req as any).query);

    if (!parsed.success) {
      return reply.error(parsed.error.message || 'Validation failed', 400);
    }

    const { hash, userId } = parsed.data;

    try {
      const [leaderboard, best] = await Promise.all([
        getLeaderboard(prisma, hash),
        getBestScore(prisma, hash, userId),
      ]);

      return reply.success({ best, leaderboard });
    } catch (err: any) {
      (req as any).log.error(err);
      return reply.error(err.message, 500);
    }
  });

  // User's best scores per song
  app.get('/user/best', async (req, reply) => {
    const parsed = z
      .object({ userId: z.string().transform((val) => parseInt(val)) })
      .safeParse((req as any).query);

    if (!parsed.success) {
      return reply.error(parsed.error.message || 'Validation failed', 400);
    }

    const { userId } = parsed.data;

    try {
      const result = await getUserBestScores(prisma, userId);
      return reply.success({ scores: result });
    } catch (err: any) {
      (req as any).log.error(err);
      return reply.error(err.message, 500);
    }
  });

  // Submit score
  app.post('/', async (req, reply) => {
    const parsed = z
      .object({
        user: z.object({
          userId: z.number().int().positive(),
          name: z.string().min(1),
        }),
        payload: z.object({
          hash: z.string().min(1),
          rate: z.number().min(70).max(200),
          score: z.number().int().nonnegative(),
          accuracy: z.number().min(0).max(100),
          combo: z.number().int().nonnegative(),
          maxCombo: z.number().int().nonnegative(),
          marvelous: z.number().int().nonnegative(),
          perfect: z.number().int().nonnegative(),
          great: z.number().int().nonnegative(),
          good: z.number().int().nonnegative(),
          bad: z.number().int().nonnegative(),
          miss: z.number().int().nonnegative(),
          grade: z.enum(['F', 'D', 'C', 'B', 'A', 'S', 'SS']),
          rating: z.number().nonnegative(),
          mean: z.number(),
        }),
      })
      .safeParse((req as any).body);

    if (!parsed.success) {
      return reply.error('Validation failed', 400);
    }

    const { user, payload } = parsed.data;

    try {
      // Step 1: Ensure player exists
      const player = await upsertPlayer(prisma, user.userId, user.name, true);

      // Step 2: Save the score
      await prisma.score.create({
        data: {
          player_id: player.id,
          hash: payload.hash,
          score: payload.score,
          accuracy: payload.accuracy,
          combo: payload.combo,
          max_combo: payload.maxCombo,
          marvelous: payload.marvelous,
          perfect: payload.perfect,
          great: payload.great,
          good: payload.good,
          bad: payload.bad,
          miss: payload.miss,
          grade: payload.grade,
          rating: payload.rating,
          rate: payload.rate,
          mean: payload.mean,
        },
      });

      // Step 3: Recalculate player's overall rating
      const bestScores = await getUserBestScores(prisma, user.userId);
      const ratings = Array.isArray(bestScores)
        ? bestScores.map((score: any) => Number(score.rating) || 0)
        : [];
      const accuracies = Array.isArray(bestScores)
        ? bestScores.map((score: any) => Number(score.accuracy) || 0)
        : [];

      const newOverallRating = calculateOverallRating(ratings);
      const newAverageAccuracy = calculateAverageAccuracy(accuracies);

      // Step 4: Update player's rating in database
      const updatedPlayer = await updatePlayerRating(
        prisma,
        player.id,
        newOverallRating,
        newAverageAccuracy
      );

      // Step 5: Update leaderboard and get rank
      const rank = await updateLeaderboardAndGetRank(
        kv,
        GLOBAL_LEADERBOARD_KEY,
        user.userId,
        newOverallRating,
        (req as any).log
      );

      // Step 6: Return updated profile
      const profile = formatPlayerProfile(updatedPlayer);
      return reply.success({ profile: { ...profile, rank } });
    } catch (err: any) {
      (req as any).log.error(err);
      return reply.error(err.message, 500);
    }
  });

  async function updateLeaderboardAndGetRank(
    kv: any,
    leaderboardKey: string,
    userId: number,
    rating: number,
    logger: any
  ): Promise<number | null> {
    if (!kv) return null;

    try {
      await updateLeaderboard(kv, leaderboardKey, userId, rating);
      return await getPlayerRank(kv, leaderboardKey, userId);
    } catch (error: any) {
      logger.error(error, 'Failed to update leaderboard or get player rank');
      return null;
    }
  }

  // “Your scores” history
  app.get<{
    Params: { playerId: string; songKey: string };
  }>('/:playerId/:songKey', async (req, reply) => {
    const { playerId, songKey } = (req.params || {}) as {
      playerId: string;
      songKey: string;
    };

    try {
      const rows = await prisma.score.findMany({
        where: { player_id: BigInt(playerId), hash: songKey },
        orderBy: { created_at: 'desc' },
      });
      const safe = rows.map((r: any) => ({
        ...r,
        player_id: r.player_id != null ? String(r.player_id) : null,
      }));
      return reply.success({ scores: safe });
    } catch (err: any) {
      (req as any).log.error(err);
      return reply.error(err.message, 500);
    }
  });
};

export default scoresRoutes;
