import 'package:cairn/core/crypto/vault.dart';
import 'package:cairn/data/backup_service.dart';
import 'package:cairn/data/cigarette_repository.dart';
import 'package:cairn/data/database.dart';
import 'package:cairn/data/journey_repository.dart';
import 'package:cairn/domain/models/enums.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CairnDatabase db;
  setUp(() => db = CairnDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('export chiffré → import restaure le journal', () async {
    await CigaretteRepository(db).logSmoke();
    await CigaretteRepository(db).logSmoke();
    await JourneyRepository(db).setMode(JourneyMode.reduction);

    final backup = BackupService(db);
    final env = await backup.exportEncrypted('pass', params: Argon2Params.fast);

    await db.delete(db.cigarettes).go();
    await db.delete(db.journeyEvents).go();
    expect(await db.select(db.cigarettes).get(), isEmpty);

    await backup.importEncrypted(env, 'pass');
    expect((await db.select(db.cigarettes).get()).length, 2);
    expect((await db.select(db.journeyEvents).get()).length, 1);
  });

  test('import avec mauvaise passphrase échoue sans toucher la base', () async {
    await CigaretteRepository(db).logSmoke();
    final backup = BackupService(db);
    final env = await backup.exportEncrypted('bon', params: Argon2Params.fast);

    await expectLater(
      backup.importEncrypted(env, 'mauvais'),
      throwsA(isA<VaultException>()),
    );
    expect((await db.select(db.cigarettes).get()).length, 1); // intacte
  });
}
