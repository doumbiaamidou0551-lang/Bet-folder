import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_text.dart';
import '../../data/demo_data.dart';
import '../../data/models.dart';
import '../../widgets/app_card.dart';
import '../../widgets/market_card.dart';
import '../../widgets/match_card.dart';
import '../../widgets/tags.dart';
import '../match_analysis/match_analysis_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _open(BuildContext context, DemoMatch match) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MatchAnalysisScreen(match: match),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayMatches =
        DemoData.matches.where((m) => m.dayOffset == 0).toList();
    final todayAnalysed = todayMatches.where((m) => m.hasAnalysis).toList();
    final analysedCount = DemoData.matches.where((m) => m.hasAnalysis).length;
    final example = DemoData.nerisVallon.markets.first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'BET-FOLDER',
              style: TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            DemoBadge(),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Aujourd’hui',
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        const Text(DemoData.updatedAtLabel, style: AppText.muted),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                value: '$analysedCount',
                label: 'analyses disponibles',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatTile(
                value: '${todayMatches.length}',
                label: 'matchs aujourd’hui',
              ),
            ),
          ],
        ),
        const SectionTitle('Matchs du jour'),
        for (final m in todayAnalysed.take(2))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: MatchCard(match: m, onTap: () => _open(context, m)),
          ),
        const SectionTitle('Marché à étudier (exemple)'),
        MarketCard(entry: example, subtitle: DemoData.matches.first.title),
        const SizedBox(height: 16),
        const Text(AppTexts.disclaimer, style: AppText.small),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          Text(label, style: AppText.muted),
        ],
      ),
    );
  }
}
