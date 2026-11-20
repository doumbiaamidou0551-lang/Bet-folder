import 'package:flutter/material.dart';

import '../../core/app_text.dart';
import '../../widgets/app_chip.dart';
import '../../widgets/tags.dart';
import 'bankroll_view.dart';
import 'history_view.dart';
import 'performance_view.dart';

/// Suivi : performance des analyses, historique figé et bankroll simulée.
class SuiviScreen extends StatefulWidget {
  const SuiviScreen({super.key});

  @override
  State<SuiviScreen> createState() => _SuiviScreenState();
}

class _SuiviScreenState extends State<SuiviScreen> {
  int _view = 0; // 0 = Performance, 1 = Historique, 2 = Bankroll

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Suivi',
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
              label: 'Performance',
              selected: _view == 0,
              onSelected: (_) => setState(() => _view = 0),
            ),
            AppChip(
              label: 'Historique',
              selected: _view == 1,
              onSelected: (_) => setState(() => _view = 1),
            ),
            AppChip(
              label: 'Bankroll',
              selected: _view == 2,
              onSelected: (_) => setState(() => _view = 2),
            ),
          ],
        ),
        if (_view == 0)
          const PerformanceView()
        else if (_view == 1)
          const HistoryView()
        else
          const BankrollView(),
        const SizedBox(height: 16),
        const Text(AppTexts.disclaimer, style: AppText.small),
      ],
    );
  }
}
