import '../../data/database.dart';
import '../models/enums.dart';

/// Durée d'un délai proposé sur le Boss : 10 minutes, pas plus.
const kDelayLength = Duration(minutes: 10);

/// État du délai courant. Modèle **par manche** (spec §15) : dès qu'une manche
/// est close (tenue ou rompue), une nouvelle est proposable — délais illimités.
enum DelayStatus {
  /// Aucune manche en cours : le délai est proposable (ou relançable).
  available,

  /// En cours : le compte à rebours tourne.
  running,

  /// Écoulé mais pas encore finalisé (à enregistrer comme « tenu »).
  elapsed,

  /// Tenu (une pierre posée, −1 PV Boss). Transitoire — l'UI l'affiche brièvement.
  held,

  /// Rompu (« je fume quand même », +1 PV Boss). Transitoire.
  broken,
}

class DelayState {
  const DelayState(this.status, {this.endsAt});
  final DelayStatus status;

  /// Fin du compte à rebours (seulement quand [status] == running).
  final DateTime? endsAt;
}

/// Résout l'état du délai à partir des events, **par manche** : on regarde le
/// dernier `delayStarted` et s'il a été clos (tenu/rompu) depuis. Si oui →
/// [DelayStatus.available] (relançable), sinon running/elapsed. Plus de limite
/// « un par jour ».
DelayState resolveDelay(
  List<JourneyEvent> events,
  DateTime now, {
  Duration length = kDelayLength,
}) {
  DateTime? lastStart;
  DateTime? lastTerminal; // dernier delayHeld / delayBroken
  for (final e in events) {
    final wall = e.occurredAtUtc.toLocal();
    if (e.kind == JourneyEventKind.delayStarted.name) {
      if (lastStart == null || wall.isAfter(lastStart)) lastStart = wall;
    } else if (e.kind == JourneyEventKind.delayHeld.name ||
        e.kind == JourneyEventKind.delayBroken.name) {
      if (lastTerminal == null || wall.isAfter(lastTerminal)) lastTerminal = wall;
    }
  }

  if (lastStart == null) return const DelayState(DelayStatus.available);
  // Manche close (un terminal après le dernier lancement) → relançable.
  if (lastTerminal != null && !lastTerminal.isBefore(lastStart)) {
    return const DelayState(DelayStatus.available);
  }

  final endsAt = lastStart.add(length);
  if (now.isBefore(endsAt)) {
    return DelayState(DelayStatus.running, endsAt: endsAt);
  }
  return const DelayState(DelayStatus.elapsed);
}

/// Nombre de pierres posées = délais tenus (sur tout l'historique).
int stonesPlaced(List<JourneyEvent> events) =>
    events.where((e) => e.kind == JourneyEventKind.delayHeld.name).length;
