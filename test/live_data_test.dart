import 'package:bet_folder/core/app_data.dart';
import 'package:bet_folder/data/live_data.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixture_latest.dart';

void main() {
  test('lecture du fichier de données réelles', () {
    final now = DateTime.parse('2026-11-22T22:36:55Z').toLocal();
    final snapshot = parseSnapshot(sampleLatestJson, now);
    expect(snapshot.excludedCount, 0);
    expect(snapshot.matches.length, 1);
    final m = snapshot.matches.first;
    expect(m.isDemo, false);
    expect(m.hasAnalysis, true);
    expect(m.dayOffset >= 0 && m.dayOffset <= 2, true); // lendemain, selon le fuseau
    expect(m.probs!.total, 100);
    final a = m.analysis!;
    expect(a.suggestions.length, 2);
    expect(a.htft.length, 9);
    expect(a.htft.fold<int>(0, (s, e) => s + e.pct), 100);
    expect(a.htProbs.total, 100);
    expect(a.players, isEmpty);
    expect(a.teamStats, isNotEmpty);
    // 1X2 (Victoire domicile) : cote réelle du fichier et écart calculé.
    expect(a.markets.first.name.startsWith('Victoire'), true);
    expect(a.markets.first.odds, 1.45);
    expect(a.markets.first.gapPts, isNotNull);
    expect(a.htft.any((e) => e.odds != null), true);
    expect(a.limits.contains('Pinnacle'), true);
  });

  test('un fichier invalide lève une exception (retour aux données connues)', () {
    expect(() => parseSnapshot('{"pas": "bon"}', DateTime.now()), throwsA(anything));
  });

  test('les données de démonstration restent par défaut avant tout chargement', () {
    expect(AppData.state.value.isLive, false);
  });
}
