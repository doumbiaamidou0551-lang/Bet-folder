import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_data.dart';
import '../../core/app_text.dart';
import '../../core/favorites_store.dart';
import '../../core/format.dart';
import '../../data/demo_data.dart';
import '../../data/models.dart';
import '../../widgets/app_card.dart';
import '../../widgets/tags.dart';
import '../match_analysis/match_analysis_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  int _day = 0; // 0 = aujourd'hui, 1 = demain, 2 = plus tard
  bool _favoritesOnly = false;

  Widget _chip(String label, bool selected, ValueChanged<bool> onSelected) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      selectedColor: AppColors.accent,
      backgroundColor: AppColors.surfaceHigh,
      side: BorderSide.none,
      labelStyle: TextStyle(
        color: selected ? AppColors.background : AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      onSelected: onSelected,
    );
  }

  bool _inDay(DemoMatch m) =>
      _day == 2 ? m.dayOffset >= 2 : m.dayOffset == _day;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppDataState>(
      valueListenable: AppData.state,
      builder: (context, data, _) {
        return ValueListenableBuilder<Set<String>>(
          valueListenable: FavoritesStore.favorites,
          builder: (context, favorites, _) {
            final visible = data.matches
                .where((m) =>
                    _inDay(m) && (!_favoritesOnly || favorites.contains(m.id)))
                .toList();
            final groups = <String, List<DemoMatch>>{};
            for (final m in visible) {
              groups.putIfAbsent(m.competition, () => <DemoMatch>[]).add(m);
            }
            final generated = data.generatedAt;

            return RefreshIndicator(
              onRefresh: AppData.load,
              color: AppColors.accent,
              backgroundColor: AppColors.surfaceHigh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Matchs',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                      ),
                      data.isLive ? const LiveBadge() : const DemoBadge(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      _chip('Aujourd’hui', _day == 0, (_) => setState(() => _day = 0)),
                      _chip('Demain', _day == 1, (_) => setState(() => _day = 1)),
                      _chip('Plus tard', _day == 2, (_) => setState(() => _day = 2)),
                      _chip(
                        'Favoris',
                        _favoritesOnly,
                        (v) => setState(() => _favoritesOnly = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data.isLive && generated != null
                        ? 'Données réelles · mise à jour le ${fmtDateTime(generated)} · tirez vers le bas pour actualiser'
                        : DemoData.updatedAtLabel,
                    style: AppText.muted,
                  ),
                  if (data.message != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        data.message!,
                        style: const TextStyle(color: AppColors.warning, fontSize: 12),
                      ),
                    ),
                  if (data.isLive && data.excludedCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '${data.excludedCount} match(s) exclu(s) : historique insuffisant pour une équipe.',
                        style: AppText.small,
                      ),
                    ),
                  if (visible.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Text(
                        'Aucun match pour ce filtre.',
                        style: AppText.muted,
                      ),
                    ),
                  for (final entry in groups.entries) ...[
                    SectionTitle(entry.key),
                    for (final m in entry.value)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _MatchRow(
                          match: m,
                          isFavorite: favorites.contains(m.id),
                        ),
                      ),
                  ],
                  const SizedBox(height: 12),
                  const Text(
                    'Estimations statistiques, aucune garantie de résultat.',
                    style: AppText.small,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _MatchRow extends StatelessWidget {
  const _MatchRow({required this.match, required this.isFavorite});

  final DemoMatch match;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    final probs = match.probs;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: match.hasAnalysis
          ? () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MatchAnalysisScreen(match: match),
                ),
              )
          : null,
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(match.time, style: AppText.muted),
                  Text(match.title, style: AppText.bold),
                  if (probs != null)
                    Text(
                      'Dom. ${probs.home} % · Nul ${probs.draw} % · Ext. ${probs.away} %',
                      style: AppText.muted,
                    )
                  else
                    const Text(
                      'Données insuffisantes : pas d’analyse',
                      style: TextStyle(color: AppColors.warning, fontSize: 12),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
              icon: Icon(
                isFavorite ? Icons.star : Icons.star_border,
                color: isFavorite ? AppColors.warning : AppColors.textMuted,
              ),
              onPressed: () => FavoritesStore.toggle(match.id),
            ),
          ],
        ),
      ),
    );
  }
}
