# Journal de développement — Cairn

> App de sevrage tabagique, Flutter, **local-first**. Source de vérité produit : `PLAN.md`.
> Conventions & règles non-négociables : `CLAUDE.md`. Ce journal = où on en est / comment reprendre.

---

## Point de reprise — 2026-08-03 (session 3 : signature, public, auto-update)

**État : app publiée et diffusable.** Repo GitHub **passé public**, releases **v1.0.0 → v1.0.5**
(APK signés avec un keystore de release). **Auto-update depuis les releases GitHub validé sur vrai
appareil** (bandeau au lancement + au retour au premier plan, download + install signé).

### Ce qui a été fait cette session
- **Signature release** : keystore `android/cairn-release.jks` (RSA 4096, alias `cairn`), chargé via
  `android/key.properties` dans `android/app/build.gradle.kts` (repli debug si absent). Keystore,
  `key.properties` et `SIGNING-SECRETS.txt` **gitignored**. ⚠️ **Sauvegarder le keystore hors machine**
  (le perdre = plus aucune MAJ publiable). Empreinte SHA-256 `9D:D9:0A:…:90:3A`.
- **Repo public** + releases via `gh` (installé dans `~/.local/bin`, authentifié `syoul46`).
- **README** réécrit (présentation, philosophie, install, lien release).
- **Auto-update** (`lib/core/update/`, `lib/features/update/`) : `checkForUpdate()` interroge
  l'API GitHub `releases/latest`, compare via `domain/update/version.dart` (testé), choisit l'APK
  selon l'ABI, `downloadAndInstall` (open_filex + `REQUEST_INSTALL_PACKAGES`). Bandeau global
  (`UpdateBanner`) + re-check au retour au premier plan (`UpdateOnResume`, throttle 2 min) + rejet
  par-version. Filigrane `vX.Y.Z` en bas (`VersionTag`). Manifest : `INTERNET` + `REQUEST_INSTALL_PACKAGES`.
  ⚠️ **C'est la seule connexion réseau de l'app** — le « 100 % offline » d'origine est nuancé (README à jour).
- Deps ajoutées : `http`, `package_info_plus`, `device_info_plus`, `open_filex`, `permission_handler`.

### Amorçage de l'auto-update (piège à retenir)
Une version déjà installée ne peut détecter une MAJ que si **elle-même contient le checker** (≥ 1.0.1)
**et** qu'une release **plus récente** existe. D'où la série v1.0.2→1.0.5 pour tester chaque maillon.

### Pistes restantes (inchangées)
iOS, CI, keystore sauvegardé hors machine, tuning seuils Boss, paliers santé. Rendre l'update
**manuel** (bouton) au lieu d'auto reste une option (un flag).

---

## Point de reprise — 2026-07-30 (fin de session 2)

**État : ✅ LES 10 JALONS SONT FAITS. Testés (49 verts), commités et poussés. MVP complet du
parcours (Écran 1 → observation → révélation → réduction/arrêt net → défi/rechute → sauvegarde).**
Tout est sur `main` (`origin` = `git@github.com:syoul46/Tabac-stop.git`).

