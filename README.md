<div align="center">
  <img src="design/branding/icon.png" width="112" alt="Cairn" />
  <h1>Cairn</h1>
  <p><em>Une app de sevrage tabagique qui parle le moins possible.</em></p>
  <p>
    <a href="https://github.com/syoul46/Tabac-stop/releases/latest"><img src="https://img.shields.io/github/v/release/syoul46/Tabac-stop?label=release" alt="Release" /></a>
    <img src="https://img.shields.io/badge/Flutter-local--first-0E877F" alt="Flutter local-first" />
    <img src="https://img.shields.io/badge/serveur-aucun-3A3A38" alt="Aucun serveur" />
  </p>
</div>

---

## L'idée

La plupart des apps anti-tabac culpabilisent, comptent les jours parfaits, et parlent trop.
**Cairn fait l'inverse.** Elle part d'un principe unique :

> **L'app parle le moins possible, et JAMAIS quand tu es en difficulté.**
> Elle ne parle que (1) quand tu as réussi, (2) quand elle a un fait à te révéler. Sinon, c'est un bouton.

Chaque envie résistée **pose une pierre**. Le cairn — le tas de pierres — monte.
**Fumer ne fait jamais tomber de pierre** : le cairn se met simplement en pause. Un tas de pierres
ne tousse pas, ne meurt pas, ne fait pas la morale.

## Comment ça marche

1. **Écran 1 = le bouton.** Pas de compte, pas de date d'arrêt, pas de « combien par jour ». Tu tapes quand tu fumes. C'est tout.
2. **Jours 1 à 3 : silence total.** L'app observe et enregistre, ne propose rien. Elle te laisse fumer normalement — donc pas de culpabilité, pas de mensonge, des données vraies.
3. **La révélation.** Après ≥ 3 jours et assez de données, l'app te **nomme ton « Boss »** — la cigarette la plus ancrée (ex. *« le Café de 7 h 10 »*) — et te propose une première cible atteignable.
4. **Le parcours.** Réduction en douceur (un délai à tenir avant chaque cigarette) ou arrêt net, au choix — et une 3ᵉ porte « je ne sais pas » toujours ouverte.
5. **La rechute ne casse rien.** Le streak retombe, mais les jours propres cumulés et ton plus haut cairn **ne bougent jamais**.

## Confidentialité

**Aucun compte. Aucun serveur. Aucune synchronisation.** Toutes tes données restent sur ton
téléphone, dans une base locale. Un export **chiffré** (Argon2id + XChaCha20-Poly1305) te permet de
les sauvegarder toi-même.

> Seule connexion réseau de l'app : la **vérification des mises à jour**, qui interroge l'API
> publique de GitHub pour comparer les versions. Aucune donnée personnelle n'est transmise ; le
> bandeau peut être ignoré.

## Installation — Android

Télécharge l'APK depuis la **[page des releases](https://github.com/syoul46/Tabac-stop/releases/latest)** :

| Fichier | Pour |
|---|---|
| `cairn-x.y.z-arm64-v8a.apk` | la quasi-totalité des téléphones récents |
| `cairn-x.y.z-armeabi-v7a.apk` | appareils plus anciens (32 bits) |

Au premier install hors Play Store, Android affiche un avertissement « appli inconnue » →
autorise l'installation. L'app est signée avec une clé de release (pas de blocage Play Protect).
Une fois installée, elle te **signalera elle-même** les futures mises à jour.

## Installation — iPhone (expérimental)

Cairn ne passe **ni par l'App Store, ni par TestFlight**. La CI produit un
`cairn-x.y.z-unsigned.ipa` — un binaire **non signé**, que tu signes toi-même avec ton propre
Apple ID (un compte **gratuit** suffit, pas besoin des 99 $/an).

> **Un `.ipa` ne s'installe pas en le téléchargeant sur le téléphone.** Ce n'est pas un APK :
> iOS refuse tout binaire non signé. Il te faut un ordinateur, au moins la première fois.

1. Sur un **PC Windows ou un Mac** : installe **[Sideloadly](https://sideloadly.io)** (gratuit).
2. Branche l'iPhone en USB, glisse le `.ipa`, saisis ton Apple ID.
3. Sur l'iPhone : **Réglages → Général → VPN et gestion de l'appareil** → fais confiance au
   certificat qui vient d'apparaître.
4. iOS 16+ : active **Réglages → Confidentialité et sécurité → Mode développeur**, puis redémarre.

**L'app cesse de fonctionner au bout de 7 jours** et doit être re-signée — c'est la limite des
comptes Apple gratuits (3 apps maximum, aussi). [AltStore](https://altstore.io) automatise ce
rafraîchissement en WiFi ; Sideloadly non.

### Ce que tu dois savoir avant d'essayer

Le build iOS est vérifié **à chaque commit** sur un simulateur : il compile, il démarre, il
enregistre en base, et la demande de permission de notification atteint bien le système. Mais
**personne n'a jamais fait tourner Cairn sur un vrai iPhone** — il n'y en a pas dans l'équipe.
En particulier, *qu'une notification s'affiche réellement à l'heure dite* n'est pas vérifié.

Sur iPhone, l'app ne signale pas ses mises à jour (iOS ne permet aucune installation hors
App Store) : il faut repasser par la [page des releases](https://github.com/syoul46/Tabac-stop/releases/latest).

## Pour les développeurs

App **Flutter** (Dart), local-first. Toute la logique produit vit dans `lib/domain/` en **Dart pur**
(zéro dépendance Flutter) et est testée unitairement — c'est là que sont la détection des Boss
(DBSCAN 1D), la machine à états du parcours et le calcul des métriques.

- **State** : Riverpod · **DB** : drift (SQLite typé) · **Notifs** : flutter_local_notifications + timezone
- **Journal append-only** comme unique source de vérité ; tout le reste (chrono, streak, médiane) est **dérivé**.

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # codegen drift
flutter run                                                 # sur device/émulateur
flutter test test/domain/                                   # logique pure (~4 s)
flutter build apk --release --split-per-abi                 # APK signés
```

Architecture complète, modèle de données et jalons : **[`PLAN.md`](PLAN.md)**.
Règles produit non-négociables : **[`CLAUDE.md`](CLAUDE.md)**.

## Licence

Projet personnel. Tous droits réservés (pour l'instant).
