import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_text.dart';
import '../../core/format.dart';
import '../../core/simulation_store.dart';
import '../../domain/bankroll.dart';
import '../../widgets/app_card.dart';
import '../../widgets/tags.dart';

/// Bankroll SIMULÉE : aucun argent réel n'est engagé.
class BankrollView extends StatelessWidget {
  const BankrollView({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<SimBet>>(
      valueListenable: SimulationStore.bets,
      builder: (context, bets, _) {
        final s = computeBankroll(bets, initial: SimulationStore.initialBudget);
        final today = stakedWithin(bets, 1);
        final week = stakedWithin(bets, 7);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('Bankroll · mode simulation'),
            const Text(
              'Aucun argent réel n’est engagé. Les 8 premiers paris sont de démonstration.',
              style: AppText.muted,
            ),
            const SizedBox(height: 10),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Solde simulé', style: AppText.muted),
                  Text(
                    fmtFcfa(s.balance),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Budget initial ${fmtFcfa(s.initial)} · '
                    '${fmtPct(s.roiPct, digits: 1, signed: true)}',
                    style: AppText.muted,
                  ),
                  const SizedBox(height: 8),
                  Semantics(
                    label: 'Courbe du solde simulé',
                    child: SizedBox(
                      height: 56,
                      width: double.infinity,
                      child: CustomPaint(painter: _CurvePainter(s.curve)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _Kpi(label: 'Paris', value: '${bets.length}')),
                const SizedBox(width: 8),
                Expanded(
                  child: _Kpi(label: 'Réussite', value: fmtPct(s.successPct)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _Kpi(
                    label: 'ROI (budget initial)',
                    value: fmtPct(s.roiPct, digits: 1, signed: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Kpi(
                    label: 'Yield (total misé)',
                    value: fmtPct(s.yieldPct, digits: 1, signed: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AppCard(
              child: Column(
                children: [
                  _LimitRow(
                    label: 'Limite du jour',
                    used: today,
                    limit: SimulationStore.dailyLimit,
                  ),
                  const SizedBox(height: 10),
                  _LimitRow(
                    label: 'Limite de la semaine',
                    used: week,
                    limit: SimulationStore.weeklyLimit,
                  ),
                ],
              ),
            ),
            if (s.lossStreak >= 3) ...[
              const SizedBox(height: 8),
              AppCard(
                borderColor: AppColors.warning,
                child: Text(
                  '${s.lossStreak} pertes d’affilée : faites une pause. '
                  'Ne cherchez pas à récupérer vos pertes.',
                  style: const TextStyle(color: AppColors.warning, fontSize: 12),
                ),
              ),
            ],
            const SectionTitle('Paris simulés'),
            for (final bet in bets.reversed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _BetCard(bet: bet),
              ),
          ],
        );
      },
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.muted),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _LimitRow extends StatelessWidget {
  const _LimitRow({required this.label, required this.used, required this.limit});

  final String label;
  final int used;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final double ratio =
        limit == 0 ? 1.0 : (used / limit).clamp(0.0, 1.0).toDouble();
    final color = ratio >= 0.8 ? AppColors.warning : AppColors.accent;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppText.muted),
            Text('${fmtFcfa(used)} / ${fmtFcfa(limit)}', style: AppText.muted),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 6,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: AppColors.border),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: ratio,
                  child: ColoredBox(color: color),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BetCard extends StatelessWidget {
  const _BetCard({required this.bet});

  final SimBet bet;

  @override
  Widget build(BuildContext context) {
    final won = bet.won;
    final String statusText;
    final Color statusColor;
    if (won == null) {
      statusText = 'En cours';
      statusColor = AppColors.textMuted;
    } else if (won) {
      statusText = 'Gagné ${fmtFcfa(bet.profit)}';
      statusColor = AppColors.accent;
    } else {
      statusText = 'Perdu ${fmtFcfa(bet.profit)}';
      statusColor = AppColors.danger;
    }
    final when = bet.daysAgo == 0 ? 'aujourd’hui' : 'il y a ${bet.daysAgo} j';
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(bet.label, style: AppText.bold)),
              TagChip(text: statusText, color: statusColor),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Mise ${fmtFcfa(bet.stake)} · cote ${fmtOdds(bet.odds)} · $when',
            style: AppText.muted,
          ),
          if (won == null)
            Row(
              children: [
                TextButton(
                  onPressed: () => SimulationStore.settle(bet.id, true),
                  child: const Text('Marquer gagné'),
                ),
                TextButton(
                  onPressed: () => SimulationStore.settle(bet.id, false),
                  child: const Text('Marquer perdu'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CurvePainter extends CustomPainter {
  _CurvePainter(this.values);

  final List<int> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final range = (maxV - minV) == 0 ? 1 : (maxV - minV);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - (values[i] - minV) * size.height / range;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final paint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CurvePainter oldDelegate) =>
      oldDelegate.values != values;
}
