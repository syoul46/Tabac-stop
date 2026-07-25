import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/time/logical_day.dart';
import '../domain/boss/boss.dart';
import '../domain/metrics/metrics.dart';
import '../domain/models/enums.dart';
import 'database.dart';
import 'database_provider.dart';

/// Écrit et lit le journal des cigarettes. Le tap normal et « je fume quand
/// même » passent tous deux par [logSmoke] — seuls les flags diffèrent.
class CigaretteRepository {
  CigaretteRepository(this._db, [this._uuid = const Uuid()]);

  final CairnDatabase _db;
  final Uuid _uuid;

  /// Enregistre une cigarette fumée. [at] par défaut = maintenant.
  Future<void> logSmoke({
    DateTime? at,
    bool wasBoss = false,
    bool duringDelay = false,
  }) async {
    final when = at ?? DateTime.now();
    await _db.into(_db.cigarettes).insert(
          CigarettesCompanion.insert(
            id: _uuid.v4(),
            occurredAtUtc: when.toUtc(),
            tzOffsetMin: when.timeZoneOffset.inMinutes,
            wasBoss: Value(wasBoss),
            duringDelay: Value(duringDelay),
          ),
        );
  }

  /// La dernière cigarette enregistrée (ou null si aucune), en flux réactif.
  Stream<Cigarette?> watchLast() {
    final q = _db.select(_db.cigarettes)
      ..orderBy([(t) => OrderingTerm.desc(t.occurredAtUtc)])
      ..limit(1);
    return q.watchSingleOrNull();
  }

  /// Nombre de cigarettes du jour logique (04:00) contenant [now], en flux.
  Stream<int> watchTodayCount([DateTime? now]) {
    final startUtc = LogicalDay.startOf(now ?? DateTime.now()).toUtc();
    final count = _db.cigarettes.id.count();
    final query = _db.selectOnly(_db.cigarettes)
      ..addColumns([count])
      ..where(_db.cigarettes.occurredAtUtc.isBiggerOrEqualValue(startUtc));
    return query.map((row) => row.read(count) ?? 0).watchSingle();
  }

  /// Cigarettes du jour logique courant, triées, en flux (pour la courbe horaire).
  Stream<List<Cigarette>> watchTodaysCigarettes([DateTime? now]) {
    final startUtc = LogicalDay.startOf(now ?? DateTime.now()).toUtc();
    final q = _db.select(_db.cigarettes)
      ..where((t) => t.occurredAtUtc.isBiggerOrEqualValue(startUtc))
      ..orderBy([(t) => OrderingTerm.asc(t.occurredAtUtc)]);
    return q.watch();
  }

  /// La toute première cigarette (pour l'index du jour d'observation).
  Stream<Cigarette?> watchFirst() {
    final q = _db.select(_db.cigarettes)
      ..orderBy([(t) => OrderingTerm.asc(t.occurredAtUtc)])
      ..limit(1);
    return q.watchSingleOrNull();
  }

  /// Tout le journal, trié chronologiquement (pour le moteur de métriques).
  Stream<List<Cigarette>> watchAll() {
    final q = _db.select(_db.cigarettes)
      ..orderBy([(t) => OrderingTerm.asc(t.occurredAtUtc)]);
    return q.watch();
  }

  /// Pose (ou change) le contexte optionnel d'une cigarette déjà enregistrée.
  Future<void> setContext(String id, CigContext ctx) async {
    await (_db.update(_db.cigarettes)..where((t) => t.id.equals(id)))
        .write(CigarettesCompanion(contextA: Value(ctx.index)));
  }
}

final cigaretteRepositoryProvider = Provider<CigaretteRepository>((ref) {
  return CigaretteRepository(ref.watch(databaseProvider));
});

/// Dernière cigarette (null au tout premier lancement → Écran 1).
final lastCigaretteProvider = StreamProvider<Cigarette?>((ref) {
  return ref.watch(cigaretteRepositoryProvider).watchLast();
});

/// Compte du jour logique courant.
final todayCountProvider = StreamProvider<int>((ref) {
  return ref.watch(cigaretteRepositoryProvider).watchTodayCount();
});

/// Cigarettes du jour logique courant (pour la courbe + le compte).
final todaysCigarettesProvider = StreamProvider<List<Cigarette>>((ref) {
  return ref.watch(cigaretteRepositoryProvider).watchTodaysCigarettes();
});

/// Première cigarette enregistrée (pour l'index du jour d'observation).
final firstCigaretteProvider = StreamProvider<Cigarette?>((ref) {
  return ref.watch(cigaretteRepositoryProvider).watchFirst();
});

/// Tout le journal (pour le moteur de métriques).
final allCigarettesProvider = StreamProvider<List<Cigarette>>((ref) {
  return ref.watch(cigaretteRepositoryProvider).watchAll();
});

/// Portrait chiffré du journal complet (alimente la révélation J+3).
final metricsProvider = Provider<MetricsSummary>((ref) {
  final cigs = ref.watch(allCigarettesProvider).asData?.value ??
      const <Cigarette>[];
  return computeMetrics(cigs);
});

/// Détection des Boss sur le journal complet.
final bossReportProvider = Provider<BossReport>((ref) {
  final cigs = ref.watch(allCigarettesProvider).asData?.value ??
      const <Cigarette>[];
  return detectBosses(cigs);
});
