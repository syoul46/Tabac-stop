# Journal de développement — Cairn

> App de sevrage tabagique, Flutter, **local-first**. Source de vérité produit : `PLAN.md`.
> Conventions & règles non-négociables : `CLAUDE.md`. Ce journal = où on en est / comment reprendre.

---

## Point de reprise — 2026-08-11 (session 6 : « Recommencer l'observation »)

**Ajouté** : un bouton discret sur l'écran d'observation qui **efface toutes les cigarettes et
repart de zéro**. Cas d'usage réel : on découvre l'app, on oublie de taper les premiers jours →
le portrait est faux → le Boss nommé serait faux. Spec : **`PLAN.md` §4**.

- `JourneyEventKind.observationReset` (payload `{deleted}`) + `CigaretteRepository.resetObservation()`
  — suppression et trace dans **la même transaction** (un journal vidé sans trace = trou d'histoire).
- **Visible seulement tant que `mode == null`.** Après le choix d'un mode, le journal porte les
  jours-propres cumulés et le record d'écart max : pas de bouton de correction qui puisse y toucher.
- Confirmation explicite avec le nombre en clair, copie factuelle (aucun « tu as oublié de taper » :
  personne n'a fauté). Jamais proposé par l'app d'elle-même.
- `resolvePhase` renvoie `firstLaunch` sur journal vide → l'app revient d'elle-même à l'Écran 1,
  sans code de transition dédié.
- **107 tests verts** (2 nouveaux sur `resetObservation`), `flutter analyze` propre.
  **Non vérifié sur émulateur/appareil** à ce stade.

**Aussi : « Annuler » manquait dans les modes.** Il n'existait que sur l'écran d'observation —
absent en **réduction** (où la cigarette resoigne le Boss de +1 PV) et en **arrêt net** (où un
mis-tap remet le streak à 0, le plus coûteux des trois). Extrait en composant partagé
`features/tap/undo_last_button.dart`, câblé en observation + réduction. **Arrêt net reste à faire**
— même défaut, une ligne, mais hors de la demande.

---

## Point de reprise — 2026-08-10 (session 5 : **iOS**, le dernier écart au plan)

**État : le trou iOS est bouché.** Cairn compile, démarre, enregistre et parle à iOS — vérifié
**en CI à chaque run**, sans Mac ni iPhone. Spec complète : **`PLAN.md` §17**. Rien n'est publié :
aucune release touchée, l'`.ipa` vit en artefact de run.

**Dernier run vert : [31364435969](https://github.com/syoul46/Tabac-stop/actions/runs/31364435969)**
— `build` 5 min, `smoke` 14 min, 2 tests d'intégration passés. **11 commits sur `main`**
(`a16ecb6` → `afb1da2`), arbre propre, tout poussé. Jalons **iOS-A → iOS-E tous faits** :
`ios/Podfile` versionné (`platform :ios, '13.0'`) · notifications iOS câblées · workflow `.ipa` ·
smoke + `integration_test` · README/PLAN/JOURNAL.

### Les deux murs, et comment ils tombent
- **Compiler** : impossible sous Linux → **runner `macos-latest` GitHub Actions, gratuit pour un
  repo public**. Build complet en ~6 min.
- **Installer** : iOS n'a **aucun** équivalent d'« autoriser les sources inconnues » → l'utilisateur
  re-signe l'`.ipa` avec son **Apple ID gratuit** (Sideloadly / AltStore). **Expire à 7 jours.**
  Décidé : ni App Store ni TestFlight, jamais.

### Ce que la CI prouve maintenant (`.github/workflows/ios.yml`, 2 jobs)
- `build` → `cairn-x.y.z-unsigned.ipa` (`Runner.app` 23,7 Mo), attaché à une release **seulement si
  elle existe déjà** — le workflow n'en crée jamais une.
- `smoke` → boot d'un iPhone simulé, install, lancement, captures, **puis `integration_test`** :
  taper le galet fait apparaître le chrono « depuis la dernière » (donc **écriture + relecture
  SQLite**), et `scheduleDelayEnd` fait apparaître le dialogue *« Cairn » Would Like to Send You
  Notifications* (donc **le câblage Darwin atteint iOS**).

### Le vrai trou fonctionnel trouvé en route
`notification_service.dart` ne passait qu'un `AndroidInitializationSettings` : l'app se serait
lancée sur iPhone **muette sur les fins de délai**. Corrigé (§17.3 iOS-B). Choix à retenir :
**rien n'est demandé au lancement** (permission réclamée au premier délai), **pas de badge**, et
**aucune modif d'`AppDelegate`** — le plugin s'enregistre lui-même comme délégué
`UNUserNotificationCenter`, ce qui est précisément ce qui fait marcher l'affichage au premier plan.

### Pièges rencontrés (à ne pas refaire)
- `xcrun simctl launch --console-pty` **exige un vrai tty**, absent en CI : il ne lance rien et ne
  dit rien. Lancé en arrière-plan avec `&`, son échec passe totalement inaperçu — les captures
  montraient le bureau d'iOS et on croit à un plantage de l'app. Logs : `simctl spawn log stream`.
- `pumpAndSettle` est **inutilisable** sur l'Écran 1 : le chrono planifie une frame par seconde,
  l'arbre ne se pose jamais → helper `pumpUntil` dans `integration_test/parcours_test.dart`.
- Sur iOS, `requestPermissions` ne se résout **qu'après** la réponse de l'utilisateur au dialogue
  système. Un `await` en CI = test figé. On déclenche sans attendre, et la preuve est visuelle.
- **Les macros `permission_handler` (toutes les permissions à `0`) dans `post_install` bloquent
  `integration_test`** : l'app démarre normalement, mais le **test host reste sur le splash**, Dart
  ne démarre jamais et `flutter test` attend indéfiniment. Reproduit 2 runs de suite, vert sans.
  Le bloc s'applique à **tous** les pods, celui d'`integration_test` compris. Retiré ; commentaire
  d'avertissement laissé dans `ios/Podfile`.
- `gh run watch` peut mourir sur une coupure réseau (`error connecting to api.github.com`) : son
  code de retour ne veut alors **pas** dire « le run a échoué ». Vérifier l'état réel du run.

### Ce qui reste
- **Non prouvé faute d'iPhone** : qu'une notification s'affiche vraiment à l'heure dite (personne ne
  peut taper « Allow » depuis `simctl`), le partage, l'import de sauvegarde.
- **Dettes** : `Podfile.lock` non versionné (ingénérable hors macOS) ; `open_filex` ne supporte pas
  Swift Package Manager — warning aujourd'hui, **erreur demain**, pour un plugin qui ne sert qu'au
  chemin d'update Android → le rendre Android-only.
- À décider : joindre l'`.ipa` à une release publique, ou le transmettre à la main.

---

## Point de reprise — 2026-08-06 (session 4b : §15 combat **v2** — régularité)

**État : §15 recodé en v2 (exigence de régularité) — codé, testé, vérifié sur émulateur, et
PUBLIÉ en `v1.6.0`** (« le combat des Boss »). **105 tests verts**, `flutter analyze` propre.
Release : 2 APK signés `cairn-1.6.0-{arm64-v8a,armeabi-v7a}.apk`, tag `v1.6.0`, marquée Latest.

### §15 v2 — la victoire se gagne par JOURS, à l'heure du Boss
Décidé avec le user : le combat v1 (compteur d'événements, 3 délais n'importe quand) ne prouvait pas
le changement d'habitude. v2 recale sur la **régularité**.
- `PV = clamp(PVmax − joursEntamés + joursCraqués, 0, PVmax)`, PVmax = **jours** (3/4/5).
  - **jour entamé** = ≥1 délai tenu dans la fenêtre du Boss (**± 30 min**, `kBossWindowMin`) → −1 PV, 1×/jour.
  - **jour craqué** = ≥1 cigarette dans la fenêtre → +1 PV (le Boss se resoigne, silencieux).
  - jour neutre = pause. Tout **dérivé des horodatages** (heure murale + `LogicalDay`), plus de tag `bossKey`.
- `victory.dart` : `bossHp(boss, cigs, events)`, helpers `bossWindowContains`/`daysEngaged`/`daysCracked`/
  `engagedToday` ; signatures `defeatedBossKeys`/`pendingBossVictory`/`isBossDefeated` en `(…, cigs, events)`.
- **Pierres bonus** : tenir au-delà des 10 min → +1 à 20 min, +1 à 30 min (plafond +2/manche). Event
  `bonusStone`, `stonesPlaced` les compte, `pendingBonusStones` (pur) calcule le reste, le ticker émet.
  Vérifié live : 5 → 8 pierres. Ces pierres ne touchent JAMAIS les PV du Boss.
- **UI** : bandeau cible « entamé aujourd'hui ✓ — reviens demain » (`engagedToday`) ; bandeau **descendu
  à 52 px** (il chevauchait les icônes stats/règle/sauvegarde) ; **pulse en fenêtre horaire** (le bandeau
  respire + « c'est le moment — retarde-le » quand on est dans les ± 30 min du Boss, pas encore entamé).
- **Nettoyage** : `markDelayHeld()`/`markDelayBroken()` sans paramètre.

### ⚠️ Piège formatage (à retenir)
`dart format .` de l'environnement local applique le **nouveau « tall style »** et reformate **tout
l'arbre** (49 fichiers de churn). Ne PAS le lancer en global tant que le repo est sur l'ancien style :
formater à la main / n'éditer que les fichiers touchés. J'ai dû `git checkout HEAD -- .` puis
réappliquer les changements à la main.

---

## Point de reprise — 2026-08-06 (session 4 : §15 combat de Boss codé v1)

**État : §15 (combat de Boss par PV) codé et vérifié sur émulateur, non publié.** On reste en
phase de fix (pas de release sans demande explicite). 93 tests verts, `flutter analyze` propre.

### §15 — combat de Boss (PV, délais relançables, personnage)
- **Domaine** (`domain/boss/victory.dart`) : `bossMaxHp` (fragile 3 / tenace 4 / coriace 5),
  `healsForBoss`, `bossHp = clamp(PVmax − délais tenus + cigarettes, 0, PVmax)`, `isBossDefeated`.
  `defeatedBossKeys`/`pendingBossVictory` passés en signature `(BossReport, events)`, basés PV.
- **Délai « par manche »** (`domain/journey/delay.dart`) : relançable, plus de « 1/jour ».
- **UI** : `features/boss/boss_face.dart` (rocher grognon hibiscus + `BossHpBar`) ; bandeau cible
  en réduction (visage + PV) ; `_onTapStone` soigne le Boss via `markDelayBroken(bossKey:)` (silencieux).
- **Callers recâblés** : stats, arrêt net (`bossReportProvider`), reveal de victoire.

### Correctif clé — « le délai ne fonctionnait pas »
Le message de succès « délai tenu · pierre posée » était **du code mort** : `resolveDelay` ne
renvoyait jamais `held`, donc à l'expiration **rien ne « parlait »** (le compte à rebours
disparaissait, la barre de PV baissait en silence). → `resolveDelay` renvoie maintenant `held`/`broken`
pendant une **fenêtre de 6 s** (`kDelayFeedbackWindow`) après une manche close, puis `available`.

### Outils de test / robustesse
- `kDelayLength` réglable via `--dart-define=DELAY_SECONDS=N` (défaut 600 s). **Ne pas publier un
  APK buildé avec l'override.** Testé bout-en-bout à 10 s sur l'ému.
- `tap_screen` : colonne centrale scrollable si écran court (corrige un overflow du widget test).
- Prévisu dev : `SCREEN=combat` (rend `ReductionHome`).
- « La règle du jeu » : section combat développée (visuel Boss + PV, nomme ≠ attaque, PV 3/4/5,
  relançable, victoire = rocher hissé définitif).

### Reste
- iOS (inchangé). Backlog produit : PLAN §16 (« ce que tu as évité », compagnon de respiration…).
- Ne pas oublier : `boss_face.dart` réutilisé par la règle du jeu (`_BossDemo`) et le bandeau réduction.

---

## Point de reprise — 2026-08-05 (session 3, suite : v1.5.1)

**État : le produit décrit par le PLAN est intégralement codé (jalons 0→14). Dernière release
publiée : `v1.5.1`.** Seul vrai écart au plan restant : **iOS** (jalon 0 disait « build iOS+Android » ;
seul Android est configuré/signé/testé). Changelog complet : `CHANGELOG.md`.

### v1.5.1 (correctifs)
- **Bandeau de mise à jour** qui s'affichait **à la verticale** sur écran étroit → **pleine largeur**
  (`update_banner.dart`, `left/right:8`, message sur sa propre ligne) + **résumé condensé du changelog**
  (têtes de puces de `info.notes`). ⚠️ cause du bug : un `Text` dans une `Row` réduit à ~0 de large.
- **« Annuler »** (undo tap) désormais **persistant** (plus de fenêtre 15 s) + **confirmation** avant suppression.
- Observation au-delà de la fenêtre → « **Jour 8 — on observe** » (`dayIndex` déplafonné).
- Prompt de sauvegarde → **vrai nombre de jours** (`distinctLogicalDays`, plus « 3 » en dur).
- Dédicace dans le footer (`version_tag.dart`).

### v1.5.0 (retours de test → un lot publié)
- **Fenêtre d'observation = 7 jours RÉELS** : `shouldReveal(cigs, now)` = `≥30 taps` ET
  `now − 1ʳᵉ cigarette ≥ 168 h` (`kObservationDays=7` dans `reveal_gate.dart`) — plus un compteur de
  jours calendaires (commencer à 23 h ne triche plus). `resolvePhase` prend `now`. Copie : « Jour X
  sur 7 », « Voilà ta semaine », règle du jeu, seed 8 j, CLAUDE.md/PLAN (palier santé « 72 h » intact).
- **Revoir la révélation / changer d'approche** (PLAN §15 option A) : `RevealScreen(revisit:true)`
  (titre « Où tu en es », appbar « Changer d'approche », `setMode` + `popUntil` racine) ; bouton dans
  les **stats** ; corrige l'impasse « je ne sais pas ».
- **Annuler le dernier tap** : `undoLastCigarette()` + bouton « Annuler » 15 s après un tap (Écran 1).
- **Repères horaires** 0h/4h/8h/12h/16h/20h sous la courbe (`HourlyCurve`, écran principal + stats).
- **Réduction** : chrono « depuis la dernière » **toujours affiché** (même pendant un délai / tenu).
- Libellé du prochain palier d'altitude clarifié.
- ⚠️ Piège Flutter rencontré : `OverflowBox` **sans hauteur bornée** → overflow « Infinity PIXELS ».
  Toujours borner (`maxHeight` / `SizedBox`).

### Ajustements v1.4.1 (retours de test sur vrai téléphone)
- **Icônes** (stats / aide / bouclier) : opacité 0.35 → **0.55** ; bandeau « Jour X/3 » descendu sous
  la rangée d'icônes (plus de chevauchement).
- **Écran « règle du jeu »** : conditions de la révélation détaillées (**3 jours ET ≥ 30 cigarettes**),
  petit rendu **gras** des `**…**` ajouté.
- **Paliers santé** : +2 paliers (**2 h**, **12 h**) et faits affinés (NHS/CDC/AHA) ; ils **se rejouent**
  après une rechute (`revealedMinutesSince(events, dernièreCigarette)` — on ne compte que depuis le
  dernier tap). Le « plus haut cairn » garde le record.
- **Mini-cairn d'observation** : **une seule pierre-graine fixe** (ne grandit plus par jour — c'était
  trompeur : en J1-3 on ne résiste à rien) et **recentrée** avec le chrono (ne flotte plus en haut).
- Rappel vérifié : le **chrono « depuis la dernière » est juste** (diff d'instants absolus, insensible
  au fuseau) ; le cairn ne peut pas déborder (pierres rétrécies pour tenir dans un cadre fixe).

### Ce qui a été ajouté après l'auto-update
- **Jalon 11 — paliers santé** (`domain/health/milestones.dart`, testé) : altitudes = faits
  physiologiques (NHS/CDC) déclenchés par l'abstinence continue ; reveal **une-fois** via event
  `milestoneRevealed` (une rechute ne re-révèle pas). Altitude affichée sous le streak (arrêt net).
- **Jalon 12 — cairn dessiné + victoire de Boss** :
  - `features/cairn/cairn_view.dart` = **CustomPainter** (galets Bézier bruités de façon
    déterministe, dégradé minéral, ombres). Visuel héros en arrêt net (1 pierre de fondation + 1 par
    palier) et en réduction (1 par délai tenu).
  - `domain/boss/victory.dart` (testé) : tenir **3 délais** sur un Boss (`kBossVictoryHolds`) le
    **vainc** ; délai tenu tagué `bossKey` sur `delayHeld` ; cible = `nextTarget` (plus fragile non
    vaincu). Reveal `bossDefeated` **une-fois** (`BossVictoryReveal`), rocher **hibiscus** hissé au
    sommet — visible en arrêt net **et** réduction, ne retombe jamais.
- **Jalon 13 — vie & stats** :
  - **Animations** : la pierre **tombe** (easeOutBack + fondu, ~560 ms) ; le **rocher de Boss est
    hissé depuis le bas** ; **poussière** sable à l'atterrissage (pas pour le rocher).
  - **Haptique** : `lightImpact` au calage d'une pierre (`CairnView`, flag `haptics`), `heavyImpact`
    au rocher de Boss (via le reveal, pour éviter le double). Coupée en observation.
  - **Mini-cairn en observation** : silencieux, 1 pierre par jour (`TapScreen`).
  - **Écran stats** (`features/stats/stats_screen.dart`), ouvert par l'icône `bar_chart` (haut-gauche,
    dans `_WithBackupAccess`) : rythme, cumul (dont « plus haut cairn », Boss vaincus), altitude,
    courbe horaire, liste des Boss (le vaincu barré). **Tout dérivé, rien stocké.**
- **Jalon 14 — aide / règle du jeu** (`features/help/how_it_works_screen.dart`) : écran ouvert par
  l'utilisateur qui explique tout (silence, bouton, observation, révélation, cairn, Boss, altitudes,
  confidentialité). Accès : lien « Comment ça marche ? » sur l'Écran 1 + icône `?` (haut-gauche, à
  côté des stats). Bandeau MAJ décalé à `left:100` pour laisser la place aux deux icônes de gauche.

