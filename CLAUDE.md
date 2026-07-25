# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Nom & métaphore

L'app s'appelle **Cairn** (le dossier repo reste `Tabac-stop` ; le projet Flutter est `cairn`).
Le nom ne crie pas « anti-tabac » — atout pour le public ambivalent, qui peut l'ouvrir en soirée
sans se sentir catalogué.

**La métaphore gouverne tout le design et n'est pas décorative — elle encode les invariants du produit :**
- Chaque cigarette évitée / envie résistée **pose une pierre**. Le cairn monte.
- **Fumer ne fait JAMAIS tomber de pierre** — le cairn se met simplement en **pause**. C'est la
  traduction visuelle directe de l'invariant « le second compteur ne bouge pas » : la rechute
  n'entame jamais ce qui est déjà empilé.
- Le cairn **est** la mascotte non-culpabilisante : un tas de pierres ne tousse pas, ne meurt pas,
  ne fait pas la morale. **L'écran principal, c'est le cairn qui grandit** ; le reste est secondaire.
- Vocabulaire : *poser une pierre* · *palier de hauteur* · **« ton plus haut cairn »** (remplace le
  record d'écart max) · **altitudes = paliers santé** (« 1 000 m — 24 h sans monoxyde de carbone »).
- Un **Boss vaincu = un gros rocher qu'on parvient enfin à hisser en haut** du cairn.

## Statut du projet

**Cairn** est une app mobile **Flutter** de sevrage tabagique, **local-first, sans serveur**.
Le code n'est pas encore scaffoldé — la source de vérité actuelle est **`PLAN.md`** (archi complète,
modèle de données, algo de détection des Boss, machine à états du parcours, jalons) et
**`design/direction-artistique.html`** (identité visuelle, maquettes Écran 1 + Observation).
**Lire `PLAN.md` avant toute décision structurante.**

Stack verrouillée : **Flutter (Dart)** · state **Riverpod** · DB **drift** (SQLite typé) ·
notifications **flutter_local_notifications** + `timezone` · export chiffré **Argon2id +
XChaCha20-Poly1305**. **Aucun backend, aucun compte, aucune synchro.**

## Règle qui gouverne tout le produit (non-négociable)

> **L'app parle le moins possible, et JAMAIS quand l'utilisateur est en difficulté.**
> Elle ne parle que (1) quand il a réussi, (2) quand elle a un fait à lui révéler. Sinon = un bouton.

Conséquences concrètes à ne jamais violer :
- **Écran 1 = le bouton, déjà fonctionnel.** Aucun compte / objectif / date d'arrêt / « combien par jour ».
- **J1–3 : silence total.** L'app enregistre, ne propose rien. Elle donne la permission de fumer
  normalement (→ pas de culpabilité → pas de mensonge → données vraies).
- **Validation silencieuse** : le tap « je fume quand même » remet l'écran à zéro, chrono repart,
  **aucun texte, aucune consolation** (toute consolation implique une faute).
- **Rechute (arrêt net)** : le streak retombe à 0, mais **jours-propres cumulés** et **record
  d'écart max** ne bougent JAMAIS. Ne jamais casser cet invariant.
- **Ne jamais bloquer** l'utilisateur sur la question du mode (3ᵉ porte « je ne sais pas » toujours ouverte).
- Le premier badge = **premier délai tenu**, pas la première journée parfaite.

## Principes d'architecture

- **`lib/domain/` = Dart pur, zéro dépendance Flutter.** Toute la logique produit (détection des
  Boss, machine à états du parcours, calcul des métriques) y vit et est **testée unitairement**.
  Ces algorithmes *sont* le produit — c'est la couche à couvrir en priorité par les tests.
- **Journal append-only comme unique source de vérité** (`cigarettes` + `journey_events`). Tout le
  reste — chrono, médiane, streak, jours cumulés, record — est **dérivé**, jamais stocké comme
  vérité (un cache perf est permis, mais ne fait pas autorité). C'est ce qui rend la rechute
  triviale : on reset un compteur calculé, on ne perd aucune donnée.
- **Le tap normal et « je fume quand même » sont le MÊME événement** ; seuls les flags
  (`during_delay`, `was_boss`) diffèrent. La validation silencieuse est donc le comportement par
  défaut, pas un cas spécial.
- **Détection des Boss** : pré-requis **≥30 taps ET ≥3 jours** avant toute proposition (en dessous,
  un chiffre au hasard détruit la confiance). Si 72 h atteintes mais <30 taps → **prolonger
  l'observation en silence**, jamais de reveal pauvre. Fonction pure `List<Cigarette> → BossReport`,
  testée sur des **fixtures de faux fumeurs**. Un **mode seed debug** injecte des historiques
  synthétiques pour développer sans attendre 3 jours réels.
- **Nommer ≠ attaquer** : la révélation **nomme** le Boss le plus ancré (7 h 10) ; la cible J4
  **attaque** le plus fragile (creux d'après-midi) pour garantir une victoire. La copie du reveal
  ne promet jamais que le Boss nommé est la première cible.
- **Temps** : stocker `occurred_at_utc` + `tz_offset_min` ; clusteriser les Boss sur l'**heure
  murale locale**. Jour logique = **04:00 locale** (pas minuit) — impacte count/jour et jours cumulés.
- **Contexte du tap** : 3 icônes facultatives `☕ café · 🍽️ repas · 🍷 alcool` (ancrées dans le
  temps → nourrissent le contexte du Boss). Enum v1 `{cafe, repas, alcool}` sur `context_a`.

## Design

Ambiance **polynésienne** (sable / cocotier / lagon). La couleur suit la règle du produit :
le sable domine, l'accent **lagon** `#0E877F` ne sort que quand l'app **parle** (succès, révélation),
l'**hibiscus** `#CB5A38` est réservé au **Boss**. Deux thèmes dessinés (jour / nuit clair de lune),
jamais inversés. Palatino n'existant pas sur Android, embarquer une humaniste chaude
(*Fraunces* / *Marcellus* / *Gelasio*) via asset. Détails et hex : `design/direction-artistique.html`.

## Commandes (une fois le projet scaffoldé)

```bash
flutter pub get                      # dépendances
dart run build_runner build --delete-conflicting-outputs   # codegen drift + riverpod
flutter run                          # lancer sur device/émulateur
flutter analyze                      # lint / analyse statique
dart format .                        # formatage

flutter test                         # toute la suite
flutter test test/domain/            # les tests domaine (Boss, métriques, state machine)
flutter test test/domain/boss_test.dart               # un fichier
flutter test test/domain/boss_test.dart --name "café" # un test précis
```

Priorité de build : **Jalon 1 (le bouton) avant tout le reste** — latence nulle, haptique, chrono
immédiat. Ordre complet des 11 jalons dans `PLAN.md` §8.
