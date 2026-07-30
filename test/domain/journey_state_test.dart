import 'package:cairn/domain/journey/journey_state.dart';
import 'package:cairn/domain/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  final fewCigs = fakeSmoker(
    start: DateTime.utc(2026, 7, 25),
    dailyTimes: const [(8, 0), (13, 0)], // 2/j × 3 j = 6 (< seuil)
    days: 3,
  );
  final manyCigs = fakeSmoker(
    start: DateTime.utc(2026, 7, 25),
    dailyTimes: List.generate(11, (i) => (6 + i, 0)), // 33 (>= seuil)
    days: 3,
  );

  test('aucun tap → firstLaunch', () {
    expect(resolvePhase(cigs: const [], mode: null), JourneyPhase.firstLaunch);
  });

  test('peu de taps, aucun mode → observing', () {
    expect(resolvePhase(cigs: fewCigs, mode: null), JourneyPhase.observing);
  });

  test('seuil atteint, aucun mode → revealReady', () {
    expect(resolvePhase(cigs: manyCigs, mode: null), JourneyPhase.revealReady);
  });

  test('mode choisi → phase du mode (indépendant du seuil)', () {
    expect(resolvePhase(cigs: manyCigs, mode: JourneyMode.coldTurkey),
        JourneyPhase.coldTurkey);
    expect(resolvePhase(cigs: manyCigs, mode: JourneyMode.reduction),
        JourneyPhase.reduction);
  });

  test('undecided → on continue d\'observer (pas de re-révélation)', () {
    expect(resolvePhase(cigs: manyCigs, mode: JourneyMode.undecided),
        JourneyPhase.undecided);
  });
}
