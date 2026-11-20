import 'package:bet_folder/app.dart';
import 'package:bet_folder/core/app_text.dart';
import 'package:bet_folder/data/demo_data.dart';
import 'package:bet_folder/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

  testWidgets('l’accueil affiche le nom et le marquage démo', (tester) async {
    await tester.pumpWidget(const BetFolderApp());
    expect(find.text('BET-FOLDER'), findsOneWidget);
    expect(find.text('DONNÉES DÉMO'), findsWidgets);
  });
}
