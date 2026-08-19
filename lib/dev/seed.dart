import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../data/database.dart';
import '../domain/models/enums.dart';

/// Injecte un faux historique de 8 jours (12 cigarettes/jour) si la base est
/// vide — de quoi déclencher la révélation (fenêtre = 7 jours réels), avec un
/// « Café de 7 h 10 » bien ancré. Activé via `--dart-define=SEED=true`.
/// **Dev / design uniquement.**
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
  for (var d = 8; d >= 1; d--) {
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

/// Injecte un historique **riche de ~3 semaines** si la base est vide, pour
/// visualiser les graphes de « Tes chiffres » (surtout « Ton évolution ») :
/// 7 jours d'observation (~6/j → rythme d'avant), puis une réduction déclinante
/// (~5 → 2), un mode « réduction » choisi il y a 13 jours, quelques pierres et un
/// Boss vaincu. Activé via `--dart-define=SEED=rich`. **Dev / design uniquement.**
///
/// L'app s'ouvre alors en réduction ; l'écran des graphes est l'icône
/// « graphique » en haut à gauche.
Future<void> seedRichHistoryIfEmpty(CairnDatabase db) async {
  final existing = await db.select(db.cigarettes).get();
  if (existing.isNotEmpty) return;

  const uuid = Uuid();
  final now = DateTime.now();
  final midnight = DateTime(now.year, now.month, now.day);

  // Heures piochées dans l'ordre selon le compte du jour (matin d'abord). 7 h et
  // 12 h sont présentes tous les jours → Boss bien ancrés.
  const hours = <(int, CigContext?)>[
    (7, CigContext.cafe),
    (12, CigContext.repas),
    (18, null),
    (21, CigContext.alcool),
    (8, null),
    (15, null),
    (10, null),
    (14, null),
    (16, null),
    (20, null),
  ];

  final cigs = <CigarettesCompanion>[];
  void addDay(int dayAgo, int count) {
    final base = midnight.subtract(Duration(days: dayAgo));
    for (var k = 0; k < count; k++) {
      final (h, ctx) = hours[k % hours.length];
      final local = DateTime(base.year, base.month, base.day, h, (k * 13) % 60);
      cigs.add(CigarettesCompanion.insert(
        id: uuid.v4(),
        occurredAtUtc: local.toUtc(),
        tzOffsetMin: local.timeZoneOffset.inMinutes,
        contextA: Value(ctx?.index),
      ));
    }
  }

  for (var d = 20; d >= 14; d--) {
    addDay(d, 6); // observation → rythme d'avant ≈ 6/j
  }
  const reduction = [5, 5, 4, 5, 4, 4, 3, 4, 3, 2, 3, 2, 2, 2]; // jours 13 → 0
  for (var i = 0; i < reduction.length; i++) {
    addDay(13 - i, reduction[i]);
  }
  await db.batch((b) => b.insertAll(db.cigarettes, cigs));

  final events = <JourneyEventsCompanion>[];
  JourneyEventsCompanion evt(String kind, DateTime at,
          {Map<String, dynamic>? payload}) =>
      JourneyEventsCompanion.insert(
        id: uuid.v4(),
        occurredAtUtc: at.toUtc(),
        kind: kind,
        payload: Value(payload == null ? null : jsonEncode(payload)),
      );

  // Mode choisi au début du jour logique -13 → l'observation devient la
  // référence figée du « rythme d'avant ».
  events.add(evt(JourneyEventKind.modeChanged.name,
      DateTime(now.year, now.month, now.day - 13, 4),
      payload: {'mode': JourneyMode.reduction.name}));

  // Quelques délais tenus (pierres) + une pierre bonus + un Boss vaincu (12 h).
  for (var d = 12; d >= 8; d--) {
    events.add(evt(JourneyEventKind.delayHeld.name,
        midnight.subtract(Duration(days: d)).add(const Duration(hours: 12, minutes: 5))));
  }
  events.add(evt(JourneyEventKind.bonusStone.name,
      midnight.subtract(const Duration(days: 10)).add(const Duration(hours: 12, minutes: 25))));
  events.add(evt(JourneyEventKind.bossDefeated.name,
      midnight.subtract(const Duration(days: 7)).add(const Duration(hours: 12, minutes: 40)),
      payload: {'bossKey': 'h12'}));

  await db.batch((b) => b.insertAll(db.journeyEvents, events));
}
