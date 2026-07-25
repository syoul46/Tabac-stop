import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../data/database.dart';
import '../domain/models/enums.dart';

/// Injecte un faux historique de 3 jours (12 cigarettes/jour) si la base est
/// vide — de quoi déclencher la révélation, avec un « Café de 7 h 10 » bien
/// ancré. Activé via `--dart-define=SEED=true`. **Dev / design uniquement.**
Future<void> seedFakeHistoryIfEmpty(CairnDatabase db) async {
  final existing = await db.select(db.cigarettes).get();
  if (existing.isNotEmpty) return;

  const uuid = Uuid();
  const pattern = <(int, int, CigContext?)>[
    (7, 10, CigContext.cafe),
    (8, 30, null),
    (10, 0, null),
    (11, 15, null),
    (12, 30, CigContext.repas),
    (14, 0, null),
    (15, 10, null),
    (16, 30, null),
    (18, 0, null),
    (19, 30, null),
    (21, 0, CigContext.alcool),
    (22, 30, null),
  ];

  final now = DateTime.now();
  final rows = <CigarettesCompanion>[];
  for (var d = 3; d >= 1; d--) {
    final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: d));
    for (final (h, m, ctx) in pattern) {
      final local = DateTime(day.year, day.month, day.day, h, m);
      rows.add(CigarettesCompanion.insert(
        id: uuid.v4(),
        occurredAtUtc: local.toUtc(),
        tzOffsetMin: local.timeZoneOffset.inMinutes,
        contextA: Value(ctx?.index),
      ));
    }
  }
  await db.batch((b) => b.insertAll(db.cigarettes, rows));
}
