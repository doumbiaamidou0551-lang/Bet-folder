import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_text.dart';
import '../../core/format.dart';
import '../../data/tracker_data.dart';
import '../../domain/calibration.dart';
import '../../widgets/app_card.dart';
import '../../widgets/tags.dart';

class PerformanceView extends StatelessWidget {
  const PerformanceView({super.key});

  @override
  Widget build(BuildContext context) {
    const buckets = TrackerData.buckets;
    final gap = overestimationPts(buckets);
    final overestimates = gap >= 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Performance des analyses'),
        Row(
          children: [
            Expanded(child: _Kpi(label: 'Sélections', value: '${totalSelections(buckets)}')),
            const SizedBox(width: 8),
            Expanded(child: _Kpi(label: 'Réussite', value: fmtPct(observedPct(buckets)))),
            const SizedBox(width: 8),
            Expanded(child: _Kpi(label: 'Annoncé moyen', value: fmtPct(predictedPct(buckets)))),
          ],
        ),
        const SectionTitle('Prévu contre observé'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final b in buckets) _BucketRow(bucket: b),
              const SizedBox(height: 4),
              Text(
                overestimates
                    ? 'Le modèle surestime d’environ ${gap.round()} points : '
                        'à corriger avant d’y faire confiance.'
                    : 'Écart moyen faible (${fmtDec(gap)} point) : calibration '
                        'correcte sur cet échantillon.',
                style: TextStyle(
                  color: overestimates ? AppColors.warning : AppColors.accent,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('Réussite par marché'),
        AppCard(
          child: Column(
            children: [
              for (final m in TrackerData.markets)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(m.label),
                      Text('${fmtPct(m.successPct)} · n=${m.n}', style: AppText.muted),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Historique de démonstration. Les analyses sont figées avant le '
          'match et ne sont jamais modifiées après.',
          style: AppText.small,
        ),
      ],
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          Text(label, style: AppText.muted),
        ],
      ),
    );
  }
}

class _BucketRow extends StatelessWidget {
  const _BucketRow({required this.bucket});

  final CalibrationBucket bucket;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(bucket.label, style: AppText.muted),
              Text(
                'prévu ${bucket.predictedPct} % · observé '
                '${bucket.observedPct.round()} % · n=${bucket.n}',
                style: AppText.muted,
              ),
            ],
          ),
          const SizedBox(height: 4),
          _Bar(pct: bucket.predictedPct.toDouble(), color: AppColors.neutralBar),
          const SizedBox(height: 3),
          _Bar(pct: bucket.observedPct, color: AppColors.accent),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.pct, required this.color});

  final double pct;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final double factor = (pct / 100).clamp(0.0, 1.0).toDouble();
    return SizedBox(
      height: 6,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: AppColors.border),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: factor,
              child: ColoredBox(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
