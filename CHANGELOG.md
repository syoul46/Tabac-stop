# Changelog — Cairn

Toutes les versions notables. App de sevrage tabagique, **local-first**.
Format des dates : AAAA-MM-JJ.

## v1.9.0 — 2026-08-11

### Nouveautés
- **« Ce que tu as évité »**, dans tes chiffres. À partir de ton rythme de la semaine d'observation,
  une estimation de ce que tu n'as pas fumé : aujourd'hui, et depuis que tu as choisi ton mode.
  **La référence est figée** — plus tu réduis, plus le chiffre monte. Elle ne s'affiche que si tes
  données permettent une estimation honnête, et fumer plus que ton rythme d'avant ne crée jamais
  de dette.
- **Le galet respire pendant les 10 minutes de délai** : il enfle lentement, puis redescend. Aucun
  texte, aucune consigne, aucun son — de quoi surfer l'envie au lieu de fixer un compte à rebours.
  Tu peux le suivre ou l'ignorer. Le réglage « réduire les animations » d'Android est respecté.
- **Un widget d'écran d'accueil** (Android) : le temps depuis ta dernière cigarette et le compte du
  jour, sur fond sable. Il avance tout seul, sans ouvrir l'app. À poser depuis le sélecteur de
  widgets de ton téléphone.

## v1.8.3 — 2026-08-11

### Corrigé — important
- **Tes Boss étaient presque imbattables.** Les cigarettes de ta semaine d'observation — celle où
  l'app te dit explicitement de fumer normalement — comptaient comme des « jours craqués » et
  soignaient le Boss avant même le début du combat. Un Boss annoncé à **3 jours** en demandait en
  réalité **11**, et sa barre de points de vie restait figée pendant les 8 premiers : tu faisais
  tout bien et il ne se passait rien. Le combat ne compte plus que **depuis le jour où tu choisis
  ton mode**.
- En réduction, **le nombre de cigarettes du jour** n'apparaissait que dans certains états — donc
  presque jamais. Il est maintenant affiché en permanence.
- Après un tap « je fume » hors délai, le bouton « Retarde de 10 min » disparaissait pendant
  quelques secondes, et un « délai rompu » était enregistré alors qu'aucun délai ne tournait.

### Sous le capot
- Suppression de la dépendance `open_filex` : l'ouverture de l'APK de mise à jour passe désormais
  par du code natif. Le chemin de mise à jour complet a été **testé de bout en bout** pour la
  première fois.
- Le README annonçait la révélation « après ≥ 3 jours » alors que l'app en demande **7** (et 30
  cigarettes enregistrées). C'est corrigé — l'écran « règle du jeu » dans l'app, lui, était juste.

## v1.8.2 — 2026-08-11

### Corrigé
- **« Recommencer l'observation » réapparaît si tu as répondu « Je ne sais pas encore ».** Le bouton
  se cachait dès qu'un mode existait — or cette réponse en enregistre un. Il disparaissait donc pour
  exactement les gens qui observent encore, c'est-à-dire son public. Il reste masqué en réduction et
  en arrêt net, où le journal porte des compteurs auxquels aucune correction ne doit toucher.
- Le bandeau **« Sauvegarde tes X jours »** recouvrait le numéro de version en bas d'écran.

## v1.8.1 — 2026-08-11

### Corrigé
- **« Annuler » et « J'ai oublié de taper » côte à côte.** Empilés, ils poussaient le contenu
  jusque sur la courbe des cigarettes de la journée.
- La feuille de correction s'ouvrait en **gris-vert** au lieu du sable de l'app.
- Le sélecteur d'heure s'ouvrait en **AM/PM** : il est maintenant en 24 h, comme le reste de l'app
  (« le Café de 7 h 10 »).

## v1.8.0 — 2026-08-11

### Nouveautés
- **« J'ai oublié de taper »** (bouton discret, sur les trois écrans). Deux corrections :
  - **Ajouter une cigarette oubliée** — tu te souviens de l'heure (« il est 18 h, je n'ai pas tapé
    celle de 17 h »). L'heure étant vraie, elle nourrit correctement la détection de tes Boss.
  - **Déclarer une journée entière non tapée** — aucune heure inventée. La journée devient
    **neutre** : ni propre, ni fumée. Le cairn ne perd pas de pierre, il **se met en pause**.

