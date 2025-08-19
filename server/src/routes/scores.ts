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

// Score Submission Schema
const ScoreSubmissionSchema = Type.Object({
  user: Type.Object({
    userId: Type.Integer({ minimum: 1 }),
    name: Type.String({ minLength: 1 }),
  }),
  payload: Type.Object({
    hash: Type.String({ minLength: 1 }),
    rate: Type.Number({ minimum: 70, maximum: 200 }),
    score: Type.Integer({ minimum: 0 }),
    accuracy: Type.Number({ minimum: 0, maximum: 100 }),
    combo: Type.Integer({ minimum: 0 }),
    maxCombo: Type.Integer({ minimum: 0 }),
    marvelous: Type.Integer({ minimum: 0 }),
    perfect: Type.Integer({ minimum: 0 }),
    great: Type.Integer({ minimum: 0 }),
    good: Type.Integer({ minimum: 0 }),
    bad: Type.Integer({ minimum: 0 }),
    miss: Type.Integer({ minimum: 0 }),
    grade: Type.Union([Type.Literal('F'), Type.Literal('D'), Type.Literal('C'), Type.Literal('B'), Type.Literal('A'), Type.Literal('S'), Type.Literal('SS')]),
    rating: Type.Number({ minimum: 0 }),
    mean: Type.Number(),
  }),
});

// Leaderboard Query Schema
const LeaderboardQuerySchema = Type.Object({
  hash: Type.String({ minLength: 1 }),
  userId: Type.String({ pattern: '^\\d+$' }),
});

// User Best Scores Query Schema
const UserBestScoresQuerySchema = Type.Object({
  userId: Type.String({ pattern: '^\\d+$' }),
});

// Score Entry Schema (for leaderboard responses)
const ScoreEntrySchema = Type.Object({
  playerId: Type.String(),
  name: Type.String(),
  score: Type.Number(),
  accuracy: Type.Number(),
  grade: Type.String(),
  rating: Type.Number(),
  rank: Type.Number(),
});

// Player Profile Schema 
const PlayerProfileResponseSchema = Type.Object({
  userId: Type.Number(),
  name: Type.String(),
  rating: Type.Number(),
  accuracy: Type.Union([Type.Number(), Type.Null()]),
  playCount: Type.Union([Type.Number(), Type.Null()]),
  rank: Type.Union([Type.Number(), Type.Null()]),
});

// Response schemas
const SuccessResponseSchema = Type.Object({
  success: Type.Boolean(),
});

const ScoreSubmissionResponseSchema = Type.Object({
  success: Type.Boolean(),
  profile: PlayerProfileResponseSchema,
});

const LeaderboardResponseSchema = Type.Object({
  success: Type.Boolean(),
  best: Type.Union([ScoreEntrySchema, Type.Null()]),
  leaderboard: Type.Array(ScoreEntrySchema),
});

const UserBestScoresResponseSchema = Type.Object({
  success: Type.Boolean(),
  scores: Type.Array(ScoreEntrySchema),
});

const UserHistoryResponseSchema = Type.Object({
  success: Type.Boolean(),
  scores: Type.Array(Type.Object({
    player_id: Type.String(),
    hash: Type.String(),
    score: Type.Number(),
    accuracy: Type.Number(),
    combo: Type.Number(),
    max_combo: Type.Number(),
    marvelous: Type.Number(),
    perfect: Type.Number(),
    great: Type.Number(),
    good: Type.Number(),
    bad: Type.Number(),
    miss: Type.Number(),
    grade: Type.String(),
    rating: Type.Number(),
    rate: Type.Number(),
    mean: Type.Number(),
    created_at: Type.String(),
  })),
});

const ErrorResponseSchema = Type.Object({
  success: Type.Boolean(),
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
type ScoreEntry = Static<typeof ScoreEntrySchema>;
type PlayerProfileResponse = Static<typeof PlayerProfileResponseSchema>;
type UserHistoryParams = Static<typeof UserHistoryParamsSchema>;

const scoresRoutes: FastifyPluginAsync<
  { prisma: PrismaClient; kv: any } & { prefix?: string }
> = async (app, opts) => {
  const prisma = opts.prisma; // provided from app
  const kv = opts.kv || (app as any).valkey;

  const GLOBAL_LEADERBOARD_KEY = 'leaderboard:players:rating';

  app.get('/leaderboard', {
    schema: {
      tags: ['Scores'],
      summary: 'Get song leaderboard',
      description: 'Get leaderboard for a specific song with user\'s best score',
      querystring: LeaderboardQuerySchema,
      response: {
        200: LeaderboardResponseSchema,
        400: ErrorResponseSchema,
        500: ErrorResponseSchema,
      },
    },
  }, async (req, reply) => {
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
  });

  // User's best scores per song
  app.get('/user/best', {
    schema: {
      tags: ['Scores'],
      summary: 'Get user best scores',
      description: 'Get user\'s best scores across all songs',
      querystring: UserBestScoresQuerySchema,
      response: {
        200: UserBestScoresResponseSchema,
        400: ErrorResponseSchema,
        500: ErrorResponseSchema,
      },
    },
  }, async (req, reply) => {
    const { userId } = req.query as UserBestScoresQuery;
    const userIdNum = parseInt(userId);

    try {
      const result = await getUserBestScores(prisma, userIdNum);
      return reply.success({ scores: result });
    } catch (err: any) {
      (req as any).log.error(err);
      return reply.error(err.message, 500);
    }
  });

  // Submit score
  app.post('/', {
    schema: {
      tags: ['Scores'],
      summary: 'Submit score',
      description: 'Submit a score for a song and update player rating',
      body: ScoreSubmissionSchema,
      response: {
        200: ScoreSubmissionResponseSchema,
        400: ErrorResponseSchema,
        500: ErrorResponseSchema,
      },
    },
  }, async (req, reply) => {
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

  // "Your scores" history
  app.get('/:playerId/:songKey', {
    schema: {
      tags: ['Scores'],
      summary: 'Get user score history',
      description: 'Get user\'s score history for a specific song',
      params: UserHistoryParamsSchema,
      response: {
        200: UserHistoryResponseSchema,
        500: ErrorResponseSchema,
      },
    },
  }, async (req, reply) => {
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
  });
};

export default scoresRoutes;
