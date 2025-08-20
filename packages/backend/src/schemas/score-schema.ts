import { Type } from '@sinclair/typebox';

export const LeaderboardQuerySchema = Type.Object({
  hash: Type.String({ minLength: 1 }),
  userId: Type.String({ pattern: '^\\d+$' }),
});

// User Best Scores Query Schema
export const UserBestScoresQuerySchema = Type.Object({
  userId: Type.String({ pattern: '^\\d+$' }),
});

export const GradeEnum = Type.Union([
  Type.Literal('F'),
  Type.Literal('D'),
  Type.Literal('C'),
  Type.Literal('B'),
  Type.Literal('A'),
  Type.Literal('S'),
  Type.Literal('SS'),
]);

export const ScoreSchema = Type.Object({
  rating: Type.Number({ minimum: 0 }),
  score: Type.Number({ minimum: 0 }),
  accuracy: Type.Number({ minimum: 0, maximum: 100 }),
  grade: GradeEnum,
  max_combo: Type.Number({ minimum: 0 }),
  marvelous: Type.Number({ minimum: 0 }),
  perfect: Type.Number({ minimum: 0 }),
  great: Type.Number({ minimum: 0 }),
  good: Type.Number({ minimum: 0 }),
  bad: Type.Number({ minimum: 0 }),
  miss: Type.Number({ minimum: 0 }),
  rate: Type.Number({ minimum: 70, maximum: 200 }),
  created_at: Type.String({ format: 'date-time' }),
  mean: Type.Number(),
});

// Player Profile Schema
export const PlayerSchema = Type.Object({
  userId: Type.Number(),
  name: Type.String(),
  rating: Type.Number(),
  accuracy: Type.Union([Type.Number(), Type.Null()]),
  playCount: Type.Union([Type.Number(), Type.Null()]),
  rank: Type.Union([Type.Number(), Type.Null()]),
});

export const ScoreSubmissionResponseSchema = PlayerSchema;

// Leaderboard entry with player information
export const LeaderboardEntrySchema = Type.Object({
  score: Type.Number({ minimum: 0 }),
  accuracy: Type.Number({ minimum: 0, maximum: 100 }),
  grade: GradeEnum,
  max_combo: Type.Number({ minimum: 0 }),
  marvelous: Type.Number({ minimum: 0 }),
  perfect: Type.Number({ minimum: 0 }),
  great: Type.Number({ minimum: 0 }),
  good: Type.Number({ minimum: 0 }),
  bad: Type.Number({ minimum: 0 }),
  miss: Type.Number({ minimum: 0 }),
  rate: Type.Number({ minimum: 70, maximum: 200 }),
  created_at: Type.String({ format: 'date-time' }),
  mean: Type.Number(),
  player_id: Type.String(),
});

export const LeaderboardResponseSchema = Type.Object({
  best: Type.Union([LeaderboardEntrySchema, Type.Null()]),
  leaderboard: Type.Array(LeaderboardEntrySchema),
});

export const ScoreSubmissionSchema = Type.Object({
  user: Type.Object({
    userId: Type.Integer({ minimum: 1 }),
    name: Type.String({ minLength: 1 }),
  }),
  map: Type.Object({
    hash: Type.String({ minLength: 1 }),
  }),
  payload: ScoreSchema,
});

// Score with hash for user's best scores
export const ScoreWithHashSchema = Type.Object({
  rating: Type.Number({ minimum: 0 }),
  score: Type.Number({ minimum: 0 }),
  accuracy: Type.Number({ minimum: 0, maximum: 100 }),
  grade: GradeEnum,
  max_combo: Type.Number({ minimum: 0 }),
  marvelous: Type.Number({ minimum: 0 }),
  perfect: Type.Number({ minimum: 0 }),
  great: Type.Number({ minimum: 0 }),
  good: Type.Number({ minimum: 0 }),
  bad: Type.Number({ minimum: 0 }),
  miss: Type.Number({ minimum: 0 }),
  rate: Type.Number({ minimum: 70, maximum: 200 }),
  created_at: Type.String({ format: 'date-time' }),
  mean: Type.Number(),
  hash: Type.String(),
});

export const UserBestScoresResponseSchema = Type.Array(ScoreWithHashSchema);

// User history response (direct array of scores)
export const UserHistoryResponseSchema = Type.Object({
  scores: Type.Array(ScoreSchema),
});
