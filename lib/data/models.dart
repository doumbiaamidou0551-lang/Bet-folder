enum Confidence {
  faible('Confiance faible'),
  moyenne('Confiance moyenne'),
  elevee('Confiance élevée');

  const Confidence(this.label);
  final String label;
}

enum RiskLevel {
  prudent('Risque faible'),
  modere('Risque modéré'),
  risque('Risque élevé');

  const RiskLevel(this.label);
  final String label;
}

class Probabilities1X2 {
  const Probabilities1X2(this.home, this.draw, this.away);
  final int home;
  final int draw;
  final int away;

  int get total => home + draw + away;
}

class ScoreSuggestion {
  const ScoreSuggestion(this.score, this.pct);
  final String score;
  final int pct;
}

class MarketEntry {
  const MarketEntry({
    required this.name,
    required this.estimatedPct,
    required this.odds,
    required this.confidence,
    required this.risk,
  });

  final String name;
  final int estimatedPct;

  /// Cote du bookmaker ; `null` quand aucune source de cotes n'est branchée.
  final double? odds;
  final Confidence confidence;
  final RiskLevel risk;

  /// Probabilité implicite brute (sans retrait de la marge du bookmaker).
  int? get impliedPct {
    final value = odds;
    return value == null ? null : (100 / value).round();
  }

  /// Écart entre la probabilité estimée et la probabilité implicite brute.
  int? get gapPts {
    final implied = impliedPct;
    return implied == null ? null : estimatedPct - implied;
  }
}

enum LineupStatus {
  notConfirmed('Compositions non confirmées'),
  probable('Compositions probables'),
  confirmed('Compositions confirmées');

  const LineupStatus(this.label);
  final String label;
}

class PlayerStat {
  const PlayerStat({
    required this.name,
    required this.team,
    required this.role,
    required this.goals,
    required this.assists,
    required this.shotsOnTarget,
    required this.fouls,
    required this.yellowCards,
    required this.goalsPerMatch,
    this.scorerPct,
  });

  final String name;
  final String team;
  final String role;
  final int goals;
  final int assists;
  final double shotsOnTarget; // tirs cadrés par match
  final double fouls; // fautes commises par match
  final int yellowCards;
  final double goalsPerMatch;

  /// Probabilité estimée de marquer (modèle). Provisoire tant que les
  /// compositions ne sont pas confirmées.
  final int? scorerPct;
}

class TeamStatRow {
  const TeamStatRow(this.label, this.home, this.away);
  final String label;
  final double home;
  final double away;
}

/// Une combinaison « résultat à la mi-temps / résultat final ».
class HtFtEntry {
  const HtFtEntry({
    required this.ht,
    required this.ft,
    required this.pct,
    required this.odds,
  });

  /// 0 = domicile, 1 = nul, 2 = extérieur.
  final int ht;
  final int ft;
  final int pct;
  final double? odds;

  static const List<String> _labels = ['Dom.', 'Nul', 'Ext.'];

  String get name => '${_labels[ht]} / ${_labels[ft]}';

  MarketEntry toMarketEntry() => MarketEntry(
        name: name,
        estimatedPct: pct,
        odds: odds,
        confidence: pct >= 10 ? Confidence.moyenne : Confidence.faible,
        risk: pct >= 20 ? RiskLevel.modere : RiskLevel.risque,
      );
}

class MatchAnalysis {
  const MatchAnalysis({
    required this.suggestions,
    required this.alternative,
    required this.markets,
    required this.limits,
    required this.lineup,
    required this.versionLabel,
    required this.players,
    required this.teamStats,
    required this.teamStatsNote,
    required this.htProbs,
    required this.htft,
  });

  /// Deux scores suggérés, mis en relief.
  final List<ScoreSuggestion> suggestions;

  /// Un score alternatif.
  final ScoreSuggestion alternative;
  final List<MarketEntry> markets;
  final String limits;
  final LineupStatus lineup;
  final String versionLabel;
  final List<PlayerStat> players;
  final List<TeamStatRow> teamStats;
  final String teamStatsNote;

  /// Résultat à la mi-temps (1X2 de la première période).
  final Probabilities1X2 htProbs;

  /// Les 9 combinaisons mi-temps / fin de match.
  final List<HtFtEntry> htft;
}

class DemoMatch {
  const DemoMatch({
    required this.id,
    required this.competition,
    required this.time,
    required this.dayOffset,
    required this.home,
    required this.away,
    this.probs,
    this.confidence,
    this.analysis,
    this.isDemo = true,
    this.kickoff,
  });

  final String id;
  final String competition;
  final String time;
  final int dayOffset; // 0 = aujourd'hui, 1 = demain
  final String home;
  final String away;
  final Probabilities1X2? probs;
  final Confidence? confidence;
  final MatchAnalysis? analysis;

  /// `false` pour les matchs issus des données réelles.
  final bool isDemo;

  /// Coup d'envoi (heure locale du téléphone), connu pour les données réelles.
  final DateTime? kickoff;

  bool get hasAnalysis => probs != null;
  String get title => '$home – $away';
}
