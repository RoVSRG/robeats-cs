import type { PrismaClient } from '#prisma';

export const SCORE_SELECT_FIELDS = {
  hash: true,
  score: true,
  accuracy: true,
  rating: true,
  grade: true,
  created_at: true,
  max_combo: true,
  marvelous: true,
  perfect: true,
  great: true,
  good: true,
  bad: true,
  miss: true,
  rate: true,
  mean: true,
} as const;

export async function getUserBestScores(prisma: PrismaClient, userId: number) {
  const rows = await prisma.score.findMany({
    where: { player: { user_id: BigInt(userId) } },
    orderBy: [{ hash: 'asc' }, { rating: 'desc' }, { score: 'desc' }],
    select: SCORE_SELECT_FIELDS,
  });

  const bestMap = new Map<string, any>();

  for (const r of rows) {
    if (!bestMap.has(r.hash)) bestMap.set(r.hash, r);
  }

  const best = Array.from(bestMap.values()).sort(
    (a, b) => b.rating - a.rating || b.score - a.score
  );

  return best;
}

export async function getBestScore(
  prisma: PrismaClient,
  hash: string,
  userId: number
) {
  const rec = await prisma.score.findFirst({
    where: { hash, player: { user_id: BigInt(userId) } },
    orderBy: [{ rating: 'desc' }, { score: 'desc' }],
    select: {
      ...SCORE_SELECT_FIELDS,
      player: { select: { user_id: true, name: true } },
    },
  });

  if (!rec) return null;

  return {
    user_id: rec.player?.user_id != null ? String(rec.player.user_id) : null,
    player_name: rec.player?.name,
    hash: rec.hash,
    score: rec.score,
    accuracy: rec.accuracy,
    rating: rec.rating,
    grade: rec.grade,
    created_at: rec.created_at,
    max_combo: rec.max_combo,
    marvelous: rec.marvelous,
    perfect: rec.perfect,
    great: rec.great,
    good: rec.good,
    bad: rec.bad,
    miss: rec.miss,
    rate: rec.rate,
    mean: rec.mean,
  };
}

export async function getLeaderboard(prisma: PrismaClient, hash: string) {
  const all = await prisma.score.findMany({
    where: { hash },
    orderBy: [{ player_id: 'asc' }, { rating: 'desc' }, { score: 'desc' }],
    select: {
      player_id: true,
      ...SCORE_SELECT_FIELDS,
      player: { select: { user_id: true, name: true } },
    },
  });

  const seen = new Set<bigint>();
  const bestPerPlayer: any[] = [];

  for (const r of all) {
    if (!r.player_id) continue;
    if (seen.has(r.player_id)) continue;
    seen.add(r.player_id);
    bestPerPlayer.push({
      user_id: r.player?.user_id != null ? String(r.player.user_id) : null,
      player_name: r.player?.name,
      hash: r.hash,
      score: r.score,
      accuracy: r.accuracy,
      rating: r.rating,
      grade: r.grade,
      created_at: r.created_at,
      max_combo: r.max_combo,
      marvelous: r.marvelous,
      perfect: r.perfect,
      great: r.great,
      good: r.good,
      bad: r.bad,
      miss: r.miss,
      rate: r.rate,
      mean: r.mean,
    });
  }

  bestPerPlayer.sort((a, b) => b.rating - a.rating || b.score - a.score);
  return bestPerPlayer;
}

export function formatPlayerProfile(player: any) {
  // Align with PlayerProfileSchema (userId, name, rating, accuracy, playCount, rank added later)
  return {
    userId: Number(player.user_id),
    name: player.name,
    rating: Number(player.rating ?? 0),
    accuracy: Number(player.accuracy ?? 0),
    playCount: Number(player.play_count ?? 0),
  };
}

export async function updateLeaderboard(
  kv: any,
  leaderboardKey: string,
  userId: number,
  rating: number
) {
  try {
    await kv.zAdd(leaderboardKey, [{ score: rating, value: String(userId) }]);
  } catch (e: any) {
    throw new Error(`Failed to update leaderboard: ${e.message}`);
  }
}

export async function getPlayerRank(
  kv: any,
  leaderboardKey: string,
  userId: number
): Promise<number | null> {
  try {
    const rankIdx = await kv.zRevRank(leaderboardKey, String(userId));
    return rankIdx !== null ? rankIdx + 1 : null;
  } catch (e: any) {
    throw new Error(`Failed to get player rank: ${e.message}`);
  }
}