### Pistes pour la suite (post-MVP, non planifiées)
- Beta réelle : tuner les seuils de détection des Boss sur de vraies données.
- iOS : config Xcode + notifications iOS (permission, catégories) + tester le partage.
- Onboarding badges/altitudes (paliers santé du cairn), historique/stats détaillés.
- CI (le repo n'a pas de pipeline) ; signature release Android ; icône & splash de marque.
- Vérifier sur vrai device : la police (Marcellus 1 graisse), le partage/sélection de fichier,
  et l'artefact de spellcheck vu sur l'émulateur (le `Text` n'a aucune décoration côté code).

### Note émulateur
Relancé cette fois **avec fenêtre** (`emulator -avd warren-x86_64 ... -gpu swiftshader_indirect`,
sans `-no-window`, `DISPLAY=:0`) pour visualisation directe. `flutter_local_notifications` nécessite
la permission `POST_NOTIFICATIONS` (demandée au 1ᵉʳ délai).

---

## Ce qui est fait (commits sur `main`)

| Commit | Contenu |
|---|---|
| `754189f` | **Jalon 0** — scaffold Flutter `cairn`, schéma drift (2 tables), thème minéral, enums |
| `81959bb` | **Jalon 1** — le bouton : tap = poser une pierre, chrono, compte, haptique, validation silencieuse |
| `d6c8d9d` | **Jalon 2** — observation J1-3 : bandeau « Jour X/3 », courbe horaire, 3 icônes contexte |
| `aa7b9d1` | **Jalon 3** — moteur de métriques (Dart pur) : moyenne/j, écart médian, créneau chargé |
| `83254f4` | **Jalon 4** — détection des Boss (DBSCAN 1D) : ancrage + difficulté, « le Café de 7 h 10 » |
| `a18d4b7` | **Jalon 5** — révélation J+3 : porte de déclenchement, RootScreen, RevealScreen, choix du mode |
| `9b99e6a` | build(android) : core library desugaring (requis) + outil de seed dev |
| `56a4e1c` | design : police serif Marcellus bundlée + créneau chargé (égalité → soir) |
| `21dd568` | docs : journal de développement |
| `795ce47` | **Jalon 6** — machine à états : resolvePhase + RootScreen + ColdTurkeyHome + ReductionHome |
| `294f096` | **Jalon 7a** — boucle de délai : resolveDelay + startDelay/held/broken + badge + pierres |
| `e511a8c` | **Jalon 7b** — notification locale T+10 (NotificationService), planif/annulation |
| `acee8ba` | **Jalon 8** — rechute : cumulativeCleanDays + recordGap (invariant) + offre réduction |
| `5644a98` | **Jalon 9a** — coffre chiffré (Vault Argon2id + XChaCha20) + BackupService |
| `4397d6a` | **Jalon 9b** — BackupScreen + I/O fichier (share_plus/file_picker), accès discret |
| `73be1a0` | **Jalon 10** — polish : prompt sauvegarde J4 (shouldOfferBackup) + thème sombre vérifié |

**Tests : 46 verts** (`flutter test`). Écrans validés sur émulateur : Écran 1, Observation,
Révélation, Arrêt net (+ rechute), Réduction (+ délai/notif), Sauvegarde (+ export .enc opaque).

### Build Android — notes
- `compileSdk = 36` dans `android/app/build.gradle.kts` **et** forcé sur tous les modules de
  plugin via `subprojects { afterEvaluate { LibraryExtension.compileSdk = 36 } }` dans
  `android/build.gradle.kts` (file_picker figeait 34, un plugin transitif exigeait 36).
- `share_plus ^10.1.4` + `file_picker ^8.3.3` alignés sur `win32 5.x` (share_plus 13 exigeait win32 6).

---

## Décisions verrouillées (rappel)
- Stack : Flutter · Riverpod · drift · flutter_local_notifications · export chiffré (à venir).
- **100 % local, aucun serveur.** Jour logique = **04:00**. Contexte : ☕ café · 🍽️ repas · 🍷 alcool.
- Révélation : **≥30 taps ET ≥3 jours**. Boss : **nommer le + ancré, attaquer le + facile**.
- Design : palette minérale (sable/basalte/ocre), **lagon = voix de l'app** (rare), **zéro rouge**.
  Le **cairn** est la métaphore centrale (invariant « le compteur cumulé ne bouge pas » = pierres
  qui ne tombent jamais). Cf. `CLAUDE.md` et les maquettes `design/*.html`.

---

## Environnement & commandes de reprise

**Flutter installé hors PATH** → exporter à chaque session :
```bash
export PATH="/home/syoul/flutter/bin:/home/syoul/Android/Sdk/platform-tools:/home/syoul/Android/Sdk/emulator:$PATH"
export ANDROID_HOME=/home/syoul/Android/Sdk ANDROID_SDK_ROOT=/home/syoul/Android/Sdk
```
Versions : Flutter 3.44.8 / Dart 3.12.2 (stable), dans `/home/syoul/flutter`.

**Tests**
```bash
flutter test test/domain/        # logique pure — ~4 s (à privilégier)
flutter test                     # suite complète (widgets) — ~10 min à froid !
flutter analyze                  # ~2 s, compile tout
```

**Émulateur** (AVD `warren-x86_64`, partagé avec le projet warren) :
```bash
emulator -avd warren-x86_64 -no-window -no-audio -no-boot-anim -gpu swiftshader_indirect -no-snapshot -read-only &
adb wait-for-device && adb shell getprop sys.boot_completed   # attendre "1"
```
**Lancer l'app** (build Android ~1-2 min ; le lourd — NDK/SDK — est déjà installé) :
```bash
cd /home/syoul/Tabac-stop
flutter run -d emulator-5554                        # normal
flutter run -d emulator-5554 --dart-define=SEED=true  # injecte 3 j de faux historique → révélation
```
**Capturer un écran** : `adb exec-out screencap -p > screen.png`
**Réinitialiser les données** : `adb shell pm clear com.syoul.cairn`

---

## Pièges rencontrés (à ne pas refaire)
- **Widget tests ~10 min à froid** (compilation moteur Flutter). Les tests `test/domain/` (Dart pur)
  compilent en ~4 s → itérer là quand c'est de la logique.
- **drift + widget tests** : un flux drift planifie un timer 0 s à sa fermeture → après démontage,
  `await tester.pump(const Duration(milliseconds: 1))` pour éviter « A Timer is still pending ».
  Aussi : ne jamais `await` un flux drift *dans* un `testWidgets` (deadlock FakeAsync).
- **`find.text` ne matche pas les `RichText`** → utiliser des `Text` séparés (valeur + unité).
- **Android : core library desugaring requis** par flutter_local_notifications (déjà corrigé dans
  `android/app/build.gradle.kts`).
- **`pkill -f 'motif'` s'auto-tue** si le motif figure dans sa propre ligne de commande (ex.
  `SEED=false`) → il emporte le shell parent (exit 144). Mettre le kill **seul** dans sa commande.
- **`tail` masque le code de sortie** de `flutter test` → capturer `echo "EXIT=$?"` avant le `tail`.
- Émulateur en GPU logiciel : pop-up « System UI isn't responding » possible → cliquer « Wait ».

---

## TODO connus (non bloquants)
- Marcellus n'a qu'une graisse (400) : les titres en `w600` rendent en régulier. OK esthétiquement ;
  bundler une 2ᵉ graisse si on veut du gras sur les titres.
- Le mode « seed » (`lib/dev/seed.dart`) est un outil dev — à retirer/garder selon besoin plus tard.
- Émulateur : laissé **allumé** en fin de session (`emulator-5554`) avec un `flutter run --dart-define=SEED=true`
  attaché. À rebooter demain si éteint entre-temps.

---

## Plan restant
```
✅ 0 scaffold  ✅ 1 bouton  ✅ 2 observation  ✅ 3 métriques  ✅ 4 Boss  ✅ 5 révélation
✅ 6 machine à états   ✅ 7 défi J4-7 (délai + notif)   ✅ 8 rechute   ✅ 9 sauvegarde chiffrée   ✅ 10 polish
```
Détail de chaque jalon : `PLAN.md` §8.
