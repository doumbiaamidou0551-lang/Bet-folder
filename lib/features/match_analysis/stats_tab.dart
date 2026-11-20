import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_text.dart';
import '../../core/format.dart';
import '../../data/models.dart';
import '../../widgets/app_card.dart';
import '../../widgets/tags.dart';

/// Onglet Stats : buteurs probables, statistiques des joueurs et des équipes.
class StatsTab extends StatelessWidget {
  const StatsTab({super.key, required this.match, required this.analysis});

  final DemoMatch match;
  final MatchAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final scorers = analysis.players.where((p) => p.scorerPct != null).toList()
      ..sort((a, b) => b.scorerPct!.compareTo(a.scorerPct!));
    final confirmed = analysis.lineup == LineupStatus.confirmed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Buteurs probables'),
        AppCard(
          borderColor: confirmed ? AppColors.accent : AppColors.warning,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TagChip(
                    text: analysis.lineup.label,
                    color: confirmed ? AppColors.accent : AppColors.warning,
                  ),
                  Text(analysis.versionLabel, style: AppText.muted),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                confirmed
                    ? 'Probabilités calculées avec les compositions confirmées.'
                    : 'Probabilités provisoires : elles seront recalculées dans '
                        'une nouvelle version dès que les compositions seront '
                        'confirmées.',
                style: AppText.muted,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        for (final p in scorers)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ScorerCard(player: p),
          ),
        const SectionTitle('Joueurs · saison'),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(
            children: [
              const _GridRow(
                cells: ['Joueur', 'Buts', 'Passes', 'TC/m', 'Fautes', 'Jaunes'],
                header: true,
              ),
              for (final p in analysis.players) ...[
                const Divider(height: 1, color: AppColors.border),
                _GridRow(
                  cells: [
                    p.name,
                    '${p.goals}',
                    '${p.assists}',
                    fmtDec(p.shotsOnTarget),
                    fmtDec(p.fouls),
                    '${p.yellowCards}',
                  ],
                ),
              ],
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text(
            'Passes = passes décisives · TC/m = tirs cadrés par match · '
            'Fautes = fautes commises par match.',
            style: AppText.small,
          ),
        ),
        const SectionTitle('Équipes · 10 derniers matchs'),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(
            children: [
              _GridRow(
                cells: ['Par match', match.home, match.away],
                header: true,
                firstFlex: 16,
              ),
              for (final r in analysis.teamStats) ...[
                const Divider(height: 1, color: AppColors.border),
                _GridRow(
                  cells: [r.label, fmtDec(r.home), fmtDec(r.away)],
                  firstFlex: 16,
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(analysis.teamStatsNote, style: AppText.small),
        ),
      ],
    );
  }
}

class _ScorerCard extends StatelessWidget {
  const _ScorerCard({required this.player});

  final PlayerStat player;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: player.name, style: AppText.bold),
                      TextSpan(
                        text: ' · ${player.team} · ${player.role}',
                        style: AppText.muted,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${fmtDec(player.goalsPerMatch, digits: 2)} but/match · '
                  '${fmtDec(player.shotsOnTarget)} tirs cadrés/match',
                  style: AppText.muted,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${player.scorerPct} %',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const Text('buteur', style: AppText.muted),
            ],
          ),
        ],
      ),
    );
  }
}

class _GridRow extends StatelessWidget {
  const _GridRow({
    required this.cells,
    this.header = false,
    this.firstFlex = 17,
  });

  final List<String> cells;
  final bool header;
  final int firstFlex;

  @override
  Widget build(BuildContext context) {
    final style = header ? AppText.muted : const TextStyle(fontSize: 12);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(
              flex: i == 0 ? firstFlex : 10,
              child: Text(
                cells[i],
                style: style,
                textAlign: i == 0 ? TextAlign.left : TextAlign.right,
              ),
            ),
        ],
      ),
    );
  }
}
