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

## Version 3g : l'application lit les données réelles
- Au démarrage, l'application télécharge `data/latest.json` (publié chaque jour par GitHub). Si Internet est coupé, elle affiche les dernières données enregistrées, sinon la démonstration. Tirer vers le bas dans « Matchs » actualise.
- Accueil, Matchs et Analyse affichent les matchs réels (badge « DONNÉES RÉELLES »). Pas de cotes : l'écart n'est pas calculé. Pas de statistiques de joueurs avec la source gratuite.
- Scanner, Tickets et Suivi restent en démonstration, car ils ont besoin de cotes et d'un historique réel.
- Le fichier `build-apk.yml` ajoute la permission Internet à l'application Android.

## Version 3h : cotes réelles (API-Sports)
- Le moteur récupère les cotes avant-match chez API-Sports (clé `API_SPORTS_KEY`), rapproche les matchs des deux sources (nom + heure + compétition) et ajoute les cotes aux marchés : 1X2, plus/moins 1,5 / 2,5 / 3,5, les deux équipes marquent, double chance, mi-temps/fin de match.
- Bookmaker de référence : Pinnacle, sinon Bet365, 1xBet, etc. Le nom et l'heure de relevé sont affichés dans « Limites ».
- Budget : environ 35 requêtes par jour sur les 100 de l'offre gratuite (matchs d'aujourd'hui et de demain).
- `data/latest.json` contient un bloc `diagnostics.api_sports` (requêtes utilisées, matchs rapprochés, noms de paris vus) pour contrôler le résultat.
- Scanner, Tickets et Suivi utilisent encore la démonstration : ils passeront aux cotes réelles une fois leur chargement vérifié.
