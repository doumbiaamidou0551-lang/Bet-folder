import 'package:flutter/foundation.dart';

/// Favoris gardés en mémoire seulement (perdus à la fermeture de l'application).
/// La sauvegarde durable viendra avec la base locale (étape 5).
class FavoritesStore {
  static final ValueNotifier<Set<String>> favorites =
      ValueNotifier<Set<String>>(<String>{});

  static void toggle(String id) {
    final next = Set<String>.from(favorites.value);
    if (!next.remove(id)) next.add(id);
    favorites.value = next;
  }
}
