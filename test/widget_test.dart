import 'package:cairn/app.dart';
import 'package:cairn/data/database.dart';
import 'package:cairn/data/database_provider.dart';
import 'package:cairn/features/tap/tap_stone.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CairnDatabase db;

  setUp(() => db = CairnDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const CairnApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 30)); // laisse les flux émettre
  }

  // Démonte l'arbre puis pompe une fois : dispose annule le Timer.periodic de
  // TapScreen, et le pump suivant laisse drift exécuter le timer 0 s qui ferme
  // ses streams (sinon flutter_test signale un timer en attente).
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('Écran 1 : première ouverture → la phrase d\'invite', (tester) async {
    await pumpApp(tester);
    expect(find.text('Tape quand tu fumes.'), findsOneWidget);
    expect(find.textContaining('aujourd’hui'), findsNothing);
    await unmount(tester);
  });

  testWidgets('taper fait disparaître la phrase et bascule sur le compte',
      (tester) async {
    // Absorbe l'appel plateforme du retour haptique.
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
        SystemChannels.platform, (_) async => null);
    addTearDown(() =>
        messenger.setMockMethodCallHandler(SystemChannels.platform, null));

    await pumpApp(tester);
    expect(find.text('Tape quand tu fumes.'), findsOneWidget);

    await tester.tap(find.byType(TapStone));
    await tester.pump(); // microtasks : insertion
    await tester.pump(const Duration(milliseconds: 30)); // flux → rebuild

    expect(find.text('Tape quand tu fumes.'), findsNothing);
    expect(find.textContaining('aujourd’hui'), findsOneWidget);
    await unmount(tester);
  });
}
