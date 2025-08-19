import { Type } from '@sinclair/typebox';

export const PlayerJoinSchema = Type.Object({
  userId: Type.Integer({ minimum: 1 }),
  name: Type.String({ minLength: 1 }),
});

export const PlayerProfileQuerySchema = Type.Object({
  userId: Type.String({ pattern: '^\\d+$' }),
});

// Player Profile Response Schema
export const PlayerProfileSchema = Type.Object({
  userId: Type.Number(),
  name: Type.String(),
  rating: Type.Number(),
  accuracy: Type.Union([Type.Number(), Type.Null()]),
  playCount: Type.Union([Type.Number(), Type.Null()]),
  rank: Type.Union([Type.Number(), Type.Null()]),
});

export const PlayerProfileResponseSchema = Type.Object({
  success: Type.Boolean(),
  profile: PlayerProfileSchema,
});

export const PlayersTopResponseSchema = Type.Object({
  success: Type.Boolean(),
  players: Type.Array(PlayerProfileSchema),
});
