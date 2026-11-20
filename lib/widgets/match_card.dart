import 'package:flutter/material.dart';

import '../core/app_text.dart';
import '../data/models.dart';
import 'app_card.dart';
import 'probability_bar.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({super.key, required this.match, required this.onTap});

  final DemoMatch match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final probs = match.probs;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${match.competition} · ${match.time}', style: AppText.muted),
                Text(match.confidence?.label ?? '', style: AppText.muted),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(match.home, style: AppText.bold),
                Text(match.away, style: AppText.bold),
              ],
            ),
            const SizedBox(height: 10),
            if (probs != null) ProbabilityBar(probs: probs),
          ],
        ),
      ),
    );
  }
}
