import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_text.dart';
import '../../core/format.dart';
import '../../data/tracker_data.dart';
import '../../widgets/app_card.dart';
import '../../widgets/tags.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Historique des analyses'),
        for (final e in TrackerData.history)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _HistoryCard(entry: e),
          ),
        const Text(
          'Gain théorique calculé pour une mise de 1 unité. Chaque analyse est '
          'figée avant le match (données de démonstration).',
          style: AppText.small,
        ),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final gain = fmtDec(entry.odds - 1, digits: 2);
    final (String text, Color color) = switch (entry.status) {
      BetStatus.pending => ('En cours', AppColors.textMuted),
      BetStatus.won => ('Gagné +$gain', AppColors.accent),
      BetStatus.lost => ('Perdu −1,00', AppColors.danger),
    };
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${entry.date} · analyse figée', style: AppText.muted),
              TagChip(text: text, color: color),
            ],
          ),
          const SizedBox(height: 2),
          Text(entry.match, style: AppText.bold),
          Text(
            '${entry.market} · cote ${fmtOdds(entry.odds)} · prévu ${entry.predictedPct} %',
            style: AppText.muted,
          ),
        ],
      ),
    );
  }
}
