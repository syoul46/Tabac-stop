import '../../core/time/logical_day.dart';
import '../../data/database.dart';
import '../models/enums.dart';

/// Durée d'un délai proposé sur le Boss : 10 minutes, pas plus.
const kDelayLength = Duration(minutes: 10);

/// État du délai du jour (un seul délai par jour logique).
enum DelayStatus {
  /// Pas encore lancé aujourd'hui : le délai est proposable.
  available,

  /// En cours : le compte à rebours tourne.
  running,

  /// Écoulé mais pas encore finalisé (à enregistrer comme « tenu »).
  elapsed,

  /// Tenu jusqu'au bout aujourd'hui — une pierre posée.
  held,

  /// Rompu aujourd'hui (« je fume quand même ») — silencieux.
  broken,
}

class DelayState {
  const DelayState(this.status, {this.endsAt});
  final DelayStatus status;

  /// Fin du compte à rebours (seulement quand [status] == running).
  final DateTime? endsAt;
}

/// Résout l'état du délai pour le jour logique de [now] à partir des events.
DelayState resolveDelay(
  List<JourneyEvent> events,
  DateTime now, {
  Duration length = kDelayLength,
}) {
  final today = LogicalDay.dayOf(now);
  DateTime? startedAt;
  var heldToday = false;
  var brokenToday = false;

  for (final e in events) {
    final wall = e.occurredAtUtc.toLocal();
    if (LogicalDay.dayOf(wall) != today) continue;
    if (e.kind == JourneyEventKind.delayStarted.name) {
      if (startedAt == null || wall.isAfter(startedAt)) startedAt = wall;
    } else if (e.kind == JourneyEventKind.delayHeld.name) {
      heldToday = true;
    } else if (e.kind == JourneyEventKind.delayBroken.name) {
      brokenToday = true;
    }
  }

  if (heldToday) return const DelayState(DelayStatus.held);
  if (brokenToday) return const DelayState(DelayStatus.broken);
  if (startedAt == null) return const DelayState(DelayStatus.available);

  final endsAt = startedAt.add(length);
  if (now.isBefore(endsAt)) {
    return DelayState(DelayStatus.running, endsAt: endsAt);
  }
  return const DelayState(DelayStatus.elapsed);
}

/// Nombre de pierres posées = délais tenus (sur tout l'historique).
int stonesPlaced(List<JourneyEvent> events) =>
    events.where((e) => e.kind == JourneyEventKind.delayHeld.name).length;
