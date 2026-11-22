# BET-FOLDER — prototype Android (étapes 3a, 3b, 3c) — données fictives

Tout ce que l’application affiche est **fictif** (marqué « DÉMO »). Rien n’est connecté à une API.

## Contenu
- **Accueil**, **Matchs** (filtres Aujourd’hui / Demain / Favoris), **Analyse d’un match** (probabilités 1X2, deux scores suggérés + une alternative, marchés, onglet Stats : compositions, buteurs probables, statistiques des joueurs et des équipes).
- **Scanner** : marchés repérés, filtre par profil (prudent, modéré, risqué), raisons et limites. Seuls les marchés avec un écart positif sont listés.
- **Tickets** : modes Prudent, Équilibré, Cote élevée et Perso (on coche ses propres sélections). Cote totale et probabilité calculées ; si deux sélections viennent du même match, la probabilité n’est pas affichée (corrélation). Enregistrement en simulation avec limites journalière et hebdomadaire.
- **Suivi** : Performance (prévu contre observé, avec détection de surestimation), Historique figé, Bankroll simulée (solde, ROI, yield, taux de réussite, limites, alerte après 3 pertes d’affilée, marquage gagné/perdu).

## Ce qui n’est PAS développé
Splash, calendrier, Corner & Card Lab, favoris dédiés, paramètres, notifications, méthodologie, données réelles (API), base de données, vrais modèles statistiques (étape 4). Favoris et bankroll sont gardés en mémoire seulement.

## Important : ce code n’a jamais été compilé
Écrit sans Flutter ni accès au réseau : jamais exécuté ni testé. Compilez-le (voir `GUIDE_COMPILER_SANS_INSTALLER.md`) et envoyez-moi les erreurs éventuelles.

## Compiler
- **Sans rien installer** : suivez `GUIDE_COMPILER_SANS_INSTALLER.md` (GitHub compile l’APK pour vous).
- **Avec Flutter installé** : `flutter create bet_folder --platforms=android`, remplacez `lib`, `test`, `pubspec.yaml`, `analysis_options.yaml`, puis `flutter pub get`, `flutter test`, `flutter run`.

## Organisation
`lib/core` (thème, textes, formats, stockage en mémoire) · `lib/domain` (calculs purs : tickets, bankroll, calibration) · `lib/data` (modèles et données fictives) · `lib/widgets` · `lib/features` (écrans) · `test` (tests des calculs et du lancement).

## Ajouts de la version 3d
- Onglet **Mi-temps/Fin** dans l’analyse d’un match : résultat à la mi-temps et les 9 combinaisons mi-temps / fin de match (cote, probabilité implicite, écart). Données de démonstration.
- **Icône** de l’application : dossier `android_icons` (copié dans le projet Android par le flux de compilation). `store/icon-512.png` servira pour Google Play.

## Version 3e : données réelles (football) et moteur statistique
- `engine/` : moteur Python (Poisson / Dixon-Coles, marchés de buts, scores exacts, mi-temps/fin de match), testé sur un championnat fictif aux forces connues (`python -m unittest discover -s tests`).
- `.github/workflows/daily-data.yml` : chaque jour à 00h20 UTC, récupère les matchs (football-data.org), calcule les probabilités et publie `data/latest.json`.
- L’application ne lit pas encore ce fichier : elle sera branchée dessus dès que le premier fichier réel existe (voir `GUIDE_DONNEES_REELLES.md`).
- `tools/make_icon.py` génère l’icône (monogramme BF, flèche verte, lueurs bleue et rouge).
- **Écran de démarrage** (`lib/features/splash`) : portrait en fond, monogramme BF, slogan « Analyse · Probabilités · Discipline », sports couverts. Touchez l’écran pour passer. Le fond de lancement Android est aussi bleu nuit.
