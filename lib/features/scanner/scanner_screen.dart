import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_text.dart';
import '../../core/format.dart';
import '../../data/demo_data.dart';
import '../../data/models.dart';
import '../../data/picks.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_chip.dart';
import '../../widgets/tags.dart';
import '../match_analysis/match_analysis_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  PickProfile? _filter; // null = tous les profils

  @override
  Widget build(BuildContext context) {
    // Règle du scanner : seuls les marchés avec un écart positif sont listés.
    final picks = PicksData.all
        .where((p) => p.gapPts > 0 && (_filter == null || p.profile == _filter))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Market Scanner',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            DemoBadge(),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            AppChip(
              label: 'Tous',
              selected: _filter == null,
              onSelected: (_) => setState(() => _filter = null),
            ),
            for (final profile in PickProfile.values)
              AppChip(
                label: profile.shortLabel,
                selected: _filter == profile,
                onSelected: (_) => setState(() => _filter = profile),
              ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          '${PicksData.analysedCount} analyses parcourues · '
          '${PicksData.excludedCount} exclues (données insuffisantes) · '
          'les profils indiquent un risque estimé, pas une garantie.',
          style: AppText.muted,
        ),
        if (picks.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Text('Aucun marché pour ce profil.', style: AppText.muted),
          ),
        const SizedBox(height: 10),
        for (final pick in picks)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _PickCard(pick: pick),
          ),
        const SizedBox(height: 6),
        const Text(AppTexts.disclaimer, style: AppText.small),
      ],
    );
  }
}

class _PickCard extends StatelessWidget {
  const _PickCard({required this.pick});

  final ScannerPick pick;

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
    final leg = pick.leg;
    final lowConfidence = pick.confidence == Confidence.faible;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        final match = DemoData.matches.firstWhere((m) => m.id == leg.matchId);
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MatchAnalysisScreen(match: match),
          ),
        );
      },
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(leg.market, style: AppText.bold)),
                TagChip(
                  text: signedPts(pick.gapPts),
                  color: lowConfidence ? AppColors.warning : AppColors.accent,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(leg.matchTitle, style: AppText.muted),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _kv('Estimé', '${leg.estimatedPct} %'),
                _kv('Cote', fmtOdds(leg.odds)),
                _kv('Implicite', '${pick.impliedPct} %'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${pick.profile.label} · ${pick.confidence.label}',
              style: AppText.muted,
            ),
            const SizedBox(height: 6),
            Text('Pourquoi : ${pick.why}', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Text('Limites : ${pick.limits}', style: AppText.muted),
          ],
        ),
      ),
    );
  }
}
