import 'package:drift/drift.dart';

/// Chaque cigarette réellement fumée.
///
/// Le tap normal ET le « je fume quand même » produisent le MÊME événement ;
/// seuls les flags [wasBoss] / [duringDelay] diffèrent. La validation
/// silencieuse est donc le comportement par défaut, pas un cas spécial.
class Cigarettes extends Table {
  TextColumn get id => text()();

  /// Toujours en **UTC** (source de vérité temporelle).
  DateTimeColumn get occurredAtUtc => dateTime()();

  /// Décalage local en minutes au moment du tap → reconstitue l'heure murale
  /// locale, sur laquelle on clusterise les Boss.
  IntColumn get tzOffsetMin => integer()();

  /// Contexte optionnel (index de `CigContext`). `contextB/C` réservés pour
  /// d'éventuelles familles futures.
  IntColumn get contextA => integer().nullable()();
  IntColumn get contextB => integer().nullable()();
  IntColumn get contextC => integer().nullable()();

  /// Cette cigarette ciblait-elle le Boss du jour.
  BoolColumn get wasBoss => boolean().withDefault(const Constant(false))();

  /// Fumée pendant un délai actif = « je fume quand même ».
  BoolColumn get duringDelay => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cycle de vie du parcours (modes, boss, délais, badges, rechutes).
///
/// Avec [Cigarettes], forme le **journal append-only** — unique source de
/// vérité. Tout le reste (chrono, streak, jours cumulés, record) est dérivé.
class JourneyEvents extends Table {
  TextColumn get id => text()();
  DateTimeColumn get occurredAtUtc => dateTime()();

  /// `JourneyEventKind.name`.
  TextColumn get kind => text()();

  /// Données spécifiques à l'événement, en JSON (id du boss, mode cible…).
  TextColumn get payload => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
