import type { FastifyPluginAsync } from 'fastify';
import { Type } from '@sinclair/typebox';
import type { Static } from '@sinclair/typebox';

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

const ErrorResponseSchema = Type.Object({
  error: Type.String(),
});

const UnauthorizedResponseSchema = Type.Object({
  error: Type.String(),
});

// Path parameters schema
const UserHistoryParamsSchema = Type.Object({
  playerId: Type.String(),
  songKey: Type.String(),
});

// Type definitions
type ScoreSubmissionRequest = Static<typeof ScoreSubmissionSchema>;
type LeaderboardQuery = Static<typeof LeaderboardQuerySchema>;
type UserBestScoresQuery = Static<typeof UserBestScoresQuerySchema>;
type ScoreEntry = Static<typeof LeaderboardEntrySchema>;
type PlayerProfileResponse = Static<typeof PlayerSchema>;
type UserHistoryParams = Static<typeof UserHistoryParamsSchema>;

const scoresRoutes: FastifyPluginAsync<
  { prisma: PrismaClient; kv: any } & { prefix?: string }
> = async (app, opts) => {
  const prisma = opts.prisma; // provided from app
  const kv = opts.kv || (app as any).valkey;

  const GLOBAL_LEADERBOARD_KEY = 'leaderboard:players:rating';

  app.get(
    '/leaderboard',
    {
      schema: {
        tags: ['Scores'],
        summary: 'Get song leaderboard',
        description:
          "Get leaderboard for a specific song with user's best score",
        querystring: LeaderboardQuerySchema,
        response: {
          200: LeaderboardResponseSchema,
          400: ErrorResponseSchema,
          401: UnauthorizedResponseSchema,
          500: ErrorResponseSchema,
        },
      },
    },
    async (req, reply) => {
      const { hash, userId } = req.query as LeaderboardQuery;
      const userIdNum = parseInt(userId);

      try {
        const [leaderboard, best] = await Promise.all([
          getLeaderboard(prisma, hash),
          getBestScore(prisma, hash, userIdNum),
        ]);

        return reply.success({ best, leaderboard });
      } catch (err: any) {
        (req as any).log.error(err);
        return reply.error(err.message, 500);
      }
    }
  );

  // User's best scores per song
  app.get(
    '/user/best',
    {
      schema: {
        tags: ['Scores'],
        summary: 'Get user best scores',
        description: "Get user's best scores across all songs",
        querystring: UserBestScoresQuerySchema,
        response: {
          200: UserBestScoresResponseSchema,
          400: ErrorResponseSchema,
          401: UnauthorizedResponseSchema,
          500: ErrorResponseSchema,
        },
      },
    },
    async (req, reply) => {
      const { userId } = req.query as UserBestScoresQuery;
      const userIdNum = parseInt(userId);

      try {
        const result = await getUserBestScores(prisma, userIdNum);

        console.log(result);

        return reply.success({ scores: result });
      } catch (err: any) {
        (req as any).log.error(err);
        return reply.error(err.message, 500);
      }
    }
  );

  // Submit score
  app.post(
    '/',
    {
      schema: {
        tags: ['Scores'],
        summary: 'Submit score',
        description: 'Submit a score for a song and update player rating',
        body: ScoreSubmissionSchema,
        response: {
          200: ScoreSubmissionResponseSchema,
          400: ErrorResponseSchema,
          401: UnauthorizedResponseSchema,
          500: ErrorResponseSchema,
        },
      },
    },
    async (req, reply) => {
      const { user, payload } = req.body as ScoreSubmissionRequest;

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
    }
  );

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

  // "Your scores" history
  app.get(
    '/:playerId/:songKey',
    {
      schema: {
        tags: ['Scores'],
        summary: 'Get user score history',
        description: "Get user's score history for a specific song",
        params: UserHistoryParamsSchema,
        response: {
          200: UserHistoryResponseSchema,
          401: UnauthorizedResponseSchema,
          500: ErrorResponseSchema,
        },
      },
    },
    async (req, reply) => {
      const { playerId, songKey } = req.params as UserHistoryParams;

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
    }
  );
};

export default scoresRoutes;
