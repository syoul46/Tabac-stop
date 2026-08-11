import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../domain/models/enums.dart';
import 'database.dart';
import 'database_provider.dart';

/// Écrit et lit le cycle de vie du parcours (modes, plus tard : boss, délais,
/// badges, rechutes) dans le journal `journey_events`.
class JourneyRepository {
  JourneyRepository(this._db, [this._uuid = const Uuid()]);

  final CairnDatabase _db;
  final Uuid _uuid;

  /// Journalise le choix (ou changement) de mode.
  Future<void> setMode(JourneyMode mode) async {
    await _db.into(_db.journeyEvents).insert(
          JourneyEventsCompanion.insert(
            id: _uuid.v4(),
            occurredAtUtc: DateTime.now().toUtc(),
            kind: JourneyEventKind.modeChanged.name,
            payload: Value(jsonEncode({'mode': mode.name})),
          ),
        );
  }

  /// Le mode courant = le dernier `modeChanged` (ou null si jamais choisi).
  Stream<JourneyMode?> watchCurrentMode() {
    final q = _db.select(_db.journeyEvents)
      ..where((t) => t.kind.equals(JourneyEventKind.modeChanged.name))
      ..orderBy([(t) => OrderingTerm.desc(t.occurredAtUtc)])
      ..limit(1);
    return q.watchSingleOrNull().map(_modeFromEvent);
  }

  /// Quand le mode courant a été choisi (dernier `modeChanged`), ou null si
  /// aucun mode ne l'a jamais été.
  Stream<DateTime?> watchCurrentModeSince() {
    final q = _db.select(_db.journeyEvents)
      ..where((t) => t.kind.equals(JourneyEventKind.modeChanged.name))
      ..orderBy([(t) => OrderingTerm.desc(t.occurredAtUtc)])
      ..limit(1);
    return q.watchSingleOrNull().map((e) => e?.occurredAtUtc);
  }

  static JourneyMode? _modeFromEvent(JourneyEvent? e) {
    if (e?.payload == null) return null;
    final name = (jsonDecode(e!.payload!) as Map)['mode'] as String?;
    for (final m in JourneyMode.values) {
      if (m.name == name) return m;
    }
    return null;
  }

  Future<void> _log(JourneyEventKind kind) async {
    await _db.into(_db.journeyEvents).insert(
          JourneyEventsCompanion.insert(
            id: _uuid.v4(),
            occurredAtUtc: DateTime.now().toUtc(),
            kind: kind.name,
          ),
        );
  }

  /// Lance le délai du jour sur le Boss.
  Future<void> startDelay() => _log(JourneyEventKind.delayStarted);

  /// Le délai a été rompu / on a fumé face au Boss (« je fume quand même ») —
  /// silencieux. Le soin du Boss est dérivé des horodatages des cigarettes (v2),
  /// plus besoin de taguer l'event.
  Future<void> markDelayBroken() => _log(JourneyEventKind.delayBroken);

  /// Pierres bonus (tenir au-delà des 10 min) — [count] d'un coup. Pour le
  /// cairn seulement, jamais pour les PV du Boss.
  Future<void> markBonusStones(int count) async {
    if (count <= 0) return;
    await _db.batch((b) {
      for (var i = 0; i < count; i++) {
        b.insert(
          _db.journeyEvents,
          JourneyEventsCompanion.insert(
            id: _uuid.v4(),
            occurredAtUtc: DateTime.now().toUtc(),
            kind: JourneyEventKind.bonusStone.name,
          ),
        );
      }
    });
  }

  /// Une rechute en arrêt net (le streak repart à zéro). Journalisé pour
  /// l'historique ; les compteurs cumulés et le record, eux, ne bougent pas.
  Future<void> markRelapse() => _log(JourneyEventKind.relapse);

  /// Mémorise que le prompt de sauvegarde a été proposé (pour ne pas re-proposer).
  Future<void> markBackupPromptSeen() => _log(JourneyEventKind.backupPromptSeen);

  /// Journalise qu'un palier santé a été révélé (seuil en minutes), pour ne le
  /// remontrer qu'une fois par montée (une rechute réinitialise, il rejouera).
  Future<void> markMilestoneRevealed(int afterMinutes) async {
    await _db.into(_db.journeyEvents).insert(
          JourneyEventsCompanion.insert(
            id: _uuid.v4(),
            occurredAtUtc: DateTime.now().toUtc(),
            kind: JourneyEventKind.milestoneRevealed.name,
            payload: Value(jsonEncode({'afterMinutes': afterMinutes})),
          ),
        );
  }

  /// Le délai a été tenu → une pierre. Au tout premier, on décroche un badge.
  /// Les dégâts au Boss (v2) sont dérivés de l'horodatage (jour + heure), plus
  /// besoin de taguer l'event.
  Future<void> markDelayHeld() async {
    final priorHeld = await (_db.select(_db.journeyEvents)
          ..where((t) => t.kind.equals(JourneyEventKind.delayHeld.name)))
        .get();
    await _log(JourneyEventKind.delayHeld);
    if (priorHeld.isEmpty) {
      await _log(JourneyEventKind.badgeEarned); // premier délai tenu
    }
  }

  /// Journalise la victoire sur un Boss (pour ne la célébrer qu'une fois).
  Future<void> markBossDefeated(String bossKey) async {
    await _db.into(_db.journeyEvents).insert(
          JourneyEventsCompanion.insert(
            id: _uuid.v4(),
            occurredAtUtc: DateTime.now().toUtc(),
            kind: JourneyEventKind.bossDefeated.name,
            payload: Value(jsonEncode({'bossKey': bossKey})),
          ),
        );
  }

  /// Tout le journal de parcours, trié (pour l'état du délai et le compte de pierres).
  Stream<List<JourneyEvent>> watchAll() {
    final q = _db.select(_db.journeyEvents)
      ..orderBy([(t) => OrderingTerm.asc(t.occurredAtUtc)]);
    return q.watch();
  }
}

final journeyRepositoryProvider = Provider<JourneyRepository>((ref) {
  return JourneyRepository(ref.watch(databaseProvider));
});

/// Mode courant du parcours (null tant qu'aucun mode n'a été choisi).
final currentModeProvider = StreamProvider<JourneyMode?>((ref) {
  return ref.watch(journeyRepositoryProvider).watchCurrentMode();
});

/// Tout le journal de parcours (pour l'état du délai et le compte de pierres).
final currentModeSinceProvider = StreamProvider<DateTime?>((ref) {
  return ref.watch(journeyRepositoryProvider).watchCurrentModeSince();
});

final journeyEventsProvider = StreamProvider<List<JourneyEvent>>((ref) {
  return ref.watch(journeyRepositoryProvider).watchAll();
});
