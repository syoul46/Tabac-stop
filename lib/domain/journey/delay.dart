import '../../data/database.dart';
import '../models/enums.dart';

/// Durée d'un délai proposé sur le Boss : 10 minutes, pas plus. Surchargeable
/// pour les tests manuels via `--dart-define=DELAY_SECONDS=15` (dev seulement —
/// la valeur par défaut reste 600 s = 10 min en production).
const kDelayLength = Duration(
  seconds: int.fromEnvironment('DELAY_SECONDS', defaultValue: 600),
);

/// Fenêtre pendant laquelle, une manche close, on affiche brièvement son
/// résultat (tenu / rompu) avant de reproposer un délai.
const kDelayFeedbackWindow = Duration(seconds: 6);

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
  Duration feedback = kDelayFeedbackWindow,
}) {
  DateTime? lastStart;
  DateTime? lastTerminal; // dernier delayHeld / delayBroken
  DelayStatus? lastTerminalKind; // held ou broken
  for (final e in events) {
    final wall = e.occurredAtUtc.toLocal();
    if (e.kind == JourneyEventKind.delayStarted.name) {
      if (lastStart == null || wall.isAfter(lastStart)) lastStart = wall;
    } else if (e.kind == JourneyEventKind.delayHeld.name ||
        e.kind == JourneyEventKind.delayBroken.name) {
      if (lastTerminal == null || wall.isAfter(lastTerminal)) {
        lastTerminal = wall;
        lastTerminalKind = e.kind == JourneyEventKind.delayHeld.name
            ? DelayStatus.held
            : DelayStatus.broken;
      }
    }
  }

  if (lastStart == null) return const DelayState(DelayStatus.available);
  // Manche close (un terminal après le dernier lancement) : on montre son
  // résultat un court instant (moment de succès), puis on repropose un délai.
  if (lastTerminal != null && !lastTerminal.isBefore(lastStart)) {
    if (now.difference(lastTerminal) < feedback) {
      return DelayState(lastTerminalKind!);
    }
    return const DelayState(DelayStatus.available);
  }

  final endsAt = lastStart.add(length);
  if (now.isBefore(endsAt)) {
    return DelayState(DelayStatus.running, endsAt: endsAt);
  }
  return const DelayState(DelayStatus.elapsed);
}

/// Nombre de pierres posées = délais tenus **+ pierres bonus** (tenir au-delà
/// des 10 min). Sur tout l'historique.
int stonesPlaced(List<JourneyEvent> events) => events
    .where((e) =>
        e.kind == JourneyEventKind.delayHeld.name ||
        e.kind == JourneyEventKind.bonusStone.name)
    .length;

/// Pierres bonus **encore à poser** pour la manche en cours, si l'abstinence
/// continue après un délai tenu : +1 à 2×[length] (20 min), +1 à 3×[length]
/// (30 min), plafond 2. Renvoie 0 si la dernière manche n'a pas été tenue, si un
/// nouveau délai a été relancé, ou si une cigarette a été fumée depuis le
/// lancement. Pur & testable ; `reduction_home` émet ce qui manque.
int pendingBonusStones(
  List<JourneyEvent> events,
  List<Cigarette> cigs,
  DateTime now, {
  Duration length = kDelayLength,
}) {
  DateTime? start; // instant UTC du dernier delayStarted
  var held = false;
  var emitted = 0;
  for (final e in events) {
    final t = e.occurredAtUtc;
    if (e.kind == JourneyEventKind.delayStarted.name) {
      start = t;
      held = false;
      emitted = 0;
    } else if (start != null && !t.isBefore(start)) {
      if (e.kind == JourneyEventKind.delayHeld.name) {
        held = true;
      } else if (e.kind == JourneyEventKind.delayBroken.name) {
        held = false;
      } else if (e.kind == JourneyEventKind.bonusStone.name) {
        emitted++;
      }
    }
  }
  if (start == null || !held) return 0;
  // Une cigarette depuis le lancement rompt la série de bonus.
  for (final c in cigs) {
    if (!c.occurredAtUtc.isBefore(start)) return 0;
  }
  final elapsed = now.toUtc().difference(start);
  var due = 0;
  if (elapsed >= length * 2) due++;
  if (elapsed >= length * 3) due++;
  final remaining = due - emitted;
  return remaining > 0 ? remaining : 0;
}
