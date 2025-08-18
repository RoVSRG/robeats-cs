import { z } from 'zod';

// Score Submission Schema
export const ScoreSubmissionSchema = z.object({
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
});

// Leaderboard Query Schema
export const LeaderboardQuerySchema = z.object({
  hash: z.string().min(1),
  userId: z.string().transform((val) => parseInt(val)),
});

// User Best Scores Query Schema
export const UserBestScoresQuerySchema = z.object({
  userId: z.string().transform((val) => parseInt(val)),
});

// Score Entry Schema (for leaderboard responses)
export const ScoreEntrySchema = z.object({
  playerId: z.string(),
  name: z.string(),
  score: z.number(),
  accuracy: z.number(),
  grade: z.string(),
  rating: z.number(),
  rank: z.number(),
});

// Player Profile Schema (reused from player-contracts, but defined here to avoid circular imports)
export const PlayerProfileResponseSchema = z.object({
  userId: z.number(),
  name: z.string(),
  rating: z.number(),
  accuracy: z.number().nullable(),
  playCount: z.number().nullable(),
  rank: z.number().nullable(),
});

// Contract definitions for SDK generation
export const ScoreContracts = {
  submit: {
    name: 'submit',
    endpoint: '/scores',
    method: 'POST' as const,
    requestSchema: ScoreSubmissionSchema,
    responseSchema: z.object({
      success: z.boolean(),
      profile: PlayerProfileResponseSchema,
    }),
    description: 'Submit a score for a song',
  },
  getLeaderboard: {
    name: 'getLeaderboard',
    endpoint: '/scores/leaderboard',
    method: 'GET' as const,
    querySchema: LeaderboardQuerySchema,
    responseSchema: z.object({
      success: z.boolean(),
      best: ScoreEntrySchema.nullable(),
      leaderboard: z.array(ScoreEntrySchema),
    }),
    description: 'Get leaderboard for a specific song',
  },
  getUserBest: {
    name: 'getUserBest',
    endpoint: '/scores/user/best',
    method: 'GET' as const,
    querySchema: UserBestScoresQuerySchema,
    responseSchema: z.object({
      success: z.boolean(),
      scores: z.array(ScoreEntrySchema),
    }),
    description: 'Get user\'s best scores across all songs',
  },
  getUserHistory: {
    name: 'getUserHistory',
    endpoint: '/scores/{playerId}/{songKey}',
    method: 'GET' as const,
    pathParams: z.object({
      playerId: z.string(),
      songKey: z.string(),
    }),
    responseSchema: z.object({
      success: z.boolean(),
      scores: z.array(z.object({
        player_id: z.string(),
        hash: z.string(),
        score: z.number(),
        accuracy: z.number(),
        combo: z.number(),
        max_combo: z.number(),
        marvelous: z.number(),
        perfect: z.number(),
        great: z.number(),
        good: z.number(),
        bad: z.number(),
        miss: z.number(),
        grade: z.string(),
        rating: z.number(),
        rate: z.number(),
        mean: z.number(),
        created_at: z.string(),
      })),
    }),
    description: 'Get user\'s score history for a specific song',
  },
};

export type ScoreSubmissionRequest = z.infer<typeof ScoreSubmissionSchema>;
export type LeaderboardQuery = z.infer<typeof LeaderboardQuerySchema>;
export type UserBestScoresQuery = z.infer<typeof UserBestScoresQuerySchema>;
export type ScoreEntry = z.infer<typeof ScoreEntrySchema>;
export type PlayerProfileResponse = z.infer<typeof PlayerProfileResponseSchema>;