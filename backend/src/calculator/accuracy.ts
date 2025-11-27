export function calculateAverageAccuracy(accuracies: number[]) {
  const total = accuracies.reduce((acc, val) => acc + val, 0);
  return total / accuracies.length;
}
