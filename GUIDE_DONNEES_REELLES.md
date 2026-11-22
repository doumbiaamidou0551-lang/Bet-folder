# Activer les données réelles du football (mise en place unique)

À la fin, GitHub mettra à jour les données **chaque jour à 00h20** (heure de Côte d’Ivoire = heure UTC) et l’application les lira. GitHub peut retarder l’exécution de quelques minutes, parfois d’une heure.

## 1. Obtenir un jeton gratuit chez football-data.org
- Allez sur football-data.org, cherchez « Register » ou « Get your free API key », remplissez le formulaire.
- Vous recevez un e-mail avec un **API token** (une longue suite de lettres et de chiffres). Gardez-le pour vous : ne l’envoyez à personne, pas même à moi.

## 2. Ajouter ce jeton dans GitHub
- Dépôt `bet-folder`, onglet **Settings** (parfois caché sous « … » ou « More »).
- Menu de gauche : « Secrets and variables », puis « Actions ».
- Cliquez « New repository secret ». Name : `FOOTBALL_DATA_TOKEN` (exactement). Secret : collez le jeton. Cliquez « Add secret ».

## 3. Rendre le dépôt public
L’application lit le fichier de données sans se connecter à GitHub, donc le dépôt doit être public. Le jeton, lui, reste caché.
- Settings, onglet « General », tout en bas : « Danger Zone ».
- « Change repository visibility », puis « Make public », puis confirmez.

## 4. Envoyer les nouveaux fichiers
- Faites comme dans `GUIDE_MISE_A_JOUR.md`, étape 2 : glissez tout le contenu du dossier `bet_folder` (en particulier le nouveau dossier `engine`).
- Ajoutez le fichier de planification : « Add file » (le « + »), « Create new file », nom : `.github/workflows/daily-data.yml`. Collez le contenu du fichier `daily-data.yml` fourni, puis « Commit changes… » deux fois.

## 5. Lancer une première fois
- Onglet « Actions », à gauche « Données du jour », bouton « Run workflow », puis le bouton vert.
- Après 2 à 4 minutes, une coche verte apparaît. Dans l’onglet « Code », un dossier `data` contient le fichier `latest.json`.
- Envoyez-moi une capture de la page Actions (et, si possible, du début du fichier `latest.json`). Je branche ensuite l’application sur ces données.

## Limites à connaître
- Football uniquement pour l’instant, 8 compétitions de l’offre gratuite : Premier League, LaLiga, Serie A, Bundesliga, Ligue 1, Ligue des champions, Eredivisie, Liga Portugal.
- Pas encore de cotes : l’écart « probabilité contre cote » ne sera affiché que lorsqu’une source de cotes sera branchée.
- Basket, tennis et hockey : prévus, pas encore développés.
