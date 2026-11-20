import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../data/models.dart';

/// Barre 1X2 : les pourcentages sont toujours écrits, la couleur ne porte
/// jamais seule l'information.
class ProbabilityBar extends StatelessWidget {
  const ProbabilityBar({super.key, required this.probs});

  final Probabilities1X2 probs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                Expanded(flex: probs.home, child: Container(color: AppColors.accent)),
                const SizedBox(width: 2),
                Expanded(flex: probs.draw, child: Container(color: AppColors.neutralBar)),
                const SizedBox(width: 2),
                Expanded(flex: probs.away, child: Container(color: AppColors.textMuted)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Dom. ${probs.home} %', style: AppText.muted),
            Text('Nul ${probs.draw} %', style: AppText.muted),
            Text('Ext. ${probs.away} %', style: AppText.muted),
          ],
        ),
      ],
    );
  }
}