### Vérif visuelle (émulateur `warren-x86_64`, GPU logiciel)
Previews dev pratiques (overrides Riverpod, pas besoin de vraies données ni de navigation) :
```bash
flutter run -t lib/dev/cairn_preview.dart                              # cairn interactif (pose)
flutter run -t lib/dev/screens_preview.dart --dart-define=SCREEN=stats # écran stats
flutter run -t lib/dev/screens_preview.dart --dart-define=SCREEN=obs   # mini-cairn observation
flutter run -t lib/dev/screens_preview.dart --dart-define=SCREEN=dust  # poussière (auto-chute)
flutter run -t lib/dev/screens_preview.dart --dart-define=SCREEN=help  # écran « règle du jeu »
```
⚠️ L'émulateur en GPU logiciel jette des ANR (« System UI isn't responding » → *Wait*) et **ignore
parfois le tactile** ; pour capturer un écran précis, l'afficher direct via `--dart-define` plutôt que
naviguer au tap. Filmer : `adb shell screenrecord --time-limit N /sdcard/x.mp4`.

### Releases de cette session
`v1.0.0` → `v1.4.0`. Cadence : v1.0.x = signature + itérations auto-update ; v1.1.x = paliers +
cairn dessiné ; v1.2.x = victoire de Boss + animations + haptique ; v1.3.0 = stats + mini-cairn +
poussière ; **v1.4.0 = écran « règle du jeu »**. Upload d'assets via `gh` : si `gh release create`
timeoute pendant l'upload, créer la release puis `gh release upload v<x> <apk> --clobber` séparément.

