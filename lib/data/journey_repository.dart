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

  /// Le délai a été rompu (« je fume quand même ») — silencieux.
  Future<void> markDelayBroken() => _log(JourneyEventKind.delayBroken);

  /// Le délai a été tenu → une pierre. Au tout premier, on décroche un badge.
  Future<void> markDelayHeld() async {
    final priorHeld = await (_db.select(_db.journeyEvents)
          ..where((t) => t.kind.equals(JourneyEventKind.delayHeld.name)))
        .get();
    await _log(JourneyEventKind.delayHeld);
    if (priorHeld.isEmpty) {
      await _log(JourneyEventKind.badgeEarned); // premier délai tenu
    }
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
final journeyEventsProvider = StreamProvider<List<JourneyEvent>>((ref) {
  return ref.watch(journeyRepositoryProvider).watchAll();
});
