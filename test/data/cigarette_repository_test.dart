import 'dart:convert';

import 'package:cairn/data/cigarette_repository.dart';
import 'package:cairn/data/database.dart';
import 'package:cairn/domain/models/enums.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CairnDatabase db;
  late CigaretteRepository repo;

  setUp(() {
    db = CairnDatabase.forTesting(NativeDatabase.memory());
    repo = CigaretteRepository(db);
  });
  tearDown(() => db.close());

  test('logSmoke insère une cigarette, watchLast la retourne', () async {
    expect(await repo.watchLast().first, isNull);
    await repo.logSmoke();
    expect(await repo.watchLast().first, isNotNull);
  });

  test('watchTodayCount compte sur le jour logique (bascule à 04:00)', () async {
    final now = DateTime(2026, 7, 25, 10, 0);
    await repo.logSmoke(at: DateTime(2026, 7, 25, 9, 0)); // même jour logique
    await repo.logSmoke(at: DateTime(2026, 7, 25, 2, 0)); // avant 04:00 → veille
    expect(await repo.watchTodayCount(now).first, 1);
  });

  test('undoLastCigarette supprime la plus récente, puis échoue à vide', () async {
    final t9 = DateTime(2026, 7, 25, 9, 0);
    final t10 = DateTime(2026, 7, 25, 10, 0);
    await repo.logSmoke(at: t9);
    await repo.logSmoke(at: t10);

    expect(await repo.undoLastCigarette(), isTrue); // supprime celle de 10 h
    final last = await repo.watchLast().first;
    expect(last, isNotNull);
    expect(last!.occurredAtUtc.isAtSameMomentAs(t9), isTrue); // reste celle de 9 h

    expect(await repo.undoLastCigarette(), isTrue); // supprime celle de 9 h
    expect(await repo.watchLast().first, isNull);
    expect(await repo.undoLastCigarette(), isFalse); // plus rien à annuler
  });

  test('resetObservation efface tout et laisse une trace au journal', () async {
    for (var h = 8; h < 14; h++) {
      await repo.logSmoke(at: DateTime(2026, 7, 25, h, 0));
    }

    expect(await repo.resetObservation(), 6);
    expect(await repo.watchLast().first, isNull); // on repart de zéro

    final events = await db.select(db.journeyEvents).get();
    final reset = events
        .where((e) => e.kind == JourneyEventKind.observationReset.name)
        .toList();
    expect(reset, hasLength(1)); // le journal garde la trace du redémarrage
    expect(jsonDecode(reset.single.payload!)['deleted'], 6);
  });

  test('resetObservation à vide n\'efface rien mais se journalise', () async {
    expect(await repo.resetObservation(), 0);
    final events = await db.select(db.journeyEvents).get();
    expect(events, hasLength(1));
  });
}
