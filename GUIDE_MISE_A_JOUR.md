# Mettre à jour l’application (à refaire à chaque nouvelle version)

## 1. Désinstaller l’ancienne version du téléphone
Appui long sur l’icône BET-FOLDER, puis « Désinstaller ». Chaque compilation est signée avec une clé différente : Android refuserait d’installer la nouvelle version par-dessus l’ancienne. Les données étant fictives, vous ne perdez rien.

## 2. Envoyer les nouveaux fichiers sur GitHub
- Décompressez `bet_folder_prototype_3d.zip` et ouvrez le dossier `bet_folder`.
- Dans votre dépôt `bet-folder`, cliquez sur le « **+** » (Add file), puis « **Upload files** ».
- Dans l’Explorateur de fichiers, appuyez sur **Ctrl + A** dans le dossier `bet_folder`, puis **glissez** la sélection dans la page. Les fichiers qui portent le même nom sont remplacés.
- Cliquez sur « **Commit changes** ».

## 3. Mettre à jour le fichier de compilation (cette fois seulement)
- Onglet « Code », dossier `.github`, dossier `workflows`, fichier `build-apk.yml`.
- Cliquez sur l’icône **crayon**, appuyez sur **Ctrl + A**, collez le nouveau contenu (fichier `build-apk.yml` fourni), puis « Commit changes… » deux fois.

## 4. Récupérer l’APK
- Onglet « Actions » : attendez la coche verte sur la compilation **la plus haute de la liste** (la plus récente). Ignorez celle d’avant.
- Cliquez dessus, descendez à « Artefacts », téléchargez `bet-folder-apk`, extrayez le zip, envoyez `app-release.apk` sur le téléphone et installez-le.
