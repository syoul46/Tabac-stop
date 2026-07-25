import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';

/// Instance unique de la base locale. À surcharger en test via
/// `databaseProvider.overrideWithValue(CairnDatabase.forTesting(...))`.
final databaseProvider = Provider<CairnDatabase>((ref) {
  final db = CairnDatabase();
  ref.onDispose(db.close);
  return db;
});
