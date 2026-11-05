# Lyrion Remote — iOS app + widget

Projet iOS (SwiftUI + WidgetKit) inspiré d'iPeng pour piloter un serveur **Lyrion / Lyrion Music Server (ex‑LMS)**.

Fonctionnalités :
- Widget interactif (moyen/grand) : pochette, titre, artiste, état, et 5 boutons **précédent / play / pause / suivant / mute**.
- App : affichage now‑playing, mêmes contrôles, choix du serveur et du lecteur.

Préconfiguré avec tes valeurs :
- Serveur : `http://192.168.40.175:9000`
- Lecteurs : Salon (`88:a2:9e:a4:a0:e9`), Terrasse bas (`b8:27:eb:65:7d:6b`), Chambre (`b8:27:eb:17:f1:d0`), Terrasse haut / Billard (`b8:27:eb:b5:94:08`).

## Structure

- `Shared/` — client JSON-RPC Lyrion (`/jsonrpc.js`) + config des lecteurs.
- `App/` — app SwiftUI.
- `Widget/` — extension WidgetKit + App Intents (commandes au tap, sans ouvrir l'app).
- `project.yml` — génération du projet Xcode via XcodeGen.
- `.github/workflows/build-ipa.yml` — build GitHub Actions produisant une IPA **non signée**.

## Ce que je peux/ne peux pas faire ici

Je n'ai pas de macOS/Xcode ici, donc je ne peux pas compiler l'app ni signer le binaire. Le workflow GitHub Actions génère l'IPA **non signée**.

## Construire l'IPA (GitHub Actions)

1. Pousse ce dossier dans un dépôt GitHub (ou copie les fichiers).
2. Va dans l'onglet **Actions** → **Build Lyrion widget IPA** → **Run workflow**.
3. Télécharge l'artifact `LyrionRemote-unsigned-ipa`.

## Signature et installation (obligatoire)

Un widget (extension `.appex`) doit être signé, comme l'app. Il faut signer **l'extension puis l'app** avec le même type de compte/certificat.

Options :
- **AltStore / Sideloadly** : installe l'IPA. Selon l'outil et ton compte, l'extension widget peut ne pas être activée correctement ; vérifie après installation que le widget apparaît dans la galerie de widgets.
- **Compte Apple Developer + Xcode** (fiable) : ouvre le projet sur un Mac, règle `Signing & Capabilities` pour `com.christ.lyrionremote` et `com.christ.lyrionremote.widget`, puis installe sur ton iPhone.
- **zsign/ldid** : possible uniquement si tu signes correctement app + appex + entitlements/profil adaptés ; c'est le chemin le plus délicat.

Identifiants de bundle :
- App : `com.christ.lyrionremote`
- Widget : `com.christ.lyrionremote.widget`

## Ajouter le widget sur l'iPhone

1. Installe l'app signée et ouvre-la une fois (réglages app).
2. Appui long sur l'écran d'accueil → **+** → cherche **Lyrion**.
3. Choisis la taille moyenne ou grande → **Ajouter le widget**.
4. Appui long sur le widget → **Modifier le widget** → choisis le **serveur** et le **lecteur**.

Les boutons envoient les commandes directement (App Intent). La pochette/titre se rafraîchit selon la politique iOS (WidgetKit n'est pas temps réel).

## Accès réseau

L'URL par défaut est `http://192.168.40.175:9000` (réseau local). Les `Info.plist` autorisent le HTTP local (`NSAppTransportSecurity` + `NSLocalNetworkUsageDescription`). Pour l'utiliser hors de chez toi, il faut exposer Lyrion de façon sécurisée (HTTPS/VPN) et changer l'URL du serveur dans le widget/l'app.

## Commandes envoyées (JSON-RPC Lyrion)

Identiques à celles observées dans iPeng :
- Play : `["play"]`
- Pause : `["pause", 1]`
- Suivant : `["button", "jump_fwd"]`
- Précédent : `["button", "jump_rew"]`
- Mute : `["mixer", "muting", "toggle"]`

Personnalisation : édite `Shared/LyrionConfig.swift` (serveur par défaut, lecteurs connus).
