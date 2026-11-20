import '../domain/calibration.dart';

enum BetStatus { pending, won, lost }

class MarketRecord {
  const MarketRecord(this.label, this.n, this.wins);
  final String label;
  final int n;
  final int wins;

  double get successPct => n == 0 ? 0 : wins * 100 / n;
}

class HistoryEntry {
  const HistoryEntry({
    required this.date,
    required this.match,
    required this.market,
    required this.odds,
    required this.predictedPct,
    required this.status,
  });

  final String date;
  final String match;
  final String market;
  final double odds;
  final int predictedPct;
  final BetStatus status;
}

/// DONNÉES DE DÉMONSTRATION (historique fictif d'analyses figées).
class TrackerData {
  static const List<CalibrationBucket> buckets = [
    CalibrationBucket('50–60 %', 55, 12, 6),
    CalibrationBucket('60–70 %', 65, 15, 9),
    CalibrationBucket('70–80 %', 75, 14, 10),
    CalibrationBucket('80–90 %', 85, 7, 5),
  ];

  static const List<MarketRecord> markets = [
    MarketRecord('Over/Under', 19, 12),
    MarketRecord('Les deux marquent', 15, 9),
    MarketRecord('1X2', 14, 9),
  ];

  static const List<HistoryEntry> history = [
    HistoryEntry(
      date: '20 nov.',
      match: 'Néris FC – Vallon SC',
      market: 'Plus de 2,5 buts',
      odds: 1.85,
      predictedPct: 58,
      status: BetStatus.pending,
    ),
    HistoryEntry(
      date: '19 nov.',
      match: 'Brava United – Kéo City',
      market: 'Double chance 1X',
      odds: 1.35,
      predictedPct: 78,
      status: BetStatus.won,
    ),
    HistoryEntry(
      date: '19 nov.',
      match: 'Orée AC – Sablon FC',
      market: 'Victoire Orée AC',
      odds: 3.10,
      predictedPct: 38,
      status: BetStatus.lost,
    ),
    HistoryEntry(
      date: '18 nov.',
      match: 'Pic RC – Lagune SC',
      market: 'Les deux équipes marquent',
      odds: 1.80,
      predictedPct: 55,
      status: BetStatus.won,
    ),
  ];
}
