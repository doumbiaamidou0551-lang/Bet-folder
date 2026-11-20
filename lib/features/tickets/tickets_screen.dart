import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_text.dart';
import '../../core/format.dart';
import '../../core/simulation_store.dart';
import '../../data/picks.dart';
import '../../domain/bankroll.dart';
import '../../domain/ticket_math.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_chip.dart';
import '../../widgets/tags.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  TicketMode _mode = TicketMode.prudent;
  final Set<String> _custom = <String>{};
  int _stake = 1000;

  List<TicketLeg> get _legs {
    if (_mode == TicketMode.perso) {
      return [
        for (final p in PicksData.all)
          if (_custom.contains(p.leg.id)) p.leg,
      ];
    }
    return _mode.legIds.map(PicksData.legById).toList();
  }

  void _save(List<TicketLeg> legs, TicketSummary summary) {
    final plural = legs.length > 1 ? 's' : '';
    final result = SimulationStore.add(
      label: '${_mode.label} · ${legs.length} sélection$plural',
      stake: _stake,
      odds: summary.totalOdds,
    );
    final message = switch (result) {
      LimitCheck.ok =>
        'Ticket enregistré en simulation : ${fmtFcfa(_stake)} (aucun argent réel).',
      LimitCheck.dailyExceeded =>
        'Limite journalière atteinte : ticket non enregistré.',
      LimitCheck.weeklyExceeded =>
        'Limite hebdomadaire atteinte : ticket non enregistré.',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _pickTile(ScannerPick p) {
    final selected = _custom.contains(p.leg.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        child: CheckboxListTile(
          value: selected,
          onChanged: (v) => setState(() {
            if (v == true) {
              _custom.add(p.leg.id);
            } else {
              _custom.remove(p.leg.id);
            }
          }),
          title: Text(
            '${p.leg.market} · cote ${fmtOdds(p.leg.odds)}',
            style: AppText.bold,
          ),
          subtitle: Text(
            '${p.leg.matchTitle} · estimé ${p.leg.estimatedPct} %',
            style: AppText.muted,
          ),
          activeColor: AppColors.accent,
          checkColor: AppColors.background,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final legs = _legs;
    final summary = summarizeTicket(legs);
    final joint = summary.jointPct;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Smart Ticket Builder',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ),
            DemoBadge(label: 'DÉMO'),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final mode in TicketMode.values)
              AppChip(
                label: mode.label,
                selected: _mode == mode,
                onSelected: (_) => setState(() => _mode = mode),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _mode == TicketMode.perso
              ? 'Cochez des sélections : l’analyse du ticket se met à jour '
                  '(corrélations, probabilité, risque).'
              : 'Ticket proposé à partir des marchés repérés (données démo).',
          style: AppText.muted,
        ),
        if (_mode == TicketMode.perso) ...[
          const SectionTitle('Marchés disponibles'),
          for (final p in PicksData.all) _pickTile(p),
        ],
        SectionTitle('Ticket ${_mode.label.toLowerCase()} (simulation)'),
        AppCard(
          child: legs.isEmpty
              ? const Text('Aucune sélection.', style: AppText.muted)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < legs.length; i++) ...[
                      if (i > 0) const Divider(height: 16, color: AppColors.border),
                      _LegRow(leg: legs[i]),
                    ],
                    const Divider(height: 20, color: AppColors.border),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: 'Cote totale ', style: AppText.muted),
                              TextSpan(
                                text: fmtOdds(summary.totalOdds),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: 'Probabilité approx. ', style: AppText.muted),
                              TextSpan(
                                text: joint == null ? '—' : fmtPct(joint),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (summary.risk != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: TagChip(
                          text: summary.risk!.label,
                          color: summary.risk == TicketRisk.faible
                              ? AppColors.accent
                              : AppColors.warning,
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 10),
        if (summary.hasCorrelation)
          const AppCard(
            borderColor: AppColors.warning,
            child: Text(
              'Deux sélections viennent du même match : elles sont corrélées, '
              'donc la probabilité du ticket n’est pas calculée. Elle '
              'demandera la matrice de scores (étape 4).',
              style: TextStyle(color: AppColors.warning, fontSize: 12),
            ),
          ),
        if (joint != null)
          AppCard(
            borderColor: AppColors.warning,
            child: Text(
              'Ce n’est pas un ticket gagnant : environ ${100 - joint.round()} '
              'fois sur 100, au moins une sélection échoue. Matchs différents, '
              'donc indépendance supposée. Probabilité implicite de la cote '
              'totale : ${fmtPct(summary.impliedPct)}.',
              style: const TextStyle(color: AppColors.warning, fontSize: 12),
            ),
          ),
        if (legs.isNotEmpty) ...[
          const SectionTitle('Mise simulée'),
          Wrap(
            spacing: 8,
            children: [
              for (final value in const [500, 1000, 2000])
                AppChip(
                  label: fmtFcfa(value),
                  selected: _stake == value,
                  onSelected: (_) => setState(() => _stake = value),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _save(legs, summary),
              child: const Text('Enregistrer en simulation'),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Aucun pari réel n’est placé : simulation uniquement. '
            'Limites : ${SimulationStore.dailyLimit} FCFA par jour, '
            '${SimulationStore.weeklyLimit} FCFA par semaine.',
            style: AppText.small,
          ),
        ],
        const SizedBox(height: 16),
        const Text(AppTexts.disclaimer, style: AppText.small),
      ],
    );
  }
}

class _LegRow extends StatelessWidget {
  const _LegRow({required this.leg});

  final TicketLeg leg;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(leg.market, style: AppText.bold),
              Text(leg.matchTitle, style: AppText.muted),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(fmtOdds(leg.odds), style: AppText.bold),
            Text('estimé ${leg.estimatedPct} %', style: AppText.muted),
          ],
        ),
      ],
    );
  }
}
