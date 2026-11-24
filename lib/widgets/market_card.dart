import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_text.dart';
import '../core/format.dart';
import '../data/models.dart';
import 'app_card.dart';
import 'tags.dart';

/// Fiche d'un marché : estimé, cote, probabilité implicite, écart,
/// confiance et risque.
class MarketCard extends StatelessWidget {
  const MarketCard({super.key, required this.entry, this.subtitle});

  final MarketEntry entry;
  final String? subtitle;

  Widget _kv(String key, String value) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$key ', style: AppText.muted),
          TextSpan(text: value, style: AppText.bold),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gap = entry.gapPts;
    final odds = entry.odds;
    final implied = entry.impliedPct;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(entry.name, style: AppText.bold)),
              TagChip(
                text: gap == null ? 'cote n.d.' : signedPts(gap),
                color: (gap ?? 0) > 0 ? AppColors.accent : AppColors.textMuted,
              ),
            ],
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(subtitle!, style: AppText.muted),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _kv('Estimé', '${entry.estimatedPct} %'),
              _kv('Cote', odds == null ? 'n.d.' : fmtOdds(odds)),
              _kv('Implicite', implied == null ? 'n.d.' : '$implied %'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${entry.confidence.label} · ${entry.risk.label}'
            '${gap != null && gap <= 0 ? ' · Pas d’avantage détecté' : ''}',
            style: AppText.muted,
          ),
        ],
      ),
    );
  }
}
