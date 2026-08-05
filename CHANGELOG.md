# Changelog — Cairn

Toutes les versions notables. App de sevrage tabagique, **local-first**.
Format des dates : AAAA-MM-JJ.

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
