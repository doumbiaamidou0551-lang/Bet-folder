import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppText {
  static const TextStyle muted =
      TextStyle(color: AppColors.textMuted, fontSize: 12);
  static const TextStyle small =
      TextStyle(color: AppColors.textMuted, fontSize: 11);
  static const TextStyle bold = TextStyle(fontWeight: FontWeight.w600);
  static const TextStyle section = TextStyle(
    color: AppColors.textMuted,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
}

class AppTexts {
  /// Mention obligatoire, affichée sur l'accueil et sur chaque analyse.
  static const String disclaimer =
      'Les analyses et probabilités proposées sont des estimations '
      'statistiques et ne constituent pas une garantie de résultat. '
      'Les paris sportifs comportent un risque de perte financière.';
}
