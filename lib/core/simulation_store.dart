import 'package:flutter/foundation.dart';

import '../domain/bankroll.dart';

/// Bankroll SIMULÉE gardée en mémoire (perdue à la fermeture de l'application ;
/// la sauvegarde durable viendra avec la base locale). Aucun argent réel.
class SimulationStore {
  static const int initialBudget = 50000;
  static const int dailyLimit = 2000;
  static const int weeklyLimit = 8000;

  static int _nextId = 100;

  static final ValueNotifier<List<SimBet>> bets =
      ValueNotifier<List<SimBet>>(_seed());

  /// Historique de démonstration, du plus ancien au plus récent.
  static List<SimBet> _seed() => const [
        SimBet(id: 's1', label: 'Démo · Plus de 1,5 buts', stake: 1000, odds: 1.45, daysAgo: 8, won: true),
        SimBet(id: 's2', label: 'Démo · Ticket équilibré', stake: 1000, odds: 2.10, daysAgo: 7, won: true),
        SimBet(id: 's3', label: 'Démo · Double chance', stake: 1000, odds: 1.80, daysAgo: 6, won: false),
        SimBet(id: 's4', label: 'Démo · Ticket cote élevée', stake: 1000, odds: 2.30, daysAgo: 5, won: false),
        SimBet(id: 's5', label: 'Démo · Moins de 3,5 buts', stake: 1000, odds: 1.60, daysAgo: 4, won: true),
        SimBet(id: 's6', label: 'Démo · Plus de 1,5 buts', stake: 1000, odds: 1.35, daysAgo: 3, won: false),
        SimBet(id: 's7', label: 'Démo · Victoire à domicile', stake: 1000, odds: 3.10, daysAgo: 2, won: false),
        SimBet(id: 's8', label: 'Démo · Ticket prudent', stake: 1000, odds: 1.90, daysAgo: 1, won: true),
      ];

  static LimitCheck add({
    required String label,
    required int stake,
    required double odds,
  }) {
    final current = bets.value;
    final check = checkLimits(
      current,
      stake,
      dailyLimit: dailyLimit,
      weeklyLimit: weeklyLimit,
    );
    if (check != LimitCheck.ok) return check;
    _nextId++;
    bets.value = [
      ...current,
      SimBet(id: 'b$_nextId', label: label, stake: stake, odds: odds, daysAgo: 0),
    ];
    return LimitCheck.ok;
  }

  static void settle(String id, bool won) {
    bets.value = [
      for (final b in bets.value) b.id == id ? b.settle(won) : b,
    ];
  }
}
