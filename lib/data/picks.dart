import '../domain/ticket_math.dart';
import 'models.dart';

enum PickProfile {
  prudent('Profil prudent', 'Prudent'),
  modere('Profil modéré', 'Modéré'),
  risque('Profil risqué', 'Risqué');

  const PickProfile(this.label, this.shortLabel);
  final String label;
  final String shortLabel;
}

class ScannerPick {
  const ScannerPick({
    required this.leg,
    required this.profile,
    required this.confidence,
    required this.why,
    required this.limits,
  });

  final TicketLeg leg;
  final PickProfile profile;
  final Confidence confidence;
  final String why;
  final String limits;

  int get impliedPct => (100 / leg.odds).round();
  int get gapPts => leg.estimatedPct - impliedPct;
}

/// DONNÉES DE DÉMONSTRATION (marchés repérés par le scanner).
class PicksData {
  static const int analysedCount = 17;
  static const int excludedCount = 5;

  static const List<ScannerPick> all = [
    ScannerPick(
      leg: TicketLeg(
        id: 'l1',
        matchId: 'm1',
        matchTitle: 'Néris FC – Vallon SC',
        market: 'Plus de 1,5 buts',
        odds: 1.32,
        estimatedPct: 81,
      ),
      profile: PickProfile.prudent,
      confidence: Confidence.moyenne,
      why: 'attaque de Néris à domicile (1,8 but/match), défense de Vallon à l’extérieur (1,6 encaissé/match).',
      limits: 'compositions non confirmées.',
    ),
    ScannerPick(
      leg: TicketLeg(
        id: 'l2',
        matchId: 'm1',
        matchTitle: 'Néris FC – Vallon SC',
        market: 'Plus de 2,5 buts',
        odds: 1.85,
        estimatedPct: 58,
      ),
      profile: PickProfile.modere,
      confidence: Confidence.moyenne,
      why: 'les deux équipes concèdent des occasions (4,1 et 5,2 tirs cadrés/match).',
      limits: 'écart modeste, sensible au changement de compositions.',
    ),
    ScannerPick(
      leg: TicketLeg(
        id: 'l3',
        matchId: 'm2',
        matchTitle: 'Brava United – Kéo City',
        market: 'Double chance 1X',
        odds: 1.35,
        estimatedPct: 78,
      ),
      profile: PickProfile.prudent,
      confidence: Confidence.moyenne,
      why: 'Brava United est favorite (52 %) et le nul pèse 26 %.',
      limits: 'cote proche de la probabilité implicite.',
    ),
    ScannerPick(
      leg: TicketLeg(
        id: 'l4',
        matchId: 'm4',
        matchTitle: 'Orée AC – Sablon FC',
        market: 'Moins de 3,5 buts',
        odds: 1.45,
        estimatedPct: 72,
      ),
      profile: PickProfile.prudent,
      confidence: Confidence.moyenne,
      why: 'les deux équipes marquent peu en moyenne (données démo).',
      limits: 'échantillon limité pour ce match.',
    ),
    ScannerPick(
      leg: TicketLeg(
        id: 'l5',
        matchId: 'm4',
        matchTitle: 'Orée AC – Sablon FC',
        market: 'Victoire Orée AC',
        odds: 3.10,
        estimatedPct: 38,
      ),
      profile: PickProfile.risque,
      confidence: Confidence.faible,
      why: '4 victoires sur 5 à domicile, mais face à des adversaires modestes.',
      limits: 'échantillon de 9 matchs : l’écart est probablement surestimé.',
    ),
  ];

  static TicketLeg legById(String id) =>
      all.firstWhere((p) => p.leg.id == id).leg;
}

enum TicketMode {
  prudent('Prudent', ['l1', 'l3', 'l4']),
  equilibre('Équilibré', ['l2', 'l3', 'l4']),
  haute('Cote élevée', ['l2', 'l3', 'l5']),
  perso('Perso', <String>[]);

  const TicketMode(this.label, this.legIds);
  final String label;
  final List<String> legIds;
}
