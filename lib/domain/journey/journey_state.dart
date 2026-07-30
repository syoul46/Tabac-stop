import '../../data/database.dart';
import '../models/enums.dart';
import 'reveal_gate.dart';

/// Phase courante du parcours — ce que l'app doit montrer.
enum JourneyPhase {
  /// Aucun tap encore : l'Écran 1 (le bouton + la phrase).
  firstLaunch,

  /// Observation en cours (seuil de révélation pas atteint, aucun mode choisi).
  observing,

  /// Seuil atteint et aucun mode choisi : on montre la révélation J+3.
  revealReady,

  /// Mode réduction : on attaque les Boss un par un.
  reduction,

  /// Mode arrêt net : on tient le compteur.
  coldTurkey,

  /// « Je ne sais pas encore » : on continue d'observer sans re-proposer.
  undecided,
}

/// Machine à états pure : à partir du journal et du mode choisi, décide la
/// phase. Ne bloque jamais sur la question du mode (la porte « undecided » reste
/// une sortie valide).
JourneyPhase resolvePhase({
  required List<Cigarette> cigs,
  required JourneyMode? mode,
}) {
  if (cigs.isEmpty) return JourneyPhase.firstLaunch;

  if (mode == null) {
    return shouldReveal(cigs) ? JourneyPhase.revealReady : JourneyPhase.observing;
  }

  switch (mode) {
    case JourneyMode.reduction:
      return JourneyPhase.reduction;
    case JourneyMode.coldTurkey:
      return JourneyPhase.coldTurkey;
    case JourneyMode.undecided:
      return JourneyPhase.undecided;
    case JourneyMode.observing:
      return JourneyPhase.observing;
  }
}
