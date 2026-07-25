import 'package:cairn/domain/metrics/metrics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  test('journal vide → MetricsSummary.empty', () {
    final m = computeMetrics(const []);
    expect(m.total, 0);
    expect(m.perDay, 0);
    expect(m.medianGap, isNull);
    expect(m.busiestWindow, isNull);
  });

  test('moyenne/jour sur le nombre de jours logiques', () {
    // 5 cigarettes/jour × 3 jours.
    final cigs = fakeSmoker(
      start: DateTime.utc(2026, 7, 25),
      dailyTimes: const [(7, 10), (12, 30), (15, 0), (21, 0), (22, 30)],
      days: 3,
      offsetMin: 120,
    );
    final m = computeMetrics(cigs);
    expect(m.total, 15);
    expect(m.days, 3);
    expect(m.perDay, closeTo(5.0, 1e-9));
  });

  test('créneau le plus chargé = 21 h – 23 h', () {
    final cigs = fakeSmoker(
      start: DateTime.utc(2026, 7, 25),
      dailyTimes: const [(7, 10), (12, 30), (15, 0), (21, 0), (22, 30)],
      days: 3,
      offsetMin: 120,
    );
    final m = computeMetrics(cigs); // largeur 2 par défaut
    expect(m.busiestWindow, (21, 23));
  });

  test('heure la plus chargée = le pic clair', () {
    final cigs = [
      cigWall(2026, 7, 25, 8, 0, id: 'a'),
      cigWall(2026, 7, 25, 8, 20, id: 'b'),
      cigWall(2026, 7, 25, 8, 40, id: 'c'),
      cigWall(2026, 7, 25, 9, 0, id: 'd'),
    ];
    expect(computeMetrics(cigs).busiestHour, 8);
  });

  test('écart médian et moyen déterministes', () {
    // 10:00, 10:30, 11:30 → écarts de 30 min et 60 min.
    final cigs = [
      cigWall(2026, 7, 25, 10, 0, id: 'a'),
      cigWall(2026, 7, 25, 10, 30, id: 'b'),
      cigWall(2026, 7, 25, 11, 30, id: 'c'),
    ];
    final m = computeMetrics(cigs);
    expect(m.medianGap, const Duration(minutes: 45)); // (30+60)/2
    expect(m.meanGap, const Duration(minutes: 45));
  });
}
