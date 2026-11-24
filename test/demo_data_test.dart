import 'package:bet_folder/app.dart';
import 'package:bet_folder/core/app_data.dart';
import 'package:bet_folder/core/app_text.dart';
import 'package:bet_folder/data/demo_data.dart';
import 'package:bet_folder/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => AppData.autoLoad = false);

  test('les probabilités 1X2 de démonstration totalisent 100 %', () {
    for (final m in DemoData.matches) {
      final p = m.probs;
      if (p != null) {
        expect(p.total, 100, reason: m.title);
      }
    }
  });

  test('probabilité implicite et écart sont cohérents (58 % à la cote 1,85)', () {
    final market = DemoData.nerisVallon.markets.first;
    expect(market.impliedPct, 54);
    expect(market.gapPts, 4);
  });

  test('deux scores suggérés et une alternative, probabilités décroissantes', () {
    final a = DemoData.nerisVallon;
    expect(a.suggestions.length, 2);
    expect(a.suggestions.first.pct >= a.suggestions.last.pct, true);
    expect(a.suggestions.last.pct >= a.alternative.pct, true);
  });

  test('les données sont marquées comme démonstration et la mention existe', () {
    expect(DemoData.isDemo, true);
    expect(AppTexts.disclaimer.contains('ne constituent pas une garantie'), true);
  });

  test('compositions non confirmées : buteurs provisoires, pourcentages valides', () {
    final a = DemoData.nerisVallon;
    expect(a.lineup, LineupStatus.notConfirmed);
    for (final p in a.players) {
      final pct = p.scorerPct;
      if (pct != null) {
        expect(pct > 0 && pct < 100, true, reason: p.name);
      }
    }
    expect(a.teamStats.length, 4);
  });

  test('mi-temps / fin de match : 9 combinaisons cohérentes avec le 1X2', () {
    final a = DemoData.nerisVallon;
    final m = DemoData.matches.first;
    final probs = m.probs!;
    int ftSum(int ft) =>
        a.htft.where((e) => e.ft == ft).fold<int>(0, (s, e) => s + e.pct);
    int htSum(int ht) =>
        a.htft.where((e) => e.ht == ht).fold<int>(0, (s, e) => s + e.pct);
    expect(a.htft.length, 9);
    expect(a.htft.fold<int>(0, (s, e) => s + e.pct), 100);
    expect(ftSum(0), probs.home);
    expect(ftSum(1), probs.draw);
    expect(ftSum(2), probs.away);
    expect(htSum(0), a.htProbs.home);
    expect(htSum(1), a.htProbs.draw);
    expect(htSum(2), a.htProbs.away);
    expect(a.htProbs.total, 100);
  });

  testWidgets('l’écran de démarrage puis l’accueil affichent le marquage démo', (tester) async {
    await tester.pumpWidget(const BetFolderApp());
    expect(find.text('BET-FOLDER'), findsOneWidget);
    expect(find.text('Analyse · Probabilités · Discipline'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('BET-FOLDER'), findsOneWidget);
    expect(find.text('DONNÉES DÉMO'), findsWidgets);
  });
}
