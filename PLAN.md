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
- **≥ 30 taps** ET **≥ 7 jours réels** de données. En dessous : aucune proposition (chiffre au hasard
  = perte de confiance). C'est la raison technique de la phase d'observation.
- Si les 7 jours sont atteints mais **< 30 taps** (petit fumeur) : on **prolonge l'observation en
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
« seed »** injecte ces historiques pour développer sans attendre une semaine réelle.

---

## 3. Machine à états du parcours

```
                 ┌──────────────┐
   J1 ─────────► │  OBSERVING   │  (J1-7) l'app ne propose RIEN, elle enregistre
                 └──────┬───────┘  écran : chrono + count + courbe + "Jour X/7 — on observe"
        7 j réels & ≥30 taps  │
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

**La 3ᵉ porte n'est pas un cul-de-sac** (v1.6.1) : `MODE_UNDECIDED` repasse en `REVEAL_READY`
au bout de **`kUndecidedRevealAgain` = 5 jours** (`domain/journey/reveal_gate.dart`), à condition
que le seuil de révélation soit toujours tenu. Les données se sont étoffées entre-temps, la question
mérite d'être reposée **une fois** — et répondre « je ne sais pas » à nouveau ne fait que réarmer le
même délai. `resolvePhase` reçoit pour cela `modeSince` (date du dernier `modeChanged`) ; sans cette
date, le comportement reste muet. Ça ne contredit pas le guard : la porte reste ouverte, elle ne se
referme simplement plus sur un silence définitif.

---

## 4. Les règles de comportement (non-négociables)

- **Écran 1 = le bouton, déjà fonctionnel.** Aucun compte, aucun objectif, aucune date d'arrêt,
  aucun « combien par jour ». Une phrase : *« Tape quand tu fumes. C'est tout, pour l'instant. »*
- **J1-7 : silence total.** Aucun défi, aucune mascotte. Texte unique : *« Jour X sur 7 — on
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
- **« Annuler »** (bouton discret) : supprime la **dernière** cigarette — un mis-tap se remarque
  parfois tard. Présent sur **les trois écrans de tap** (observation, réduction, arrêt net — c'est
  en arrêt net qu'il coûte le plus cher : le mis-tap remet le streak à 0) :
  composant unique `features/tap/undo_last_button.dart`. Ne défait **que** la cigarette — les
  événements déjà journalisés (délai rompu…) restent : faire ressusciter un délai interrompu
  ouvrirait une porte pour gagner un Boss sans l'avoir tenu.
- **« J'ai oublié de taper »** (bouton discret, les 3 écrans de tap) — traite le **trou** :
  une journée non tapée est aujourd'hui **indiscernable d'une journée sans tabac**, donc comptée
  comme une victoire. Or `cumulativeCleanDays` et `recordGap` sont les deux seuls compteurs qui ne
  redescendent **jamais** : le mensonge serait définitif et incorrigible.
  - **Ajouter une cigarette oubliée** (heure connue) : l'horodatage est **vrai** (« il est 18 h, je
    n'ai pas tapé celle de 17 h »), il peut donc nourrir la détection des Boss sans la fausser.
    À ne jamais confondre avec l'invention en masse d'horaires, qui abîmerait le clustering.
  - **Déclarer une journée non tapée** (`journey_events.dayNotLogged`, payload `{day}`) :
    **aucune heure inventée**. Le jour devient **neutre** — ni propre, ni fumé. C'est la métaphore
    du cairn appliquée à l'ignorance : il ne gagne pas de pierre, il n'en perd pas, **il se met en
    pause**, exactement comme à la rechute.
  - Conséquences (fonctions pures, `domain/journey/not_logged.dart`) : le jour ne compte pas comme
    propre, et **tout écart qui l'enjambe est disqualifié du record**. Pas de preuve, pas de trophée.
  - La **détection des Boss n'a jamais eu besoin de ça** : `totalDays = distinctLogicalDays(cigs)`
    exclut déjà les jours non tapés des deux côtés de la fraction d'ancrage.
- **« Recommencer l'observation »** (bouton discret, `tap_screen`) : efface toutes les cigarettes
  et repart de zéro. Raison d'être : des premiers jours **mal tapés** (on découvre l'app, on oublie)
  produisent un **faux portrait**, et c'est sur ce portrait que l'app nommera un Boss. Mieux vaut une
  semaine vraie qu'une révélation tirée de données fausses.
  - **Uniquement tant qu'aucun mode n'est choisi** (`mode == null`). Après, le journal porte des
    jours-propres cumulés et un record d'écart max : **on n'y touche pas depuis un bouton de
    correction** — l'invariant prime.
  - **Jamais proposé par l'app** : c'est une sortie de secours, pas un conseil. Copie strictement
    factuelle (« Tes N cigarettes enregistrées seront effacées… C'est définitif »), aucun « tu as
    oublié de taper ».
  - **Confirmation dissymétrique** : « Garder mes données » en `FilledButton` (l'issue sûre se
    touche sans réfléchir), « Tout effacer » en texte teinté `colorScheme.error` — seul endroit de
    l'app où cette couleur sert. Le nombre exact est annoncé : effacer 9 jours de vraies données
    par mégarde coûterait bien plus cher que le mauvais portrait qu'on cherche à corriger.
  - L'effacement et sa trace (`journey_events.observationReset`, payload `{deleted}`) tombent dans
    **la même transaction** : un journal vidé sans trace serait un trou dans l'histoire.

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
    observation/   J1-7 (courbe + "Jour X/7")
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
| **2** | Observation J1-7 | courbe qui se remplit, « Jour X/7 », 3 icônes contexte optionnelles | l'écran d'observation vit |
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
  J1-7 (silence) ni sur l'Écran 1.
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

## 15. Combat de Boss — PV, délais multiples, personnage (**codé v2**, non publié)

Refonte du combat en réduction, décidée avec le user. **Deux règles verrouillées changent** — voir
« Impacts » plus bas. Le combat est désormais en **v2** (exigence de régularité — voir « Révision v2 »
plus bas) : le décompte se fait **par jours à l'heure du Boss**, plus par événements. **v2 codée,
testée (105 tests) et vérifiée sur émulateur.** Non publié (phase de fix). La section « Mécanique »
ci-dessous décrit la v1 (compteur d'événements) — conservée pour l'historique, mais **c'est la v2 qui
fait foi**.

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

### Réalisé (session 4) — écarts / ajouts vs spec
- **Moment de succès à l'expiration** (ajout) : `resolveDelay` renvoie brièvement `held`/`broken`
  (fenêtre `kDelayFeedbackWindow` = 6 s) après une manche close, avant `available`. Sans ça, le
  message « délai tenu · pierre posée » (déjà présent dans `_Header`) ne s'affichait **jamais** —
  `resolveDelay` ne renvoyait que `available` : rien ne « parlait » à l'expiration.
- **Durée de délai réglable** (dev/test) : `kDelayLength` lit `--dart-define=DELAY_SECONDS` (défaut
  **600 s = 10 min** en prod). Sert à tester l'expiration à la main. **Ne jamais publier un APK
  buildé avec cet override.**
- **Robustesse layout** : la colonne centrale de `tap_screen` est scrollable si l'écran est court
  (corrige un overflow révélé par le widget test, protège les petits téléphones).
- **Règle du jeu** : section combat développée (nomme ≠ attaque, visuel Boss + barre de PV,
  PV 3/4/5, délai relançable, victoire = rocher hissé définitif) + prévisu dev `SCREEN=combat`.

### Révision v2 — exigence de régularité (**codée** session 4)

Le combat v1 (ci-dessus) se gagne sur un **compteur d'événements** : 3 délais tenus, n'importe quand,
n'importe où. Or un Boss est **défini par sa récurrence horaire quotidienne** — on peut donc « vaincre
le Café de 7 h 10 » en tenant 3 délais un mardi après-midi, sans jamais affronter le vrai déclencheur.
v2 recale la victoire sur la **régularité, au jour et à l'heure du Boss**. **Cette révision remplace la
décision « dégâts = nb de délais tenus ».**

**Modèle (pur, dérivé des horodatages — plus besoin de taguer les events avec `bossKey`) :**
```
PV = clamp( PVmax − joursEntamés + joursCraqués , 0 , PVmax )
```
- **Fenêtre du Boss** = `centerMinute ± kBossWindowMin` (**30 min**, cohérent avec `epsMinutes = 25`).
- **Jour entamé** (−1 PV, **une fois/jour logique**) = ≥ 1 **délai tenu** dont l'instant tombe dans la
  fenêtre. Il faut *activement* tenir un délai — une simple non-envie ne blesse pas le Boss.
- **Jour craqué** (+1 PV, borné à PVmax) = ≥ 1 **cigarette** (n'importe laquelle, même hors délai) dans
  la fenêtre. Peut annuler un jour de progrès, jamais sous 0, **toujours silencieux**.
- **Jour neutre** (ni délai-en-fenêtre, ni clope-en-fenêtre) = **pause**, aucun mouvement. (Donc
  « consécutif sans punir » = un cumul-net au jour, pas un streak qui casse sur un jour manqué.)
- **Un même jour** peut être entamé ET craqué → net 0 (tenir plus qu'on ne craque).
- **PVmax = nb de jours** : fragile **3** · tenace **4** · coriace **5**. Vaincu à 0 → rocher hissé, définitif.

**Le cairn, découplé du combat** : *tout* délai tenu pose **1 pierre** (où que ce soit, quelle que soit
l'heure) ; **bonus de durée** — si l'utilisateur tient au-delà des 10 min sans fumer, **+1 pierre à
20 min, +1 à 30 min** (plafond **+2**, soit 3 pierres max pour une manche). Le cairn ne recule jamais.

**Réalisé (code v2) :**
- `domain/boss/victory.dart` : `bossHp(boss, cigs, events)` = `PVmax − daysEngaged + daysCracked` borné.
  Helpers `bossWindowContains`, `daysEngaged`, `daysCracked`, `engagedToday` (via `logical_day.dart` +
  heure murale). `kBossWindowMin = 30`. Signatures `defeatedBossKeys`/`pendingBossVictory`/`isBossDefeated`
  passées à `(…, cigs, events)`. Le heal est dérivé des horodatages des cigarettes.
- `domain/journey/delay.dart` : `stonesPlaced` compte `delayHeld` **+** `bonusStone` ; `pendingBonusStones`
  (pur) = pierres bonus restant à poser pour la manche (paliers `2×length` / `3×length`, plafond 2,
  coupé par une cigarette ou une relance).
- Nouvel event `JourneyEventKind.bonusStone` ; `markBonusStones(n)` (batch). Nettoyage : `markDelayHeld()`
  / `markDelayBroken()` sans paramètre (le tag `bossKey` devenait inutile).
- `reduction_home` : le ticker émet les bonus dus (`_maybeBonus`) ; bandeau cible affiche
  « entamé aujourd'hui ✓ — reviens demain » quand `engagedToday`. Bandeau descendu (52 px, ne chevauche
  plus les icônes du haut). **Pulse en fenêtre** : dans la tranche horaire du Boss (± 30 min) et pas
  encore entamé aujourd'hui, le bandeau « respire » (fond/halo/bordure hibiscus, easeInOut 1,3 s) +
  « c'est le moment — retarde-le » (`_TargetBanner` devenu StatefulWidget).
- Tests réécrits sur fixtures multi-jours (`boss_combat`, `boss_victory`) + bonus & `engagedToday`.
  **105 tests verts.** ⚠️ Ne pas lancer `dart format .` global : l'outil récent applique le « tall style »
  et reformate tout l'arbre — formatage à la main pour rester sur l'ancien style du repo.

| # | Jalon | Contenu | Sortie vérifiable |
|---|---|---|---|
| **15** | **Combat de Boss (PV)** | PV par difficulté, délais illimités, fumer soigne (silencieux), tête de Boss + barre de PV, « revoir ma révélation » | vaincre un Boss demande + de délais tenus que de cigarettes ; on peut changer d'approche |
| **15 v2** | **Régularité** | dégâts = **jours** distincts où on retarde le Boss **à son heure** (± 30 min) ; fumer en fenêtre = +1 PV ; bonus pierres 20/30 min | vaincre le Café de 7 h 10 demande de le retarder vers 7 h 10 sur 3+ jours ; une clope en fenêtre rallonge |

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
galerie des Boss vaincus (trophées) · re-détection de nouveaux Boss · tendance des écarts (stats).
*(iOS n'est plus « en réserve » : voir **§17**.)*

### 16.4 À manier avec prudence (frôle des règles)
- **Nudges** (« ton Café de 7 h 10 approche ») : **opt-in strict**, **réduction only** — sinon casse
  « l'app parle le moins possible ».
- **Argent économisé** : demande le prix du paquet → **contredit** « aucun setup » → option facultative, jamais imposé.
- **Son** à la pose : **opt-in** (app souvent ouverte en soirée / silence).

---

## 17. iOS — release non signée (sideload), sans Mac ni iPhone

Ferme le seul écart au plan restant (jalon 0 disait « build iOS + Android »). **Décidé :** on ne
passe **jamais** par l'App Store ni TestFlight — on publie un **`.ipa` non signé** à côté des APK
dans la release GitHub, et l'utilisateur le re-signe lui-même. Cohérent avec le produit : aucun
compte, aucun serveur, aucune dépendance à un tiers qui pourrait fermer la porte.

### 17.1 Les deux murs (à ne pas confondre)

| Mur | Contrainte | Solution retenue |
|---|---|---|
| **Compiler** | Flutter ne compile pas iOS hors macOS + Xcode. Le poste de dev est sous Linux. | **GitHub Actions, runner `macos-*` — gratuit pour un repo public** (le nôtre l'est). Aucun Mac à acheter. |
| **Installer** | iOS n'a **aucun** équivalent d'« autoriser les sources inconnues ». Tout binaire doit porter une signature que l'appareil accepte. | L'**utilisateur final** re-signe l'`.ipa` avec son **Apple ID gratuit** (Sideloadly / AltStore / SideStore). Validité **7 jours**, refresh automatique en WiFi avec AltStore/SideStore. |

Conséquence à assumer et à écrire dans le README : sur iOS, l'installation est une **manip
d'utilisateur averti**, qui exige un ordinateur au moins la première fois, et qui expire au bout
d'une semaine. Ce n'est pas un APK.

### 17.2 Routes écartées (et pourquoi)

| Route | Coût | Apple dans la boucle ? | Verdict |
|---|---|---|---|
| **`.ipa` non signé + Apple ID gratuit** | 0 € | non | ✅ **retenue** |
| Compte dev + **ad-hoc** (100 UDID, 1 an) | 99 $/an | non (pas de review) | à ressortir si un cercle fermé le demande |
| **TestFlight** | 99 $/an | **oui** (review) | contredit la décision |
| **DMA / AltStore PAL** (UE) | 99 $/an + frais | **oui** (notarisation obligatoire) | lourd, Apple reste gatekeeper |
| TrollStore / jailbreak | 0 € | non | public trop étroit (iOS ≤ 16.6.1) |

### 17.3 Jalons (**tous codés** — session 5)

**iOS-A — rendre le projet compilable. ✅** Surprise du premier build : le template Flutter suffisait
tel quel (Xcode 26.6, CocoaPods 1.17, `pod install` en 1 s, zéro warning). Le conflit de deployment
target qu'on redoutait n'a pas eu lieu. Déjà bon au départ : icônes iOS générées
(`flutter_launcher_icons ios: true`), police Marcellus embarquée en asset (pas de fetch réseau),
`bundle id` `com.syoul.cairn`.
- **`ios/Podfile` versionné** — il était régénéré à chaque build : ça marchait, mais rien ne le
  garantissait d'une image de runner à l'autre. `platform :ios, '13.0'`, aligné sur
  l'`IPHONEOS_DEPLOYMENT_TARGET` du projet Xcode (donc aucun changement de comportement).
- **Bloc `GCC_PREPROCESSOR_DEFINITIONS` de permission_handler : essayé, puis retiré.** Couper toutes
  les permissions iOS (l'app n'en utilise aucune) semblait gratuit. Il a été accusé d'un blocage du
  test host — **à tort** : cf. §17.4, le blocage est intermittent et revient sans lui. Le bloc reste
  retiré (bénéfice marginal), mais il n'a jamais été prouvé coupable.
- `Info.plist` : `ITSAppUsesNonExemptEncryption = false`.
- ⚠️ **Correction d'une erreur de ce plan** : il disait « restreindre à portrait seul, comme
  Android ». C'est faux — l'`AndroidManifest` **ne verrouille pas** l'orientation. Verrouiller iOS
  aurait fait diverger les deux plateformes sur une décision produit que personne n'a prise. Laissé
  en l'état ; à trancher pour les **deux** plateformes si le sujet revient.

**iOS-B — parité fonctionnelle. ✅** Le trou était réel : `initialize()` ne recevait qu'un
`AndroidInitializationSettings`, donc l'app se serait lancée sur iPhone **muette sur les fins de
délai** — l'essentiel de ce qu'elle a le droit de dire.
- `DarwinInitializationSettings` avec les trois `request*Permission` à **`false`** : rien n'est
  demandé au lancement, la permission est réclamée **au premier délai lancé**. Une pop-up système au
  démarrage ferait parler l'app avant qu'elle ait quoi que ce soit à dire.
- `requestPermissions(alert, sound)` **sans badge** : l'app ne compte rien sur son icône.
- `DarwinNotificationDetails(presentAlert/Banner/Sound)` : le rappel tombe souvent **app au premier
  plan** (l'utilisateur regarde son chrono), il doit s'afficher quand même.
- **Aucune modification d'`AppDelegate.swift`**, contrairement au snippet qu'on lit partout : le
  plugin s'enregistre lui-même comme délégué `UNUserNotificationCenter`, et c'est justement ce qui
  fait marcher l'affichage au premier plan. Poser `self` comme délégué risquait de le casser.
- `downloadAndInstall` : garde `Platform.isAndroid` (`requestInstallPackages` n'existe pas sur iOS).
  `checkForUpdate()` renvoyait déjà `null` ailleurs → **silence total sur iOS**.
- Export : `sharePositionOrigin` pour la popover iPad (sinon exception).

**iOS-C — CI. ✅** `.github/workflows/ios.yml`, runner `macos-latest`, deux jobs parallèles.
- `build` : `flutter build ios --release --no-codesign` → `Payload/Runner.app` zippé en
  `cairn-<version>-unsigned.ipa`. **~6 min**, `Runner.app` de 23,7 Mo.
- Déclenché sur tag `v*`, sur `release: published`, ou à la main. L'`.ipa` est **toujours** uploadé
  en artefact du run ; il n'est attaché à une release **que si elle existe déjà** — le workflow n'en
  crée jamais une, les notes et les APK restent écrits à la main.

**iOS-D — validation sans appareil. ✅** Job `smoke` : boot du dernier iPhone disponible, install,
lancement, captures d'écran, **puis `integration_test` qui pilote l'app pour de vrai**.
- Preuve n°1 — **taper le galet fait apparaître le chrono « depuis la dernière »**, qui ne s'affiche
  que si la cigarette a été écrite en base **puis relue** : l'aller-retour drift/SQLite tient.
- Preuve n°2 — `scheduleDelayEnd` appelé **sans `await`** (sur iOS la Future ne se résout qu'après
  la réponse au dialogue système, que personne ne tape en CI) → le dialogue *« Cairn » Would Like to
  Send You Notifications* apparaît. Il vit **hors de l'arbre Flutter**, donc invisible au test :
  c'est une **boucle de captures lancée en parallèle** qui en ramène la preuve.
- `pumpAndSettle` est inutilisable : le chrono planifie une frame par seconde, l'arbre ne se pose
  jamais → helper `pumpUntil`.
- Deux pièges de script, corrigés : `simctl launch --console-pty` exige un vrai tty (absent en CI) —
  lancé en arrière-plan, son échec passait inaperçu ; et les logs se récupèrent via
  `simctl spawn log stream`, pas via le pty.

**iOS-E — doc. ✅** Section « iOS » du README (procédure Sideloadly/AltStore, expiration 7 jours,
3 apps max par Apple ID gratuit, ordinateur requis à la première install, **binaire jamais testé sur
matériel réel**), ce §17, entrée JOURNAL.

### 17.4 Ce qui est prouvé — et ce qui ne l'est pas

**Prouvé en CI, à chaque run** : ça compile · ça s'installe · **ça démarre** · l'icône est la bonne ·
drift ouvre sa base · le tap **écrit et relit** en SQLite · la demande de permission de notification
**atteint iOS**.

**Toujours pas prouvé, faute d'iPhone** :
- **qu'une notification s'affiche à l'heure dite** — personne ne peut taper « Allow » depuis
  `simctl`, donc la permission n'est jamais accordée et rien n'est réellement planifié ;
- le partage, l'import de sauvegarde, le rendu sur encoche / Dynamic Island.

**⚠️ Blocage intermittent du smoke `integration_test`** — après un `Xcode build done` réussi,
`flutter test` reste parfois muet et le **test host se fige sur le splash** (Dart ne démarre
jamais). L'app, elle, démarre normalement dans la même exécution : le job `build` et l'étape
`Installer et lancer Cairn` passent. Observé sur ~1 run sur 3 (31359220605, 31362036419,
31457923436), sans lien établi avec le contenu du Podfile — **on a cru un temps que les macros
`permission_handler` en étaient la cause, c'était une corrélation sur deux points.** Parade en
place : garde-fou de 8 min qui tue le test et ramène la dernière capture, puis **une seconde
tentative après redémarrage du simulateur**. Un `.ipa` produit par le job `build` n'est jamais
concerné.

**Deux dettes connues** :
- `Podfile.lock` n'est **pas** versionné (impossible à générer hors macOS) — les versions de pods
  peuvent donc encore bouger d'un run à l'autre.
- ~~`open_filex` ne supporte pas Swift Package Manager~~ → **réglé** : la dépendance est supprimée.
  Ouvrir l'APK téléchargé passe désormais par un canal natif (`MainActivity.kt` + `FileProvider`,
  autorité `${applicationId}.updates`, chemins dans `res/xml/file_paths.xml`). Le plugin déclarait
  une implémentation iOS et s'invitait donc dans tous les builds iOS — où installer un APK n'a aucun
  sens — en bloquant la migration SPM. **Vérifié de bout en bout sur émulateur** : bandeau →
  téléchargement (22 Mo) → installeur système ouvert.

### 17.5 Voir tourner l'app sans iPhone — ce qui existe vraiment

Il n'existe **aucun émulateur iOS installable sous Linux ou Windows**. Le *simulateur* iOS fait
partie de Xcode et ne tourne que sur macOS (et ce n'est pas un émulateur : l'app est recompilée pour
l'architecture de l'hôte). Les options réelles, de la plus raisonnable à la moins :

| Option | Coût | Ce que ça donne |
|---|---|---|
| **Runner GitHub Actions + `xcrun simctl`** | 0 € | Simulateur réel, captures d'écran en artefacts. **La voie par défaut** (= jalon iOS-D). |
| **Runner GH Actions + session interactive** (`tmate`, ou VNC) | 0 € | Un shell — voire un écran — sur un vrai Xcode, depuis Linux, ~6 h par job. Le meilleur « hands-on » gratuit pour déboguer un build récalcitrant. |
| **Appetize.io** | freemium (quota de minutes) | On envoie le build simulateur, on interagit **dans le navigateur**. Pratique pour cliquer soi-même dans l'app. |
| **Mac loué à l'heure** (Scaleway Mac mini, MacinCloud, EC2 mac) | ~0,1 €/h, facturation min. 24 h | Xcode complet, itération rapide. À sortir seulement si iOS-B traîne. |
| **macOS en VM (OSX-KVM / Docker-OSX)** sur le homelab | 0 € | Techniquement faisable, mais **contraire à l'EULA Apple** (macOS hors matériel Apple), pas d'accél. GPU → simulateur lent, ~100 Go. Non retenu. |
| **Corellium** | cher, accès filtré | Vraie virtualisation ARM d'iOS. Hors sujet ici. |

Aucune de ces options ne remplace un test sur appareil : elles valident que **ça compile et que ça
démarre**, pas que les notifications sonnent.
