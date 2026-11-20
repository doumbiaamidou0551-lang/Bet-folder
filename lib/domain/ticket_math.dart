enum TicketRisk {
  faible('Risque faible'),
  modere('Risque modéré'),
  eleve('Risque élevé');

  const TicketRisk(this.label);
  final String label;
}

class TicketLeg {
  const TicketLeg({
    required this.id,
    required this.matchId,
    required this.matchTitle,
    required this.market,
    required this.odds,
    required this.estimatedPct,
  });

  final String id;
  final String matchId;
  final String matchTitle;
  final String market;
  final double odds;
  final int estimatedPct;
}

class TicketSummary {
  const TicketSummary({
    required this.totalOdds,
    required this.jointPct,
    required this.hasCorrelation,
    required this.risk,
  });

  final double totalOdds;

  /// Probabilité approximative du ticket. `null` quand elle n'est pas
  /// calculable honnêtement (sélections corrélées d'un même match).
  final double? jointPct;
  final bool hasCorrelation;
  final TicketRisk? risk;

  /// Probabilité implicite de la cote totale (sans retrait de marge).
  double get impliedPct => totalOdds <= 0 ? 0 : 100 / totalOdds;
}

/// Cote totale = produit des cotes. Probabilité = produit des probabilités
/// estimées, UNIQUEMENT si chaque sélection vient d'un match différent
/// (hypothèse d'indépendance). Sinon : pas de probabilité affichée.
TicketSummary summarizeTicket(List<TicketLeg> legs) {
  if (legs.isEmpty) {
    return const TicketSummary(
      totalOdds: 0,
      jointPct: null,
      hasCorrelation: false,
      risk: null,
    );
  }
  var odds = 1.0;
  var prob = 1.0;
  var correlated = false;
  final matches = <String>{};
  for (final leg in legs) {
    odds *= leg.odds;
    prob *= leg.estimatedPct / 100;
    if (!matches.add(leg.matchId)) correlated = true;
  }
  if (correlated) {
    return TicketSummary(
      totalOdds: odds,
      jointPct: null,
      hasCorrelation: true,
      risk: null,
    );
  }
  final pct = prob * 100;
  final risk = pct >= 55
      ? TicketRisk.faible
      : (pct >= 30 ? TicketRisk.modere : TicketRisk.eleve);
  return TicketSummary(
    totalOdds: odds,
    jointPct: pct,
    hasCorrelation: false,
    risk: risk,
  );
}
