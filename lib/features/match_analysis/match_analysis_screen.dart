import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_text.dart';
import '../../core/favorites_store.dart';
import '../../data/models.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_chip.dart';
import '../../widgets/market_card.dart';
import '../../widgets/probability_bar.dart';
import '../../widgets/tags.dart';
import 'htft_tab.dart';
import 'stats_tab.dart';

class MatchAnalysisScreen extends StatefulWidget {
  const MatchAnalysisScreen({super.key, required this.match});

  final DemoMatch match;

  @override
  State<MatchAnalysisScreen> createState() => _MatchAnalysisScreenState();
}

class _MatchAnalysisScreenState extends State<MatchAnalysisScreen> {
  int _tab = 0; // 0 = Marchés, 1 = Stats, 2 = Mi-temps/Fin

  List<Widget> _marketsSection(MatchAnalysis analysis) {
    return [
      const SectionTitle('Marchés'),
      for (final entry in analysis.markets)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: MarketCard(entry: entry),
        ),
      AppCard(
        borderColor: AppColors.warning,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Text(
          'Limites : ${analysis.limits}',
          style: const TextStyle(color: AppColors.warning, fontSize: 12),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final probs = match.probs;
    final analysis = match.analysis;
    const teamStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.w700);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Analyse du match', style: TextStyle(fontSize: 16)),
        actions: [
          ValueListenableBuilder<Set<String>>(
            valueListenable: FavoritesStore.favorites,
            builder: (context, favorites, _) {
              final isFavorite = favorites.contains(match.id);
              return IconButton(
                tooltip:
                    isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
                icon: Icon(
                  isFavorite ? Icons.star : Icons.star_border,
                  color: isFavorite ? AppColors.warning : AppColors.textMuted,
                ),
                onPressed: () => FavoritesStore.toggle(match.id),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${match.competition} · ${match.time}',
                        style: AppText.muted),
                    match.isDemo
                        ? const DemoBadge(label: 'DÉMO')
                        : const LiveBadge(label: 'RÉEL'),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(match.home, style: teamStyle),
                    Text(match.away, style: teamStyle),
                  ],
                ),
                if (probs != null) ...[
                  const SizedBox(height: 10),
                  ProbabilityBar(probs: probs),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(match.confidence?.label ?? '',
                        style: AppText.muted),
                  ),
                ],
                if (analysis != null) ...[
                  const SizedBox(height: 14),
                  const Text('Scores exacts suggérés (indicatif)',
                      style: AppText.muted),
                  const SizedBox(height: 6),
                  _ScoresRow(analysis: analysis),
                  const SizedBox(height: 6),
                  Text(
                    'Un score exact reste rare : environ 1 fois sur '
                    '${(100 / analysis.suggestions.first.pct).round()} au mieux.',
                    style: AppText.small,
                  ),
                ],
              ],
            ),
          ),
          if (analysis != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                AppChip(
                  label: 'Marchés',
                  selected: _tab == 0,
                  onSelected: (_) => setState(() => _tab = 0),
                ),
                AppChip(
                  label: 'Stats',
                  selected: _tab == 1,
                  onSelected: (_) => setState(() => _tab = 1),
                ),
                AppChip(
                  label: 'Mi-temps/Fin',
                  selected: _tab == 2,
                  onSelected: (_) => setState(() => _tab = 2),
                ),
              ],
            ),
            if (_tab == 0)
              ..._marketsSection(analysis)
            else if (_tab == 1)
              StatsTab(match: match, analysis: analysis)
            else
              HtFtTab(match: match, analysis: analysis),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: AppCard(
                child: Text(
                  'Dans ce prototype, le détail (marchés, scores, stats) existe '
                  'seulement pour Néris FC – Vallon SC.',
                  style: AppText.muted,
                ),
              ),
            ),
          const SizedBox(height: 16),
          const Text(AppTexts.disclaimer, style: AppText.small),
        ],
      ),
    );
  }
}

class _ScoresRow extends StatelessWidget {
  const _ScoresRow({required this.analysis});

  final MatchAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ScoreBox(
            label: 'SUGGESTION 1',
            score: analysis.suggestions[0],
            highlighted: true,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _ScoreBox(
            label: 'SUGGESTION 2',
            score: analysis.suggestions[1],
            highlighted: true,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _ScoreBox(
            label: 'ALTERNATIVE',
            score: analysis.alternative,
            highlighted: false,
          ),
        ),
      ],
    );
  }
}

class _ScoreBox extends StatelessWidget {
  const _ScoreBox({
    required this.label,
    required this.score,
    required this.highlighted,
  });

  final String label;
  final ScoreSuggestion score;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.accentSoft : null,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlighted ? AppColors.accent : AppColors.textMuted,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: highlighted ? AppColors.accent : AppColors.textMuted,
            ),
          ),
          Text(
            score.score,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          Text('${score.pct} %', style: AppText.muted),
        ],
      ),
    );
  }
}
