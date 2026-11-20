class CalibrationBucket {
  const CalibrationBucket(this.label, this.predictedPct, this.n, this.wins);

  final String label;
  final int predictedPct;
  final int n;
  final int wins;

  double get observedPct => n == 0 ? 0 : wins * 100 / n;
}

int totalSelections(List<CalibrationBucket> buckets) =>
    buckets.fold(0, (sum, b) => sum + b.n);

int totalWins(List<CalibrationBucket> buckets) =>
    buckets.fold(0, (sum, b) => sum + b.wins);

double observedPct(List<CalibrationBucket> buckets) {
  final n = totalSelections(buckets);
  return n == 0 ? 0 : totalWins(buckets) * 100 / n;
}

double predictedPct(List<CalibrationBucket> buckets) {
  final n = totalSelections(buckets);
  if (n == 0) return 0;
  final weighted = buckets.fold<double>(0, (sum, b) => sum + b.predictedPct * b.n);
  return weighted / n;
}

/// Écart moyen en points : positif = le modèle annonce plus que la réalité.
double overestimationPts(List<CalibrationBucket> buckets) =>
    predictedPct(buckets) - observedPct(buckets);
