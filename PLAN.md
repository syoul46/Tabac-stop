# Plan de développement — Tabac-stop

> App de sevrage tabagique **local-first**, gouvernée par une règle unique :
> **l'app se tait le plus possible, et ne parle jamais quand l'utilisateur est en difficulté.**
> Elle parle seulement (1) quand il a réussi, (2) quand elle a un fait à lui révéler sur lui-même.
> Le reste du temps, elle est **un bouton**.

## 0. Décisions verrouillées

| Sujet | Choix |
|---|---|
| Stack | **Flutter** (Dart), un codebase iOS + Android |
| State | **Riverpod** |
| DB locale | **drift** (SQLite typé) |
| Notifications | **flutter_local_notifications** + `timezone` |
| Données | **100% local, aucun serveur.** Sauvegarde = export chiffré manuel |
| Crypto export | Passphrase → **Argon2id** → **XChaCha20-Poly1305** (`cryptography` / `sodium`) |
| Compte / sync | **Aucun.** Remplacé par la sauvegarde chiffrée au J4 |

**Principe d'architecture n°1** : toute la logique produit (détection des Boss, machine à états
du parcours, calcul des métriques) vit dans une couche **`domain/` en Dart pur, sans dépendance
Flutter**, donc entièrement testable unitairement. Ces algorithmes *sont* le produit.

---

## 0 bis. Direction artistique — le cairn

Nom = **Cairn**. La métaphore n'est pas un habillage, c'est **la visualisation centrale du produit**
(cf. `CLAUDE.md` § Nom & métaphore). **L'écran principal EST le cairn qui grandit** : chaque pierre
= une cigarette évitée / une envie résistée. **Fumer ne fait jamais tomber de pierre — le cairn se
met en pause.** C'est l'invariant « le second compteur ne bouge pas », rendu visible. Le bouton de
tap et le cairn ne font qu'un : on tape *dans* la scène du cairn.

Ambiance : cairn de **pierres de basalte** posé sur le **sable chaud** d'une plage polynésienne
(les îles sont volcaniques → la synthèse est naturelle). **Une plage calme = une app qui se tait.**

### Palette (refonte minérale, ✅ imposée par le nom)
| Rôle | Nom | Hex (jour) | Usage |
|---|---|---|---|
| Fond | Sable | `#E7D5B6` | la plage, domine |
| Pierres | Basalte | `#3A3A38` / `#565450` | le cairn (gris minéral) |
| Terre | Ocre | `#B0743F` | pierres chaudes, paliers |
| **Accent** | **Vert discret** | `#4E7A5A` | **la voix de l'app — rare** (pierre posée, palier atteint) |
| Texte | Basalte foncé | `#241F19` | corps |

**Contraintes du nom, non-négociables** : **zéro rouge**, **zéro picto médical**, **zéro cigarette
barrée**. Ça nous démarque de tout le secteur (clinique ou criard). L'**hibiscus/corail** des
maquettes précédentes **saute** : le Boss n'est plus une alerte rouge, c'est **un gros rocher**
distinct qu'on hisse en haut du cairn.

