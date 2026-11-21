import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_text.dart';
import '../../data/models.dart';
import '../../widgets/app_card.dart';
import '../../widgets/market_card.dart';
import '../../widgets/probability_bar.dart';
import '../../widgets/tags.dart';

/// Onglet Mi-temps / Fin de match (HT/FT).
class HtFtTab extends StatelessWidget {
  const HtFtTab({super.key, required this.match, required this.analysis});

  final DemoMatch match;
  final MatchAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final entries = [...analysis.htft]..sort((a, b) => b.pct.compareTo(a.pct));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Résultat à la mi-temps'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProbabilityBar(probs: analysis.htProbs),
              const SizedBox(height: 8),
              const Text(
                'Probabilités estimées du résultat à la mi-temps.',
                style: AppText.small,
              ),
            ],
          ),
        ),
        const SectionTitle('Mi-temps / fin de match'),
        Text(
          'Format : résultat à la mi-temps / résultat final. '
          'Dom. = ${match.home}, Ext. = ${match.away}. '
          'Classé de la combinaison la plus probable à la moins probable.',
          style: AppText.small,
        ),
        const SizedBox(height: 8),
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: MarketCard(entry: e.toMarketEntry()),
          ),
        const AppCard(
          borderColor: AppColors.warning,
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            'Marché à marge élevée : les écarts positifs sont rares et '
            'fragiles. Le modèle par mi-temps sera développé à l’étape 4 ; '
            'ces chiffres sont des données de démonstration.',
            style: TextStyle(color: AppColors.warning, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
