import 'package:bet_folder/core/simulation_store.dart';
import 'package:bet_folder/data/picks.dart';
import 'package:bet_folder/data/tracker_data.dart';
import 'package:bet_folder/domain/bankroll.dart';
import 'package:bet_folder/domain/calibration.dart';
import 'package:bet_folder/domain/ticket_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ticket', () {
    test('cote totale et probabilité du ticket prudent (matchs différents)', () {
      final legs = TicketMode.prudent.legIds.map(PicksData.legById).toList();
      final s = summarizeTicket(legs);
      expect(s.totalOdds, closeTo(2.584, 0.001));
      expect(s.jointPct, closeTo(45.49, 0.01));
      expect(s.hasCorrelation, false);
    });

    test('deux sélections du même match : pas de probabilité affichée', () {
      final legs = [PicksData.legById('l1'), PicksData.legById('l2')];
      final s = summarizeTicket(legs);
      expect(s.hasCorrelation, true);
      expect(s.jointPct, isNull);
      expect(s.totalOdds, closeTo(1.32 * 1.85, 0.001));
    });

    test('ticket vide', () {
      expect(summarizeTicket(const []).totalOdds, 0);
    });

    test('les presets ne contiennent jamais deux sélections du même match', () {
      for (final mode in TicketMode.values) {
        final legs = mode.legIds.map(PicksData.legById).toList();
        expect(summarizeTicket(legs).hasCorrelation, false, reason: mode.label);
      }
    });
  });

  group('bankroll', () {
    final seed = SimulationStore.bets.value;

    test('statistiques de l’historique de démonstration', () {
      final s = computeBankroll(seed, initial: SimulationStore.initialBudget);
      expect(s.profit, -950);
      expect(s.settledCount, 8);
      expect(s.wins, 4);
      expect(s.balance, 49050);
      expect(s.roiPct, closeTo(-1.9, 0.001));
      expect(s.yieldPct, closeTo(-11.875, 0.001));
      expect(s.successPct, 50);
      expect(s.lossStreak, 0);
    });

    test('une mise en cours réduit le solde sans compter comme perte', () {
      final bets = [
        ...seed,
        const SimBet(id: 'x', label: 'x', stake: 500, odds: 2, daysAgo: 0),
      ];
      final s = computeBankroll(bets, initial: 50000);
      expect(s.profit, -950);
      expect(s.balance, 49050 - 500);
      expect(s.settledCount, 8);
    });

    test('la série de pertes est comptée à la fin', () {
      final bets = [
        const SimBet(id: 'a', label: 'a', stake: 100, odds: 2, daysAgo: 3, won: true),
        const SimBet(id: 'b', label: 'b', stake: 100, odds: 2, daysAgo: 2, won: false),
        const SimBet(id: 'c', label: 'c', stake: 100, odds: 2, daysAgo: 1, won: false),
        const SimBet(id: 'd', label: 'd', stake: 100, odds: 2, daysAgo: 0, won: false),
      ];
      expect(computeBankroll(bets, initial: 1000).lossStreak, 3);
    });

    test('limites journalière et hebdomadaire', () {
      expect(
        checkLimits(seed, 2000, dailyLimit: 2000, weeklyLimit: 8000),
        LimitCheck.ok,
      );
      expect(
        checkLimits(seed, 2500, dailyLimit: 2000, weeklyLimit: 8000),
        LimitCheck.dailyExceeded,
      );
      expect(
        checkLimits(seed, 1500, dailyLimit: 2000, weeklyLimit: 7000),
        LimitCheck.weeklyExceeded,
      );
    });
  });

  group('calibration', () {
    test('totaux et écart de la démonstration', () {
      expect(totalSelections(TrackerData.buckets), 48);
      expect(totalWins(TrackerData.buckets), 30);
      expect(observedPct(TrackerData.buckets), closeTo(62.5, 0.001));
      expect(predictedPct(TrackerData.buckets), closeTo(68.33, 0.01));
      expect(overestimationPts(TrackerData.buckets), closeTo(5.83, 0.01));
    });

    test('les marchés totalisent le même nombre de sélections', () {
      final n = TrackerData.markets.fold<int>(0, (s, m) => s + m.n);
      final w = TrackerData.markets.fold<int>(0, (s, m) => s + m.wins);
      expect(n, 48);
      expect(w, 30);
    });
  });
}
