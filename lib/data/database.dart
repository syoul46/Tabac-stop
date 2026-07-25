import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'database.g.dart';

/// Base locale de Cairn. **100 % locale, aucun serveur.** La seule sortie
/// possible est un export chiffré manuel (Argon2id + XChaCha20-Poly1305).
@DriftDatabase(tables: [Cigarettes, JourneyEvents])
class CairnDatabase extends _$CairnDatabase {
  CairnDatabase() : super(_openConnection());

  /// Constructeur de test : passer `NativeDatabase.memory()`.
  CairnDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'cairn.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
