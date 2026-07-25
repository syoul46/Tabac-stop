import 'package:cairn/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('l\'app démarre et affiche le mot-marque Cairn', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CairnApp()));
    expect(find.text('Cairn'), findsOneWidget);
  });
}
