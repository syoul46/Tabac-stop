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

  /// « Je ne sais pas encore » : on continue d'observer. La question est
  /// reposée **une fois** après [kUndecidedRevealAgain] (cf. [resolvePhase]).
  undecided,
}

/// Machine à états pure : à partir du journal et du mode choisi, décide la
/// phase. Ne bloque jamais sur la question du mode (la porte « undecided » reste
/// une sortie valide).
/// [modeSince] = quand le mode courant a été choisi (dernier `modeChanged`).
/// Sert uniquement à reposer la question à qui a répondu « je ne sais pas » :
/// sans cette date, on reste sur le comportement muet.
JourneyPhase resolvePhase({
  required List<Cigarette> cigs,
  required JourneyMode? mode,
  required DateTime now,
  DateTime? modeSince,
}) {
  if (cigs.isEmpty) return JourneyPhase.firstLaunch;

  if (mode == null) {
    return shouldReveal(cigs, now)
        ? JourneyPhase.revealReady
        : JourneyPhase.observing;
  }

  switch (mode) {
    case JourneyMode.reduction:
      return JourneyPhase.reduction;
    case JourneyMode.coldTurkey:
      return JourneyPhase.coldTurkey;
    case JourneyMode.undecided:
      // La 3ᵉ porte n'est pas un cul-de-sac : après quelques jours de données
      // en plus, on repose la question une fois. Répondre « je ne sais pas » à
      // nouveau réarme simplement le même délai (le `modeChanged` est réécrit).
      final since = modeSince;
      if (since != null &&
          now.difference(since.toLocal()) >= kUndecidedRevealAgain &&
          shouldReveal(cigs, now)) {
        return JourneyPhase.revealReady;
      }
      return JourneyPhase.undecided;
    case JourneyMode.observing:
      return JourneyPhase.observing;
  }
}
