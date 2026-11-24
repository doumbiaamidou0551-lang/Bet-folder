import 'dart:convert';

import '../core/format.dart';
import 'models.dart';

/// Contenu de data/latest.json, converti dans les modèles de l'application.
class LiveSnapshot {
  const LiveSnapshot({
    required this.generatedAt,
    required this.matches,
    required this.excludedCount,
  });

  final DateTime generatedAt;
  final List<DemoMatch> matches;
  final int excludedCount;
}

int _int(Object? value) => (value as num).toInt();

double? _double(Object? value) => value == null ? null : (value as num).toDouble();

Confidence _confidence(Object? value) {
  switch (value) {
    case 'elevee':
      return Confidence.elevee;
    case 'moyenne':
      return Confidence.moyenne;
    default:
      return Confidence.faible;
  }
}

RiskLevel _riskFor(int pct) =>
    pct >= 70 ? RiskLevel.prudent : (pct >= 45 ? RiskLevel.modere : RiskLevel.risque);

/// Lit le texte JSON du fichier de données. Lève une exception si le format
/// n'est pas celui attendu (l'appelant retombe alors sur les données connues).
LiveSnapshot parseSnapshot(String source, DateTime now) {
  final root = jsonDecode(source) as Map<String, dynamic>;
  final generatedAt = DateTime.parse(root['generated_at'] as String).toLocal();
  final sports = root['sports'] as Map<String, dynamic>;
  final football = sports['football'] as Map<String, dynamic>;
  final rawMatches = (football['matches'] as List<dynamic>?) ?? <dynamic>[];
  final excluded = (football['excluded'] as List<dynamic>?) ?? <dynamic>[];

  final matches = <DemoMatch>[
    for (final item in rawMatches)
      _parseMatch(item as Map<String, dynamic>, generatedAt, now),
  ];
  matches.sort((a, b) => a.kickoff!.compareTo(b.kickoff!));
  return LiveSnapshot(
    generatedAt: generatedAt,
    matches: matches,
    excludedCount: excluded.length,
  );
}

DemoMatch _parseMatch(
  Map<String, dynamic> j,
  DateTime generatedAt,
  DateTime now,
) {
  final kickoff = DateTime.parse(j['kickoff_utc'] as String).toLocal();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(kickoff.year, kickoff.month, kickoff.day);
  final dayOffset = day.difference(today).inDays;
  final time = (dayOffset >= 2 || dayOffset < 0)
      ? '${kickoff.day}/${kickoff.month} ${fmtClock(kickoff)}'
      : fmtClock(kickoff);

  final home = j['home'] as String;
  final away = j['away'] as String;
  final p = j['probs'] as Map<String, dynamic>;
  final model = j['model'] as Map<String, dynamic>;
  final confidence = _confidence(model['confidence']);
  final sample = model['sample_matches'] as Map<String, dynamic>;

  final markets = <MarketEntry>[
    for (final raw in j['markets'] as List<dynamic>)
      MarketEntry(
        name: (raw as Map<String, dynamic>)['label'] as String,
        estimatedPct: _int(raw['pct']),
        odds: _double(raw['odds']),
        confidence: confidence,
        risk: _riskFor(_int(raw['pct'])),
      ),
  ];

  final scores = j['scores'] as Map<String, dynamic>;
  final suggestions = <ScoreSuggestion>[
    for (final raw in scores['suggestions'] as List<dynamic>)
      ScoreSuggestion(
        (raw as Map<String, dynamic>)['score'] as String,
        _int(raw['pct']),
      ),
  ];
  final alt = scores['alternative'] as Map<String, dynamic>;

  final ht = j['htft'] as Map<String, dynamic>;
  final htProbs = ht['ht'] as Map<String, dynamic>;
  final combos = <HtFtEntry>[
    for (final raw in ht['combos'] as List<dynamic>)
      HtFtEntry(
        ht: _int((raw as Map<String, dynamic>)['ht']),
        ft: _int(raw['ft']),
        pct: _int(raw['pct']),
        odds: _double(raw['odds']),
      ),
  ];

  final form = j['form'] as Map<String, dynamic>;
  final homeForm = form['home_team'] as Map<String, dynamic>;
  final awayForm = form['away_team'] as Map<String, dynamic>;
  final homeAtHome = form['home_team_at_home'] as Map<String, dynamic>;
  final awayAway = form['away_team_away'] as Map<String, dynamic>;
  final rows = <TeamStatRow>[];
  void addRow(String label, Object? h, Object? a) {
    final hv = _double(h);
    final av = _double(a);
    if (hv != null && av != null) rows.add(TeamStatRow(label, hv, av));
  }

  addRow('Buts marqués (5 derniers)', homeForm['goals_for'], awayForm['goals_for']);
  addRow('Buts encaissés (5 derniers)', homeForm['goals_against'], awayForm['goals_against']);
  addRow('Buts marqués (dom. / ext.)', homeAtHome['goals_for'], awayAway['goals_for']);
  addRow('Buts encaissés (dom. / ext.)', homeAtHome['goals_against'], awayAway['goals_against']);
  final homeLetters = (homeForm['last'] as String?) ?? '';
  final awayLetters = (awayForm['last'] as String?) ?? '';

  final oddsInfo = j['odds'] as Map<String, dynamic>?;
  final bookmaker = oddsInfo?['bookmaker'] as String?;
  final oddsUpdated = DateTime.tryParse((oddsInfo?['updated_at'] as String?) ?? '')?.toLocal();
  final bookText = bookmaker ?? 'bookmaker inconnu';
  final updatedText =
      oddsUpdated == null ? '' : ' relevées le ${fmtDateTime(oddsUpdated)}';
  final oddsText =
      oddsInfo == null ? 'pas de cotes pour ce match' : 'cotes $bookText$updatedText';

  final analysis = MatchAnalysis(
    suggestions: suggestions,
    alternative: ScoreSuggestion(alt['score'] as String, _int(alt['pct'])),
    markets: markets,
    limits: 'compositions non confirmées ; $oddsText ; '
        'échantillon : ${sample['home']} et ${sample['away']} matchs.',
    lineup: LineupStatus.notConfirmed,
    versionLabel: 'Calcul du ${fmtDateTime(generatedAt)}',
    players: const <PlayerStat>[],
    teamStats: rows,
    teamStatsNote: 'Moyennes par match. Forme sur 5 matchs (V = victoire, '
        'N = nul, D = défaite) : $home $homeLetters · $away $awayLetters. '
        'Fautes, tirs cadrés et cartons : non disponibles avec la source gratuite.',
    htProbs: Probabilities1X2(
      _int(htProbs['home']),
      _int(htProbs['draw']),
      _int(htProbs['away']),
    ),
    htft: combos,
  );

  return DemoMatch(
    id: j['id'] as String,
    competition: j['competition'] as String,
    time: time,
    dayOffset: dayOffset,
    home: home,
    away: away,
    probs: Probabilities1X2(_int(p['home']), _int(p['draw']), _int(p['away'])),
    confidence: confidence,
    analysis: analysis,
    isDemo: false,
    kickoff: kickoff,
  );
}
