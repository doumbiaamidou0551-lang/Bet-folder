import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../data/demo_data.dart';
import '../data/live_data.dart';
import '../data/models.dart';

enum DataSource { demo, live }

class AppDataState {
  const AppDataState({
    required this.matches,
    required this.source,
    this.generatedAt,
    this.excludedCount = 0,
    this.loading = false,
    this.message,
  });

  final List<DemoMatch> matches;
  final DataSource source;
  final DateTime? generatedAt;
  final int excludedCount;
  final bool loading;
  final String? message;

  bool get isLive => source == DataSource.live;
}

/// Données affichées par l'application : réelles si disponibles (fichier
/// publié chaque jour), sinon dernières données enregistrées, sinon démo.
class AppData {
  static const String url =
      'https://raw.githubusercontent.com/doumbiaamidou0551-lang/Bet-folder/main/data/latest.json';

  /// Désactivé dans les tests pour éviter tout accès réseau.
  static bool autoLoad = true;

  static final ValueNotifier<AppDataState> state = ValueNotifier<AppDataState>(
    const AppDataState(matches: DemoData.matches, source: DataSource.demo),
  );

  static File get _cacheFile =>
      File('${Directory.systemTemp.path}/bet_folder_latest.json');

  static Future<void> load() async {
    final before = state.value;
    state.value = AppDataState(
      matches: before.matches,
      source: before.source,
      generatedAt: before.generatedAt,
      excludedCount: before.excludedCount,
      loading: true,
      message: before.message,
    );

    // 1) Dernières données enregistrées, affichées tout de suite.
    try {
      final file = _cacheFile;
      if (!before.isLive && await file.exists()) {
        _apply(parseSnapshot(await file.readAsString(), DateTime.now()), true);
      }
    } catch (_) {
      // Fichier enregistré illisible : on l'ignore.
    }

    // 2) Données du jour depuis Internet.
    try {
      final text = await _download();
      _apply(parseSnapshot(text, DateTime.now()), false);
      try {
        await _cacheFile.writeAsString(text);
      } catch (_) {
        // Enregistrement impossible : sans conséquence.
      }
    } catch (error) {
      final now = state.value;
      final firstLine = error.toString().split('\n').first;
      final detail =
          firstLine.length > 140 ? '${firstLine.substring(0, 140)}…' : firstLine;
      state.value = AppDataState(
        matches: now.matches,
        source: now.source,
        generatedAt: now.generatedAt,
        excludedCount: now.excludedCount,
        loading: false,
        message: now.isLive
            ? 'Hors connexion : dernières données enregistrées. ($detail)'
            : 'Données réelles indisponibles : démonstration affichée. ($detail)',
      );
    }
  }

  static void _apply(LiveSnapshot snapshot, bool loading) {
    state.value = AppDataState(
      matches: snapshot.matches,
      source: DataSource.live,
      generatedAt: snapshot.generatedAt,
      excludedCount: snapshot.excludedCount,
      loading: loading,
    );
  }

  static Future<String> _download() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close().timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode}');
      }
      return await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 30));
    } finally {
      client.close();
    }
  }
}
