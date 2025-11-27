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
  accuracy: Type.Number(),
  playCount: Type.Number(),
  rank: Type.Number(),
});

export const PlayerProfileResponseSchema = PlayerProfileSchema;

export const PlayersTopResponseSchema = Type.Array(PlayerProfileSchema);