### Pistes restantes
**iOS** (le seul écart au plan) · CI · sauvegarder le keystore hors machine · tuning réel des seuils
Boss (vraie beta) · rendre l'auto-update **manuel** (option) · son discret optionnel.

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

**iOS — tout passe par la CI** (aucun build iOS possible sous Linux, cf. `PLAN.md` §17) :
```bash
gh workflow run ios.yml --ref main            # build .ipa + smoke simulateur (~15 min)
gh run list --workflow=ios.yml --limit 3      # suivre
gh run download <run-id> -n cairn-1.6.0-unsigned.ipa -D /tmp/ipa   # récupérer le binaire
gh run download <run-id> -n smoke-simulateur  -D /tmp/smoke        # captures + logs du smoke
```
`gh run watch` meurt sur une coupure réseau : préférer une boucle qui interroge
`gh run view <id> --json status`. Le job `smoke` dure ~14 min ; au-delà de 20, quelque chose
est bloqué → regarder la **dernière capture** de `captures/`, c'est elle qui parle.

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
✅ iOS A→E (Podfile · notifications · workflow .ipa · smoke simulateur · doc)
```
Détail de chaque jalon : `PLAN.md` §8. iOS : **`PLAN.md` §17**.

**Reste sur iOS** : rien ne prouve qu'une notification s'affiche vraiment à l'heure dite (personne
ne peut taper « Allow » depuis `simctl`), ni le partage, ni l'import de sauvegarde — il faut un
iPhone. Dettes : `Podfile.lock` non versionné ; `open_filex` sans support Swift Package Manager
(warning aujourd'hui, erreur demain) alors qu'il ne sert qu'au chemin d'update Android.
