export function calculateOverallRating(ratings: number[]): number {
  let rating = 0;
  const maxNumOfScores = Math.min(ratings.length, 25);

  for (let i = 0; i < maxNumOfScores; i++) {
    const item = ratings[i] ?? 0;

    if (i + 1 <= 10) {
      rating += item * 1.5;
    } else {
      rating += item;
    }
  }

  return Math.round((100 * rating) / 30) / 100;
}
