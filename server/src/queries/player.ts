import type { PrismaClient } from '#prisma';

export const PLAYER_SELECT_FIELDS = {
  user_id: true,
  name: true,
  rating: true,
  accuracy: true,
  play_count: true,
  created_at: true,
  xp: true,
} as const;

export async function getPlayerProfile(prisma: PrismaClient, userId: number) {
  return await prisma.player.findFirst({
    where: { user_id: BigInt(userId), allowed: true },
    select: PLAYER_SELECT_FIELDS,
  });
}

export async function upsertPlayer(
  prisma: PrismaClient,
  userId: number,
  name: string,
  incrementPlayCount = false
) {
  const updateData: any = { name };
  if (incrementPlayCount) {
    updateData.play_count = { increment: 1 };
  }

  return await prisma.player.upsert({
    where: { user_id: BigInt(userId) },
    create: { user_id: BigInt(userId), name },
    update: updateData,
    select: { id: true, ...PLAYER_SELECT_FIELDS },
  });
}

export async function updatePlayerRating(
  prisma: PrismaClient,
  playerId: bigint,
  rating: number,
  accuracy: number
) {
  return await prisma.player.update({
    where: { id: playerId },
    data: { rating, accuracy },
    select: PLAYER_SELECT_FIELDS,
  });
}
