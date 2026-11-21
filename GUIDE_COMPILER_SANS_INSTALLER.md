# Obtenir l’APK sans rien installer (compilation gratuite dans le cloud)

**Principe** : vous envoyez les fichiers à GitHub (un site gratuit), un ordinateur distant compile l’application Android à votre place, puis vous téléchargez le fichier d’installation (APK) et l’installez sur votre téléphone.

**Il vous faut** : un ordinateur (même prêté) avec Internet, une adresse e-mail, et votre téléphone Android.

## 1. Créer un compte GitHub
Sur github.com, cliquez sur « Sign up », créez un compte gratuit et confirmez votre e-mail.

## 2. Créer un dépôt (un dossier en ligne)
- Cliquez sur le « + » en haut à droite, puis « New repository ».
- Nom : `bet-folder`. Cochez **Private**. Cliquez sur « Create repository ».

## 3. Envoyer les fichiers
- Décompressez `bet_folder_prototype_3c.zip` (clic droit, « Extraire tout »). Ouvrez le dossier `bet_folder` obtenu.
- Dans votre dépôt GitHub, cliquez sur le lien « uploading an existing file ».
- Sélectionnez **tout ce qui se trouve dans** le dossier `bet_folder` (`lib`, `test`, `.github` s’il est visible, `pubspec.yaml`, `analysis_options.yaml`, `README.md`) et glissez-le dans la page. Attendez la fin de l’envoi, puis cliquez sur « Commit changes ».
- **Vérification** : dans la liste des fichiers du dépôt, cherchez un dossier nommé `.github`. S’il y est, passez directement à l’étape 5. Sinon, faites l’étape 4.

## 4. Ajouter le fichier de compilation (seulement si `.github` est absent)
- Cliquez sur « Add file », puis « Create new file ».
- Dans le champ du nom, tapez exactement : `.github/workflows/build-apk.yml` (les « / » créent les dossiers).
- Ouvrez le fichier `build-apk.yml` fourni avec l’archive, copiez tout son contenu et collez-le dans la grande zone de texte.
- Cliquez sur « Commit changes », puis de nouveau « Commit changes ».

## 5. Lancer la compilation
- Cliquez sur l’onglet « Actions ». Si GitHub demande d’activer les workflows, acceptez.
- À gauche, choisissez « Compiler l’APK Android », puis « Run workflow » (bouton à droite), puis le bouton vert « Run workflow ».
- Attendez 5 à 10 minutes. Le rond jaune devient une coche verte si tout va bien.

## 6. Récupérer et installer l’APK
- Cliquez sur l’exécution terminée, descendez jusqu’à « Artifacts », cliquez sur `bet-folder-apk` : un zip se télécharge.
- Décompressez-le : vous obtenez `app-release.apk`. Envoyez-le sur votre téléphone (câble USB, e-mail, WhatsApp ou Drive).
- Sur le téléphone, ouvrez le fichier. Si Android le demande, autorisez l’installation depuis cette source.

## En cas de blocage
- **Vous ne savez pas où cliquer** : écrivez-moi simplement « je suis à l’étape X et je vois… », je vous guide.
- **Une croix rouge apparaît** : cliquez sur l’exécution en échec, puis sur l’étape marquée d’une croix rouge. Faites une capture d’écran du message (ou copiez le texte) et envoyez-la-moi : je corrige le code et je vous renvoie une archive.
