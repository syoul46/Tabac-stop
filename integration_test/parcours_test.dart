// Smoke test « vivant » (jalon iOS-D, cf. PLAN.md §17).
//
// Le job `smoke` du workflow prouve que l'app démarre. Ce test-ci va plus loin :
// il **touche** l'app sur le simulateur et vérifie les deux chemins qu'on ne
// peut pas valider autrement sans iPhone —
//   1. écrire une pierre en base et la relire (drift / SQLite) ;
//   2. faire remonter la demande de permission de notification jusqu'à iOS.
//
// Lancement : `flutter test integration_test/parcours_test.dart -d <simulateur>`.

import 'dart:async';

import 'package:cairn/core/notifications/notification_service.dart';
import 'package:cairn/features/tap/tap_stone.dart';
import 'package:cairn/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Pompe jusqu'à ce que [finder] existe (ou expiration).
///
/// `pumpAndSettle` est inutilisable ici : le chrono de l'Écran 1 planifie une
/// frame par seconde, donc l'arbre ne « se pose » jamais.
Future<void> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  const step = Duration(milliseconds: 250);
  var waited = Duration.zero;
  while (waited < timeout) {
    await tester.pump(step);
    waited += step;
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Introuvable après ${timeout.inSeconds} s : $finder');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('taper le galet pose une pierre (aller-retour SQLite)',
      (tester) async {
    app.main();

    await pumpUntil(tester, find.text('Tape quand tu fumes.'));
    expect(find.byType(TapStone), findsOneWidget);

    await tester.tap(find.byType(TapStone));

    // Le chrono ne s'affiche que si la cigarette a été **écrite** en base puis
    // **relue** — c'est le seul aller-retour drift qu'on puisse prouver sans
    // appareil réel. S'il apparaît, la couche de données tient sur iOS.
    await pumpUntil(tester, find.text('depuis la dernière'));
    expect(find.text('Tape quand tu fumes.'), findsNothing);
  });

  testWidgets('la demande de permission de notification atteint iOS',
      (tester) async {
    // Volontairement **pas** de `await` : sur iOS, `requestPermissions` ne se
    // résout qu'une fois que l'utilisateur a répondu au dialogue système — et
    // personne ne tape « Autoriser » sur un runner. On déclenche, on laisse le
    // dialogue s'afficher, et la capture d'écran prise en parallèle par le
    // workflow fait office de preuve : sans le câblage Darwin, aucun dialogue
    // n'apparaîtrait du tout.
    unawaited(
      NotificationService().scheduleDelayEnd(
        DateTime.now().add(const Duration(minutes: 10)),
        bossName: 'le Café de 7 h 10',
      ),
    );

    for (var i = 0; i < 32; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  });
}
