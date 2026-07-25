import 'package:cairn/data/cigarette_repository.dart';
import 'package:cairn/data/database.dart';
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
}
