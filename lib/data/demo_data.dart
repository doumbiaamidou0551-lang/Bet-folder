import 'models.dart';

/// DONNÉES DE DÉMONSTRATION : équipes, scores, cotes et probabilités sont
/// fictifs. Ils servent uniquement à valider l'interface.
class DemoData {
  static const bool isDemo = true;
  static const String updatedAtLabel =
      'Données de démonstration · mise à jour fictive : 20 nov., 09:00';

  static const MatchAnalysis nerisVallon = MatchAnalysis(
    suggestions: [ScoreSuggestion('1-1', 11), ScoreSuggestion('2-1', 9)],
    alternative: ScoreSuggestion('1-0', 8),
    markets: [
      MarketEntry(
        name: 'Plus de 2,5 buts',
        estimatedPct: 58,
        odds: 1.85,
        confidence: Confidence.moyenne,
        risk: RiskLevel.modere,
      ),
      MarketEntry(
        name: 'Les deux équipes marquent',
        estimatedPct: 55,
        odds: 1.80,
        confidence: Confidence.moyenne,
        risk: RiskLevel.modere,
      ),
      MarketEntry(
        name: 'Victoire Néris FC',
        estimatedPct: 46,
        odds: 2.10,
        confidence: Confidence.moyenne,
        risk: RiskLevel.risque,
      ),
    ],
    limits:
        'compositions non confirmées ; échantillon de 18 matchs par équipe (données démo).',
    lineup: LineupStatus.notConfirmed,
    versionLabel: 'Version 1 · 09:00',
    players: [
      PlayerStat(
        name: 'N. Auriol',
        team: 'Néris FC',
        role: 'ATT',
        goals: 9,
        assists: 3,
        shotsOnTarget: 2.1,
        fouls: 1.2,
        yellowCards: 2,
        goalsPerMatch: 0.52,
        scorerPct: 34,
      ),
      PlayerStat(
        name: 'L. Corvin',
        team: 'Néris FC',
        role: 'MIL',
        goals: 4,
        assists: 6,
        shotsOnTarget: 0.9,
        fouls: 2.0,
        yellowCards: 4,
        goalsPerMatch: 0.25,
        scorerPct: 18,
      ),
      PlayerStat(
        name: 'D. Sabre',
        team: 'Vallon SC',
        role: 'ATT',
        goals: 7,
        assists: 2,
        shotsOnTarget: 1.8,
        fouls: 1.4,
        yellowCards: 3,
        goalsPerMatch: 0.44,
        scorerPct: 29,
      ),
      PlayerStat(
        name: 'M. Tessier',
        team: 'Vallon SC',
        role: 'ATT',
        goals: 5,
        assists: 4,
        shotsOnTarget: 1.1,
        fouls: 0.8,
        yellowCards: 1,
        goalsPerMatch: 0.31,
        scorerPct: 21,
      ),
    ],
    teamStats: [
      TeamStatRow('Buts marqués', 1.8, 1.3),
      TeamStatRow('Tirs cadrés', 5.2, 4.1),
      TeamStatRow('Fautes', 12.4, 13.8),
      TeamStatRow('Cartons jaunes', 1.9, 2.4),
    ],
    teamStatsNote:
        'Moyennes par match sur les 10 derniers matchs ; Néris FC à domicile, Vallon SC à l’extérieur (données démo).',
    htProbs: Probabilities1X2(33, 47, 20),
    htft: [
      HtFtEntry(ht: 0, ft: 0, pct: 26, odds: 3.60),
      HtFtEntry(ht: 0, ft: 1, pct: 5, odds: 17.00),
      HtFtEntry(ht: 0, ft: 2, pct: 2, odds: 41.00),
      HtFtEntry(ht: 1, ft: 0, pct: 17, odds: 5.20),
      HtFtEntry(ht: 1, ft: 1, pct: 21, odds: 4.60),
      HtFtEntry(ht: 1, ft: 2, pct: 9, odds: 8.50),
      HtFtEntry(ht: 2, ft: 0, pct: 3, odds: 26.00),
      HtFtEntry(ht: 2, ft: 1, pct: 2, odds: 23.00),
      HtFtEntry(ht: 2, ft: 2, pct: 15, odds: 7.00),
    ],
  );

  static const List<DemoMatch> matches = [
    DemoMatch(
      id: 'm1',
      competition: 'Ligue Exemple',
      time: '20:45',
      dayOffset: 0,
      home: 'Néris FC',
      away: 'Vallon SC',
      probs: Probabilities1X2(46, 28, 26),
      confidence: Confidence.moyenne,
      analysis: nerisVallon,
    ),
    DemoMatch(
      id: 'm2',
      competition: 'Ligue Exemple',
      time: '18:30',
      dayOffset: 0,
      home: 'Brava United',
      away: 'Kéo City',
      probs: Probabilities1X2(52, 26, 22),
      confidence: Confidence.moyenne,
    ),
    DemoMatch(
      id: 'm3',
      competition: 'Ligue Exemple',
      time: '21:00',
      dayOffset: 0,
      home: 'Mora CF',
      away: 'Dunes AC',
    ),
    DemoMatch(
      id: 'm4',
      competition: 'Coupe Démo',
      time: '18:00',
      dayOffset: 0,
      home: 'Orée AC',
      away: 'Sablon FC',
      probs: Probabilities1X2(38, 30, 32),
      confidence: Confidence.faible,
    ),
    DemoMatch(
      id: 'm5',
      competition: 'Coupe Démo',
      time: '20:00',
      dayOffset: 0,
      home: 'Pic RC',
      away: 'Lagune SC',
      probs: Probabilities1X2(41, 29, 30),
      confidence: Confidence.moyenne,
    ),
    DemoMatch(
      id: 'm6',
      competition: 'Ligue Exemple',
      time: '19:00',
      dayOffset: 1,
      home: 'Rive FC',
      away: 'Cime AC',
      probs: Probabilities1X2(44, 27, 29),
      confidence: Confidence.moyenne,
    ),
  ];
}