### Corrigé
- **Une journée oubliée était comptée comme une journée sans tabac.** Elle gonflait tes
  « jours propres cumulés » et pouvait même décrocher un faux « plus haut cairn » — or ces deux
  compteurs ne redescendent jamais, donc l'erreur était définitive. Une journée déclarée non tapée
  ne compte plus comme une victoire, et aucun écart qui l'enjambe ne peut devenir un record.
  *(La détection des Boss, elle, n'était pas affectée : elle ne compte que les jours observés.)*

## v1.7.0 — 2026-08-11

### Nouveautés
- **« Je ne sais pas encore » n'est plus un cul-de-sac.** Répondre ça à la révélation te laissait en
  observation muette **définitivement** : rien ne reproposait jamais le choix. La question t'est
  maintenant reposée **une fois tous les 5 jours** — et répondre à nouveau « je ne sais pas »
  réarme simplement le délai. Rien ne te bloque, jamais.
- **« Annuler » partout.** Le bouton qui supprime la dernière cigarette n'existait que pendant
  l'observation. Il est maintenant aussi en **réduction** (où la cigarette resoigne le Boss) et en
  **arrêt net** (où un tap par erreur remet le streak à zéro).
- **« Recommencer l'observation »** (bouton discret, uniquement tant qu'aucun mode n'est choisi) :
  si tes premiers jours n'ont pas été tapés fidèlement, le portrait est faux — et c'est sur ce
  portrait que l'app nommera ton Boss. Tu peux repartir d'une semaine vraie. Confirmation explicite
  et dissymétrique, avec le nombre de cigarettes annoncé.

### Sous le capot
- **Build iOS** : l'app compile, démarre et enregistre sur iPhone, vérifié à chaque commit sur un
  simulateur (cf. `PLAN.md` §17). Un `.ipa` **non signé** est produit par la CI, à re-signer soi-même
  avec un Apple ID gratuit. **Jamais testé sur un vrai iPhone** — voir le README.
- **Notifications iOS** câblées (elles n'existaient que côté Android).

## v1.6.0 — 2026-08-06

### Nouveautés
- **Le combat des Boss** (mode réduction). Une fois ta révélation faite, tu affrontes tes cigarettes
  ancrées **une par une**, en commençant par la plus fragile. Chaque Boss a un **visage** et une
  **barre de points de vie**.
- **On gagne par la régularité.** Un Boss ne tombe que si tu le **retardes à son heure** (± 30 min
  autour de sa tranche), sur **plusieurs jours** : fragile 3 jours, tenace 4, coriace 5. Fumer à son
  heure lui **redonne** un point de vie — en silence, sans reproche. À 0, un **rocher est hissé** au
  sommet de ton cairn : victoire définitive.
- **Le bandeau pulse quand tu es dans sa tranche horaire** — « c'est le moment ».
- **Délais relançables** autant de fois que tu veux, et **pierres bonus** si tu tiens au-delà des
  10 min (une de plus à 20 min, une à 30 min).

### Amélioré
- **Moment de succès** clair à la fin d'un délai tenu (« délai tenu · pierre posée »).
- **La règle du jeu** détaille tout le combat, avec l'aperçu du Boss.

## v1.5.1 — 2026-08-05

### Corrigé
- **Bandeau de mise à jour** : sur certains téléphones, le texte s'affichait **à la verticale**
  (une lettre par ligne). Il est désormais pleine largeur, toujours lisible.
- **Observation** au-delà de la fenêtre : affiche « Jour 8 — on observe » (au lieu de rester bloqué
  sur « Jour 7 sur 7 ») tant que la révélation ne s'est pas déclenchée.
- **Prompt de sauvegarde** : affiche le **vrai** nombre de jours d'historique (plus « 3 » en dur).

### Amélioré
- **Bandeau de mise à jour** : montre un **résumé condensé du changelog** (les nouveautés en bref).
- **Annuler le dernier tap** : le bouton est maintenant **persistant** (un mis-tap peut se remarquer
  plus tard) et demande une **confirmation** avant de supprimer.
- Une petite **dédicace** dans le pied de page. ♥

---

## v1.5.0 — 2026-08-05

### Ajouté
- **Observation sur une semaine.** La révélation se déclenche après **7 jours réels**
  d'observation (au lieu de 3), pour capter aussi ton rythme de **week-end** et fiabiliser
  l'analyse. Le critère est une **durée réelle** (`≥ 168 h` depuis ta 1ʳᵉ cigarette) : commencer
  à 23 h ne « triche » plus de deux bascules de calendrier.
- **Revoir ta révélation / changer d'approche.** Depuis l'écran **stats**, tu peux ré-ouvrir ta
  révélation et changer de mode (arrêt net / réduction / je ne sais pas) **quand tu veux**, sans
  rien perdre (le mode n'est qu'un filtre). Corrige l'impasse « Je ne sais pas encore ».
- **Annuler le dernier tap.** Un bouton **« Annuler »** discret apparaît quelques secondes après
  un tap, pour corriger une erreur d'enregistrement.
- **Repères horaires** sur la courbe « Tes heures » : **0 h · 4 h · 8 h · 12 h · 16 h · 20 h**
  sous les barres (écran principal **et** stats).

### Corrigé / amélioré
- **Réduction** : le chrono **« depuis la dernière » reste toujours visible**, même pendant un
  délai (avant, il disparaissait derrière le compte à rebours ou l'état « pierre posée »).
- Libellé du prochain palier d'altitude plus clair : *« prochain palier : 20 minutes sans fumer
  → 200 m »*.

---

## Versions précédentes (résumé)

- **v1.4.x** — Écran **« La règle du jeu »** (comment ça marche) ; retours de test (icônes plus
  visibles, conditions de la révélation détaillées, paliers santé enrichis et rejoués après une
  rechute, pierre-graine d'observation).
- **v1.3.0** — Écran **stats** (rythme, cumul, altitude, heures, Boss) ; mini-cairn silencieux en
  observation ; poussière à la pose d'une pierre.
- **v1.2.x** — **Victoire de Boss** (le rocher hissé) ; animations de pose et de hissage ; haptique.
- **v1.1.x** — **Paliers santé** (altitudes du cairn) ; **cairn dessiné** (visuel héros).
- **v1.0.x** — MVP du parcours (bouton → observation → révélation → réduction/arrêt net →
  rechute → sauvegarde chiffrée) ; signature de release ; **auto-update** depuis les releases GitHub.
