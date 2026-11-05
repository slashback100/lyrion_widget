# Lyrion Remote — iOS app + widget

Projet iOS (SwiftUI + WidgetKit) inspiré d'iPeng pour piloter un serveur **Lyrion / Lyrion Music Server (ex‑LMS)**.

Fonctionnalités :
- Widget interactif (moyen/grand) : pochette, titre, artiste, état, et 5 boutons **précédent / play / pause / suivant / mute**.
- App : affichage now‑playing, contrôles lecture, réglage du volume, choix du serveur et du lecteur.

Préconfiguré avec tes valeurs :
- Serveur : `http://lyrion_host:9000`
- Lecteurs : Salon, Terrasse bas, Chambre, Terrasse haut / Billard.

## Structure

- `Shared/` — client JSON-RPC Lyrion (`/jsonrpc.js`) + config des lecteurs.
- `App/` — app SwiftUI.
- `Widget/` — extension WidgetKit + App Intents (commandes au tap, sans ouvrir l'app).
- `project.yml` — génération du projet Xcode via XcodeGen.
- `.github/workflows/build-ipa.yml` — build GitHub Actions produisant une IPA **non signée**.

## Accès réseau

L'URL par défaut est `http://lyrion_host:9000` (réseau local). Les `Info.plist` autorisent le HTTP local (`NSAppTransportSecurity` + `NSLocalNetworkUsageDescription`). Pour l'utiliser hors de chez toi, il faut exposer Lyrion de façon sécurisée (HTTPS/VPN) et changer l'URL du serveur dans le widget/l'app.

## Commandes envoyées (JSON-RPC Lyrion)

Identiques à celles observées dans iPeng (lecture) :
- Play : `["play"]`
- Pause : `["pause", 1]`
- Suivant : `["button", "jump_fwd"]`
- Précédent : `["button", "jump_rew"]`
- Mute : `["mixer", "muting", "toggle"]`
- Volume (app) : `["mixer", "volume", N]` (0–100)

Personnalisation : édite `Shared/LyrionConfig.swift` (serveur par défaut, lecteurs connus).