> **⚠️ Décision d'accent à confirmer** : le brief du nom dit « un vert discret ». J'adopte donc le
> **vert** comme accent de « la voix de l'app », et je **retire le lagon turquoise** des maquettes
> précédentes. Si tu tenais au lagon (le moment « l'app parle pour la 1ʳᵉ fois » à la révélation),
> on peut le garder comme *unique* highlight rare de l'eau — à trancher. Par défaut : tout-minéral + vert.

### Vocabulaire (dérivé de la métaphore)
*poser une pierre* · *palier de hauteur* · **« ton plus haut cairn »** (= record d'écart max) ·
**altitudes = paliers santé** (« 1 000 m — 24 h sans CO ») · **Boss vaincu = gros rocher hissé**.

### Typo & matière
- **Display** : humaniste chaleureuse type *Palatino* (Android → embarquer *Fraunces*/*Marcellus*).
- **Chrono / chiffres** : `tabular-nums`, graisse légère.
- **Motif** : trame minérale/tapa quasi invisible. Aucune animation ne commente jamais ; poser une
  pierre est le seul mouvement franc.

> **Maquettes** : `design/direction-artistique.html` et `design/revelation-j3.html` datent d'AVANT
> le nom (palette lagon + hibiscus). **À refondre** vers la palette minérale + le cairn comme écran
> principal une fois l'accent tranché.

### Palette (jour)
| Rôle | Nom | Hex | Usage |
|---|---|---|---|
| Fond | Sable | `#E7D5B6` | domine partout |
| Structure | Cocotier | `#33543E` | texte d'accent, courbe, bordures |
| Texte | Basalte | `#241F19` | corps |
| **Accent** | **Lagon** | `#0E877F` | **la voix de l'app — rare** (succès, reveal) |
| Alerte | Hibiscus | `#CB5A38` | **le Boss — plus rare encore** |
| Highlight | Tiaré | `#FCF7EC` | face du bouton, reflets |

**Nuit** = lagon au clair de lune (fond `#141D1C`, texte sable, palme/lagon éclaircis).
Les deux thèmes sont **dessinés**, jamais inversés.

### Typo & matière
- **Display** : humaniste chaleureuse type *Palatino* (« le Café de 7 h 10 »).
- **Chrono / chiffres** : `tabular-nums`, graisse légère.
- **Texte / UI** : `system-ui`.
- **Motif tapa** (barkcloth) en trame quasi invisible — jamais bavard.
- **Le bouton = un galet chauffé par le soleil** : dégradé radial, halo doux, anneau tressé
  en pointillé. Un seul appui, enfoncement franc. **Aucune animation ne commente jamais.**

> Contrainte Flutter : Palatino n'existe pas sur Android → embarquer une alternative humaniste
> chaude via `google_fonts`/asset (ex. *Gelasio*, *Marcellus* ou *Fraunces*) dans le thème.

---

## 1. Modèle de données (le journal d'événements)

Le cœur est un **journal append-only**. Tout le reste est **dérivé** (rien de calculé n'est la
source de vérité). Deux tables drift.

### `cigarettes` — chaque cigarette réellement fumée
Un tap = « j'ai fumé maintenant ». Le tap normal et le « je fume quand même » produisent le
**même** événement ; seuls les flags diffèrent.

| Colonne | Type | Note |
|---|---|---|
| `id` | TEXT (uuid) | |
| `occurred_at_utc` | INTEGER (epoch ms) | source de vérité temporelle |
| `tz_offset_min` | INTEGER | pour reconstituer l'heure murale locale |
| `context_a` | INTEGER? | icône contexte 1 (optionnelle) |
| `context_b` | INTEGER? | icône contexte 2 (optionnelle) |
| `context_c` | INTEGER? | icône contexte 3 (optionnelle) |
| `was_boss` | BOOL | cette clope ciblait-elle le Boss du jour |
| `during_delay` | BOOL | fumée pendant un délai actif = « je fume quand même » |

> **3 icônes de contexte** (✅ tranché) : `☕ café` · `🍽️ repas` · `🍷 alcool`. Choisies parce
> qu'elles sont **ancrées dans le temps** → elles nourrissent le `contexte_dominant` d'un Boss et
> son nommage (« le Café de 7 h 10 », « la clope de l'apéro »). Facultatives, tapables en 1 s,
> jamais bloquantes. Enum figée v1, extensible. Enum : `{ cafe, repas, alcool }` sur `context_a`
> (les colonnes `context_b/c` restent réservées pour d'éventuelles familles futures).

### `journey_events` — cycle de vie du parcours
| Colonne | Type | Note |
|---|---|---|
| `id` | TEXT | |
| `occurred_at_utc` | INTEGER | |
| `kind` | TEXT enum | `mode_changed`, `boss_assigned`, `delay_started`, `delay_held`, `delay_broken`, `badge_earned`, `relapse`, `reveal_shown` |
| `payload` | TEXT (json) | données spécifiques (id du boss, mode cible, etc.) |

### Dérivés (calculés, jamais stockés comme vérité)
Temps depuis la dernière · nombre aujourd'hui · intervalle médian glissant · moyenne/jour ·
histogramme horaire (créneau chargé) · streak · jours-propres cumulés · record d'écart max.
Certains peuvent être **cachés** en table `metrics_cache` pour la perf, jamais faisant autorité.

**✅ Tranché** : le « jour » logique commence à **04:00 locale** (pas minuit) — pour ne pas couper
les gros créneaux du soir en deux. Une clope à 1 h du matin compte donc sur la journée de la veille.
Impacte `count/jour` et `jours-propres cumulés`.

---

## 2. Détection des Boss (l'algorithme central)

Un **Boss** = une cigarette qui **revient chaque jour à peu près à la même heure**, idéalement
liée à un contexte. C'est ce qui rend la révélation J+3 impossible à obtenir ailleurs.

### Pré-requis (✅ tranché)
- **≥ 30 taps** ET **≥ 3 jours** de données. En dessous : aucune proposition (chiffre au hasard
  = perte de confiance). C'est la raison technique de la phase d'observation.
- Si les 72 h sont atteintes mais **< 30 taps** (petit fumeur) : on **prolonge l'observation en
  silence** — pas de reveal pauvre. Message inchangé (« on observe »), pas d'échec affiché.

### Algorithme
1. Pour chaque clope, calculer l'**heure murale locale** (minutes depuis minuit) sur N jours
   glissants (via `occurred_at_utc` + `tz_offset_min`).
2. **Clustering 1D** sur l'axe temps-de-la-journée, type DBSCAN :
   `eps ≈ 25 min`, `minPts = ceil(0.6 × N_jours)`.
3. Chaque cluster = candidat Boss :
   `{ heure_centre, dispersion(std), jours_présents, occurrences, contexte_dominant }`.
4. **Score d'ancrage** `anchor = (jours_présents / N_jours) × (1 − std_normalisé) × cohérence_contexte`.
5. **Difficulté** (pour choisir la cible J4) :
   - **Dur** : centre ∈ [06:00–09:00] (1ʳᵉ du matin), OU contexte alcool/social, OU ancrage très fort.
   - **Facile** : creux d'après-midi [14:00–17:00], ancrage modéré, sans contexte alcool.
6. **Révélation J+3** → on **nomme** le Boss au **plus fort ancrage** (l'ennemi emblématique,
   « le Café de 7h10 »). C'est le moment dramatique du nommage.
7. **Cible J4** → on **attaque** le Boss **le plus facile** (garantir une victoire), jamais le
   Boss du matin ni celui de l'alcool.

> **✅ Tranché — nommer ≠ attaquer.** On nomme le plus ancré (impact narratif) mais on attaque le
> plus fragile (garantir la 1ʳᵉ victoire à J4). La copie du reveal ne doit donc **jamais promettre**
> que le Boss nommé est la première cible : « on lui donne un nom, on s'y attaquera ensemble »,
> pas « on l'attaque en premier ». (Déjà appliqué dans `design/revelation-j3.html`.)

### Testabilité
Fonction pure `List<Cigarette> → BossReport`. Testée avec des **fixtures de faux fumeurs**
(3 jours synthétiques : gros fumeur régulier, fumeur du soir, fumeur social…). Un **mode debug
« seed »** injecte ces historiques pour développer sans attendre 3 jours réels.

---

## 3. Machine à états du parcours

```
                 ┌──────────────┐
   J1 ─────────► │  OBSERVING   │  (J1-3) l'app ne propose RIEN, elle enregistre
                 └──────┬───────┘  écran : chrono + count + courbe + "Jour X/3 — on observe"
        72h & ≥30 taps  │
                        ▼
                 ┌──────────────┐
                 │   REVEAL     │  portrait perso + 1ᵉʳ Boss nommé + question du mode
                 └──┬────┬───┬──┘
        arrêt net  │    │   │  réduction
             ┌─────┘    │   └─────────┐
             ▼   "je sais pas"        ▼
     ┌─────────────┐  │        ┌─────────────┐
     │ COLD_TURKEY │  │        │  REDUCTION  │  1 délai/jour (10 min max) sur le Boss facile
     └──────┬──────┘  ▼        └─────────────┘  1ᵉʳ badge = 1ᵉʳ délai tenu
            │   ┌───────────────┐
      tap   │   │ MODE_UNDECIDED│  reste en observation, la révélation s'affine
            ▼   └───────────────┘  (ne JAMAIS bloquer sur la question du mode)
     ┌─────────────┐
     │   RELAPSE   │  streak → 0 (honnête), MAIS jours-cumulés & record intacts,
     └─────────────┘  propose (sans insister) de repasser en réduction
```

Guard central : **on ne bloque jamais** sur la question du mode — la 3ᵉ porte
« je ne sais pas encore » est toujours ouverte.

---

## 4. Les règles de comportement (non-négociables)

- **Écran 1 = le bouton, déjà fonctionnel.** Aucun compte, aucun objectif, aucune date d'arrêt,
  aucun « combien par jour ». Une phrase : *« Tape quand tu fumes. C'est tout, pour l'instant. »*
- **J1-3 : silence total.** Aucun défi, aucune mascotte. Texte unique : *« Jour X sur 3 — on
  observe, on ne change rien. »* (donne la permission de fumer normalement → pas de culpabilité
  → pas de mensonge → données vraies).
- **Validation silencieuse.** Le tap « je fume quand même » : écran revient à zéro, chrono repart,
  **rien d'autre**. Zéro consolation (toute consolation implique une faute).
- **1ᵉʳ badge = 1ᵉʳ délai tenu**, pas la 1ᵉʳ journée parfaite. Si les 4 premiers jours ratent →
  J8 propose un Boss encore plus facile, **sans jamais dire** que le précédent a échoué
  (« on change de cible »).
- **Rechute en arrêt net** (prévue *by design*, pas cas limite) :
  - compteur principal (streak) → **0** (honnête) ;
  - compteur **« jours sans tabac cumulés depuis le début »** → **ne bouge pas** (12 jours restent
    12 jours gagnés — c'est ce qui empêche l'effondrement « tout est foutu ») ;
  - **record d'écart max** → intact ;
  - proposition douce de repasser en réduction quelques jours.
- **Notifications** : uniquement pour le délai du Boss (une locale à T+10 min). Sinon, silence.

---

## 5. Métriques & compteurs

| Métrique | Définition | Reset ? |
|---|---|---|
| Temps depuis la dernière | `now − last.occurred_at` | à chaque tap |
| Nombre aujourd'hui | count sur le jour logique (04:00) | quotidien |
| Intervalle médian | médiane glissante des écarts | jamais (glissant) |
| Moyenne/jour | sur N derniers jours | glissant |
| Créneau chargé | mode de l'histogramme horaire | glissant |
| **Streak** | temps depuis la dernière clope (arrêt net) | à la rechute |
| **Jours-propres cumulés** | nb de jours logiques à 0 clope depuis le début | **jamais** |
| **Record d'écart max** | plus long intervalle jamais atteint | **jamais** |

---

## 6. Sauvegarde chiffrée (remplace le compte, proposée à J4)

- Argument, affiché **au J4 seulement** (quand il y a des données à protéger) :
  *« Tu as 3 jours d'historique — sauvegarde-les. »*
- Export : sérialisation du journal → **Argon2id**(passphrase) → clé → **XChaCha20-Poly1305** →
  fichier `.tabacstop.enc`. L'utilisateur choisit où (Fichiers/iCloud/Drive à sa main).
- Import : passphrase → déchiffrement → restauration du journal.
- **Rien ne quitte l'appareil sans action explicite.** Le fichier exporté est un blob opaque.

---

## 7. Arborescence du projet

```
lib/
  main.dart
  app.dart
  core/
    db/            drift database, migrations
    crypto/        argon2 + xchacha (export/import)
    notifications/ scheduling du délai Boss
    time/          jour logique 04:00, tz, formatage
    theme/
  data/
    tables/        cigarettes, journey_events (drift)
    daos/
    repositories/  CigaretteRepo, JourneyRepo
  domain/          ◄── DART PUR, 0 dépendance Flutter, 100% testé
    models/
    metrics/       median, moyenne, histogramme, streak, cumul, record
    boss/          clustering + difficulté + BossReport
    journey/       state machine + transitions
  features/
    tap/           Écran 1 (le bouton)
    observation/   J1-3 (courbe + "Jour X/3")
    reveal/        portrait J+3 + question du mode
    challenge/     Boss + délai + badge
    stats/
    backup/        export/import chiffré
  shared/          widgets communs
test/
  domain/          fixtures de faux fumeurs, tests boss/metrics/state machine
  features/        widget tests (tap → event, validation silencieuse)
```

---

## 8. Jalons (ordre de construction)

| # | Jalon | Contenu | Sortie vérifiable |
|---|---|---|---|
| **0** | Setup | projet Flutter, deps, schéma drift, riverpod, thème | app vide qui build iOS+Android |
| **1** | **Le bouton** | tap → enregistre, chrono, count aujourd'hui, **0 compte** | on peut taper, ça persiste |
| **2** | Observation J1-3 | courbe qui se remplit, « Jour X/3 », 3 icônes contexte optionnelles | l'écran d'observation vit |
| **3** | Moteur de métriques | médiane, moyenne, histogramme, créneau chargé (Dart pur + tests) | tests verts sur fixtures |
| **4** | Détection Boss | clustering + difficulté + `BossReport` + mode seed debug | reveal calculé sur faux fumeurs |
| **5** | Révélation J+3 | écran portrait, 1ᵉʳ Boss nommé, question du mode (3 portes) | le moment charnière tourne |
| **6** | State machine | modes réduction / arrêt net / indécis, persistés | transitions testées |
| **7** | Boucle défi J4-7 | 1 délai/jour (10 min max), notif, 1ᵉʳ badge, validation silencieuse | une victoire possible |
| **8** | Arrêt net + rechute | streak, jours-cumulés, record, flux rechute + bascule proposée | rechute gérée proprement |
| **9** | Sauvegarde | export/import chiffré, prompt J4 | round-trip chiffré OK |
| **10** | Polish | copie, haptique, accessibilité, empty states, **audit « l'app se tait »** | build de démo |

**Priorité absolue = Jalon 1.** Le bouton doit être parfait (latence nulle, haptique, chrono
immédiat) avant tout le reste : c'est le service rendu gratuitement dès la 1ᵉʳ seconde.

---

## 9. Risques & points à trancher

- **Tuning de la détection Boss** : impossible à régler sans données réelles → développer sur
  fixtures + mode seed, et prévoir des seuils (`eps`, `minPts`) exposés en config debug.
- **Jour logique** : 04:00 vs minuit → **décision à valider** (impacte count/jour et jours-cumulés).
- **Fuseau / heure d'été** : stocker UTC + offset, clusteriser sur l'heure murale locale.
- **Chrono en arrière-plan** : trivial (`now − last_ts`), aucun service background requis — seule
  la notif de délai est planifiée.
- **3 icônes de contexte** : figer l'enum v1 avant le Jalon 2.

---

## 10. Stratégie de test

- **domain/ = couverture forte.** Fixtures de faux fumeurs → valider `BossReport` (reveal + cible).
- **State machine** : tous les chemins, y compris rechute (streak reset mais cumul/record intacts).
- **Widget** : tap → événement enregistré ; « je fume quand même » → écran zéro, aucun texte.
- **Crypto** : round-trip export→import, mauvaise passphrase = échec propre.
```

---

## 11. Paliers santé — les altitudes du cairn (v1.1)

**But** : donner une *échelle* au cairn. Aujourd'hui il monte « dans le vide ». Chaque durée
d'abstinence continue franchie fait gagner de l'**altitude** et **révèle un fait physiologique
vrai** sur la récupération après l'arrêt du tabac. C'est le 2ᵉ cas — et le seul ajouté ici — où
l'app a le droit de parler : *elle a un fait à révéler*. Entre deux paliers, **silence total**.

### Ce qui pilote l'altitude
- **Altitude courante = abstinence continue** = `now − dernière cigarette` (le `streak` déjà calculé).
  C'est honnête : physiologiquement, fumer relance l'horloge du monoxyde de carbone.
- **« Ton plus haut cairn » = `recordGap`** (record d'écart max, déjà là) → **ne redescend jamais**.
  Une rechute remet l'altitude *courante* à zéro **sans faire tomber de pierre** : le plus haut
  cairn reste acquis, et **aucun palier déjà révélé n'est re-révélé** (voir plus bas).

### Table des paliers (fonction pure, `domain/health/`)
| Abstinence | Altitude | Fait révélé |
|---|---|---|
| 20 min | 300 m | le pouls et la tension redescendent |
| 8 h | 800 m | le monoxyde de carbone reflue, l'oxygène remonte |
| 24 h | 1 000 m | le corps est débarrassé du monoxyde de carbone |
| 48 h | 1 500 m | le goût et l'odorat reviennent |
| 72 h | 2 000 m | les bronches se détendent, respirer est plus facile |
| 2 semaines | 3 000 m | la circulation s'améliore |
| 1 mois | 3 500 m | les poumons se nettoient, moins d'essoufflement |
| 3 mois | 4 000 m | la fonction pulmonaire remonte nettement |
| 1 an | 5 000 m | le risque de maladie cardiaque est divisé par deux |

Repères classiques (NHS/CDC). Table figée v1, extensible.

### Règles de révélation (non-culpabilisantes)
- **Chaque palier n'est révélé qu'une fois « pour toujours »** — journalisé via un `journey_event`
  `milestoneRevealed` (payload = seuil en minutes). Après une rechute, re-grimper **ne re-révèle
  pas** (l'app resterait bavarde). On ne suit que le **plus haut seuil déjà révélé**.
- Le reveal ne s'affiche **qu'en mode** (arrêt net / réduction) — **jamais** pendant l'observation
  J1-3 (silence) ni sur l'Écran 1.
- Que des **gains**, jamais de perte affichée. Voix **lagon**, sobre, une carte, un bouton.

### Dérivés (jamais stockés comme vérité)
`currentAbstinence`, `milestoneAt(d)`, `nextMilestoneAfter(d)`, `reachedIndex(d)`,
`pendingMilestoneReveal(abstinence, highestRevealedIndex)` — tous purs, testés sur des durées
(comme le reste du domaine). Le seul écrit = l'événement `milestoneRevealed`.

### Surfaces
- **Sous le streak (arrêt net)** : ligne d'**altitude courante** + **prochain palier** comme objectif.
- **Reveal de palier** : carte plein-écran discrète au franchissement (recalcul périodique léger,
  pas de service background).

### Jalon
| # | Jalon | Contenu | Sortie vérifiable |
|---|---|---|---|
| **11** | **Paliers santé** | table + fonctions pures (testées), event `milestoneRevealed`, altitude sous le streak, reveal au franchissement | franchir un seuil révèle le fait une seule fois ; rechute ne re-révèle pas |

---

## 12. Le cairn dessiné & la victoire de Boss (v1.1+)

**Le cairn dessiné** (`features/cairn/cairn_view.dart`) est le visuel héros : pierres empilées
organiques (blobs Bézier bruités de façon déterministe → rendu stable), dégradé minéral + ombres.
Il monte avec la progression :
- **Arrêt net** : 1 pierre de fondation + 1 par palier santé atteint ; une pierre « en formation »
  (opacité = progression) vise le prochain palier.
- **Réduction** : 1 pierre par délai tenu (`stonesPlaced`).

**La victoire de Boss** (`domain/boss/victory.dart`, testé) — *un Boss vaincu = un gros rocher
hissé au sommet*, en **hibiscus** (seul écart chaud autorisé) :
- On **attaque** en réduction le Boss le plus fragile (`nextTarget`, hors Boss déjà vaincus).
- Chaque **délai tenu** est attribué au Boss visé (payload `bossKey` sur `delayHeld`).
- **≥ `kBossVictoryHolds` (3) délais tenus** sur un Boss ⇒ vaincu. `pendingBossVictory` déclenche
  un reveal **une seule fois** (event `bossDefeated`), puis le rocher reste sur le cairn (arrêt net
  **et** réduction). Fidèle à l'invariant : le rocher ne retombe jamais.

| # | Jalon | Contenu | Sortie vérifiable |
|---|---|---|---|
| **12** | **Cairn dessiné + victoire de Boss** | CairnPainter (galets + rocher Boss), `victory.dart` (testé), reveal `bossDefeated`, cible = prochain Boss non vaincu | tenir 3 délais sur un Boss le vainc, hisse un rocher hibiscus, une seule célébration |
| **13** | **Vie & stats** | animations de pose (chute + poussière) et de hissage, haptique, mini-cairn silencieux en observation, **écran stats** (`features/stats/`, tout dérivé) | la pierre tombe/le rocher se hisse ; les chiffres s'affichent (rythme, cumul, altitude, heures, Boss) |
| **14** | **Aide / règle du jeu** | écran « La règle du jeu » (`features/help/how_it_works_screen.dart`), ouvert par l'utilisateur ; accès lien Écran 1 + icône « ? » | l'utilisateur comprend tout le fonctionnement d'un seul écran |

---

## 15. Combat de Boss — PV, délais multiples, personnage (spec v1.5.0, **à coder**)

Refonte du combat en réduction, décidée avec le user. **Deux règles verrouillées changent** — voir
« Impacts » plus bas.

### Décisions verrouillées
- **Fumer soigne le Boss (+1 PV)** — assumé, mais **silencieux** (aucun texte/reproche/rouge) et le
  **cairn ne recule jamais** (aucune pierre ne tombe : c'est l'ennemi qui récupère, pas l'utilisateur
  qui perd). Une fois vaincu (rocher hissé), refumer **ne ressuscite pas** le Boss.
- **Délais illimités** : relançables immédiatement — on retire « 1 délai / jour ».
- **PV par difficulté** : fragile **3** · tenace **4** · coriace **5**.
- **Boss = rocher grognon minéral** (hibiscus, sourcils froncés / rictus), pas cartoon.

### Mécanique (pure, dérivée du journal, testable)
- `PV = clamp(PVmax − dégâts + soins, 0, PVmax)`
  - **dégâts** = nb de `delayHeld` sur ce Boss → chaque délai tenu : **−1 PV + 1 pierre**.
  - **soins** = nb de cigarettes fumées face à ce Boss (via `delayBroken`/heal tagué `bossKey`) → **+1 PV** (plafonné).
- **Vaincu** = PV à 0 → rocher hissé + `bossDefeated` (une fois) → **définitif**.
- **Cible** = le plus fragile non vaincu (`nextTarget`) ; quand il tombe, on passe au suivant.
- **Délai « par manche »** : `resolveDelay` ne raisonne plus par jour logique mais par manche
  (dernier `delayStarted` → terminal `delayHeld`/`delayBroken` → relançable).

### Revoir la révélation (option A)
- `RevealScreen` ré-ouvrable, titre adouci **« Où tu en es »** ; choisir un mode = changer d'approche
  (le mode n'est qu'un filtre, rien n'est perdu). Accès : bouton dans l'écran **stats**. Corrige
  l'impasse « Je ne sais pas encore » (aujourd'hui sans retour possible au choix).

### UI
- **Tête du Boss** (`features/boss/boss_face.dart`, CustomPainter) + **barre de PV** sobre à côté du
  nom : révélation, bandeau cible en réduction, victoire.
- Réduction : action délai **relançable** · galet « je fume » (soigne le Boss, silencieux).

### Fichiers
`domain/boss/victory.dart` (→ `bossMaxHp`, `bossHp`, `isDefeated`, signatures `…(report, events)`) ·
`domain/journey/delay.dart` (par manche) · nouveau `features/boss/boss_face.dart` ·
`features/reduction/*` · `reveal_screen.dart` · `stats_screen.dart` · `cold_turkey_home.dart` ·
`boss_victory_reveal.dart` · `journey_repository.dart` · tests `delay_test` + `boss_combat`.

### Impacts (règles qui changent)
- **PLAN §12 / §5** : « 1 délai par jour » → **délais multiples** ; « ≥ 3 délais tenus » → **PV à 0**.
- **CLAUDE.md** : nuancer l'invariant — un **setback scopé au combat de Boss** est désormais assumé
  (le Boss se resoigne), MAIS le cairn/les pierres/jours-propres/plus-haut-cairn **ne reculent jamais**
  et l'app reste **silencieuse** quand on fume.

| # | Jalon | Contenu | Sortie vérifiable |
|---|---|---|---|
| **15** | **Combat de Boss (PV)** | PV par difficulté, délais illimités, fumer soigne (silencieux), tête de Boss + barre de PV, « revoir ma révélation » | vaincre un Boss demande + de délais tenus que de cigarettes ; on peut changer d'approche |

---

## 16. Idées suivantes (backlog — non tranché)

Réserve d'idées discutées avec le user. **Rien n'est verrouillé** : chaque item liste ce qui reste
à décider avant d'en faire une spec.

### 16.1 « Ce que tu as évité » (dérivé) — *combo recommandé*
- À partir du **rythme observé** (médiane / moyenne d'avant le mode), estimer les cigarettes évitées.
- Affichage **factuel, jamais culpabilisant** : *« à ton rythme d'avant, ~X aujourd'hui — tu en es à Y »* ;
  cumul *« ~N évitées ce mois-ci »*. Pur / dérivé du journal.
- À trancher : **baseline** = fenêtre d'observation figée au choix du mode, ou moyenne glissante ? ·
  où l'afficher (stats + écran de mode) · formulation exacte.

### 16.2 Compagnon de délai (respiration) — *combo recommandé*
- Pendant le compte à rebours 10 min, une **respiration guidée minérale** (le cairn « respire »),
  pour surfer l'envie au lieu d'attendre. Dans le mode réduction (combat de Boss).
- À trancher : **automatique ou opt-in** · cycle (4-7-8 ?) · désactivable · discrétion.

### 16.3 En réserve (à re-prioriser)
Widget écran d'accueil (cairn / chrono / PV) · paysage de cairns au fil des mois · altitude en toile
de fond (relief qui se révèle) · cairn **partageable** (rendu local, à l'initiative de l'user) ·
galerie des Boss vaincus (trophées) · re-détection de nouveaux Boss · tendance des écarts (stats) ·
**iOS** (le seul vrai trou du plan).

### 16.4 À manier avec prudence (frôle des règles)
- **Nudges** (« ton Café de 7 h 10 approche ») : **opt-in strict**, **réduction only** — sinon casse
  « l'app parle le moins possible ».
- **Argent économisé** : demande le prix du paquet → **contredit** « aucun setup » → option facultative, jamais imposé.
- **Son** à la pose : **opt-in** (app souvent ouverte en soirée / silence).
