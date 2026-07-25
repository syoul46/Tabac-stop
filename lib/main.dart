import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/database.dart';
import 'dev/seed.dart';

void main() async {
  // Dev/design : --dart-define=SEED=true injecte un faux historique de 3 jours.
  if (const bool.fromEnvironment('SEED')) {
    WidgetsFlutterBinding.ensureInitialized();
    final db = CairnDatabase();
    await seedFakeHistoryIfEmpty(db);
    await db.close();
  }
  runApp(const ProviderScope(child: CairnApp()));
}
