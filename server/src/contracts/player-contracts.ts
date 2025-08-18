import { z } from 'zod';

// Player Join Schema
export const PlayerJoinSchema = z.object({
  userId: z.number().int().positive(),
  name: z.string().min(1),
});

// Player Profile Query Schema
export const PlayerProfileQuerySchema = z.object({
  userId: z.string().regex(/^\d+$/),
});

// Player Profile Response Schema (for reference)
export const PlayerProfileSchema = z.object({
  userId: z.number(),
  name: z.string(),
  rating: z.number(),
  accuracy: z.number().nullable(),
  playCount: z.number().nullable(),
  rank: z.number().nullable(),
});

// Player Top Response Schema
export const PlayerTopResponseSchema = z.object({
  players: z.array(PlayerProfileSchema),
});

// Contract definitions for SDK generation
export const PlayerContracts = {
  join: {
    name: 'join',
    endpoint: '/players/join',
    method: 'POST' as const,
    requestSchema: PlayerJoinSchema,
    responseSchema: z.object({ success: z.boolean() }),
    description: 'Join player to the system',
  },
  getProfile: {
    name: 'getProfile',
    endpoint: '/players',
    method: 'GET' as const,
    querySchema: PlayerProfileQuerySchema,
    responseSchema: z.object({
      success: z.boolean(),
      profile: PlayerProfileSchema,
    }),
    description: 'Get player profile by userId',
  },
  getTop: {
    name: 'getTop',
    endpoint: '/players/top',
    method: 'GET' as const,
    responseSchema: z.object({
      success: z.boolean(),
      players: z.array(PlayerProfileSchema),
    }),
    description: 'Get top players by rating',
  },
};

export type PlayerJoinRequest = z.infer<typeof PlayerJoinSchema>;
export type PlayerProfileQuery = z.infer<typeof PlayerProfileQuerySchema>;
export type PlayerProfile = z.infer<typeof PlayerProfileSchema>;
export type PlayerTopResponse = z.infer<typeof PlayerTopResponseSchema>;