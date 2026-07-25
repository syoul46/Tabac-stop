import 'package:cairn/domain/journey/reveal_gate.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  test('< 30 taps mais 3 jours → pas de révélation', () {
    final cigs = fakeSmoker(
      start: DateTime.utc(2026, 7, 25),
      dailyTimes: const [(8, 0), (13, 0), (19, 0)], // 3/j × 3 j = 9
      days: 3,
    );
    expect(cigs.length, 9);
    expect(shouldReveal(cigs), isFalse);
  });

  test('30 taps mais 2 jours seulement → pas de révélation', () {
    final cigs = fakeSmoker(
      start: DateTime.utc(2026, 7, 25),
      dailyTimes: List.generate(15, (i) => (6 + i, 0)), // 15/j
      days: 2,
    );
    expect(cigs.length, 30);
    expect(shouldReveal(cigs), isFalse);
  });

  test('≥ 30 taps ET ≥ 3 jours → révélation', () {
    final cigs = fakeSmoker(
      start: DateTime.utc(2026, 7, 25),
      dailyTimes: List.generate(11, (i) => (6 + i, 0)), // 11/j × 3 j = 33
      days: 3,
    );
    expect(cigs.length, 33);
    expect(shouldReveal(cigs), isTrue);
  });
}
