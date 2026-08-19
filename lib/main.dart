import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/database.dart';
import 'dev/seed.dart';

void main() async {
  // Dev/design : --dart-define=SEED=true injecte 8 jours (déclenche la
  // révélation) ; SEED=rich injecte ~3 semaines déclinantes + un mode choisi,
  // pour visualiser les graphes de « Tes chiffres ».
  const seed = String.fromEnvironment('SEED');
  if (seed.isNotEmpty) {
    WidgetsFlutterBinding.ensureInitialized();
    final db = CairnDatabase();
    if (seed == 'rich') {
      await seedRichHistoryIfEmpty(db);
    } else {
      await seedFakeHistoryIfEmpty(db);
    }
    await db.close();
  }
  runApp(const ProviderScope(child: CairnApp()));
}
