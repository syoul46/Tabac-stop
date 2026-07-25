import 'package:cairn/data/cigarette_repository.dart';
import 'package:cairn/domain/boss/boss.dart';
import 'package:cairn/domain/metrics/metrics.dart';
import 'package:cairn/domain/models/enums.dart';
import 'package:cairn/features/reveal/reveal_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const boss = Boss(
    centerMinute: 7 * 60 + 10,
    spreadMinutes: 0,
    occurrences: 3,
    daysPresent: 3,
    context: CigContext.cafe,
    contextConsistency: 1.0,
    anchor: 1.0,
    hardness: 0.9,
  );

  const metrics = MetricsSummary(
    total: 57,
    days: 3,
    perDay: 19,
    medianGap: Duration(minutes: 47),
    meanGap: Duration(minutes: 52),
    busiestHour: 22,
    busiestWindow: (21, 23),
  );

  testWidgets('la révélation affiche le portrait, le Boss nommé et les 3 portes',
      (tester) async {
    final report = BossReport(
      bosses: const [boss],
      mostAnchored: boss,
      easiestTarget: boss,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          metricsProvider.overrideWithValue(metrics),
          bossReportProvider.overrideWithValue(report),
        ],
        child: const MaterialApp(home: RevealScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('19'), findsOneWidget); // moyenne/jour
    expect(find.textContaining('47 min'), findsOneWidget); // écart médian
    expect(find.text('le Café de 7 h 10'), findsOneWidget); // Boss nommé
    expect(find.text('Arrêt net'), findsOneWidget);
    expect(find.text('Réduction progressive'), findsOneWidget);
    expect(find.text('Je ne sais pas encore'), findsOneWidget);
  });
}
