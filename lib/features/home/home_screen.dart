import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_data.dart';
import '../../core/app_text.dart';
import '../../core/format.dart';
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
    return ValueListenableBuilder<AppDataState>(
      valueListenable: AppData.state,
      builder: (context, data, _) {
        final todayMatches = data.matches.where((m) => m.dayOffset == 0).toList();
        final todayAnalysed = todayMatches.where((m) => m.hasAnalysis).toList();
        final analysedCount = data.matches.where((m) => m.hasAnalysis).length;
        final generated = data.generatedAt;
        final stale =
            generated != null && DateTime.now().difference(generated).inHours > 36;
        final example = DemoData.nerisVallon.markets.first;
        final hasOdds = data.matches.any(
          (m) => m.analysis?.markets.any((e) => e.odds != null) ?? false,
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'BET-FOLDER',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                data.isLive ? const LiveBadge() : const DemoBadge(),
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
            Text(
              data.isLive && generated != null
                  ? 'Football · football-data.org · mise à jour le ${fmtDateTime(generated)}'
                  : DemoData.updatedAtLabel,
              style: AppText.muted,
            ),
            if (data.loading)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  color: AppColors.accent,
                  backgroundColor: AppColors.border,
                ),
              ),
            if (data.message != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  data.message!,
                  style: const TextStyle(color: AppColors.warning, fontSize: 12),
                ),
              ),
            if (stale)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Données anciennes : la mise à jour quotidienne est en retard.',
                  style: TextStyle(color: AppColors.warning, fontSize: 12),
                ),
              ),
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
            if (todayAnalysed.isEmpty)
              const Text(
                'Aucun match analysé aujourd’hui. Voir l’onglet Matchs pour les jours suivants.',
                style: AppText.muted,
              ),
            for (final m in todayAnalysed.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: MatchCard(match: m, onTap: () => _open(context, m)),
              ),
            if (data.isLive)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: AppCard(
                  borderColor: AppColors.warning,
                  child: Text(
                    hasOdds
                        ? 'Cotes réelles chargées pour une partie des matchs (voir '
                            'l’analyse de chaque match). Le Scanner, les Tickets et '
                            'le Suivi utilisent encore la démonstration.'
                        : 'Aucune cote chargée pour l’instant : le Scanner, les '
                            'Tickets et le Suivi restent en démonstration.',
                    style: TextStyle(color: AppColors.warning, fontSize: 12),
                  ),
                ),
              )
            else ...[
              const SectionTitle('Marché à étudier (exemple)'),
              MarketCard(entry: example, subtitle: DemoData.matches.first.title),
            ],
            const SizedBox(height: 16),
            const Text(AppTexts.disclaimer, style: AppText.small),
          ],
        );
      },
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
