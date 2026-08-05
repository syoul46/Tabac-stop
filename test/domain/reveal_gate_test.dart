import 'package:cairn/domain/journey/reveal_gate.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  final start = DateTime.utc(2026, 7, 25);

  test('< 30 taps → pas de révélation, même après une semaine', () {
    final cigs = fakeSmoker(
      start: start,
      dailyTimes: const [(8, 0), (13, 0), (19, 0)], // 3/j × 7 j = 21
      days: 7,
    );
    expect(cigs.length, 21);
    expect(shouldReveal(cigs, start.add(const Duration(days: 8))), isFalse);
  });

  test('30 taps mais < 7 jours réels écoulés → pas de révélation', () {
    final cigs = fakeSmoker(
      start: start,
      dailyTimes: List.generate(15, (i) => (6 + i, 0)), // 15/j × 2 j = 30
      days: 2,
    );
    expect(cigs.length, 30);
    // 3 jours après le début → durée réelle < 7 jours.
    expect(shouldReveal(cigs, start.add(const Duration(days: 3))), isFalse);
  });

  test('≥ 30 taps ET ≥ 7 jours réels → révélation', () {
    final cigs = fakeSmoker(
      start: start,
      dailyTimes: List.generate(5, (i) => (8 + i, 0)), // 5/j × 7 j = 35
      days: 7,
    );
    expect(cigs.length, 35);
    // 1ᵉʳ tap à 08:00 → il faut dépasser 08:00 au 7ᵉ jour ; j+8 est large.
    expect(shouldReveal(cigs, start.add(const Duration(days: 8))), isTrue);
  });

  test('commencer tard ne triche pas : 3 jours de calendrier ≠ 7 j réels', () {
    final cigs = fakeSmoker(
      start: start,
      dailyTimes: List.generate(12, (i) => (6 + i, 0)), // 12/j × 3 j = 36
      days: 3,
    );
    expect(cigs.length, 36);
    // ~2 j 6 h après le 1ᵉʳ tap → l'ancienne logique (3 jours calendaires)
    // aurait révélé ; la nouvelle (durée réelle) non.
    expect(shouldReveal(cigs, DateTime.utc(2026, 7, 27, 12)), isFalse);
    // 7 jours réels plus tard → oui.
    expect(shouldReveal(cigs, DateTime.utc(2026, 8, 1, 12)), isTrue);
  });
}
