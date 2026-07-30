import 'package:cairn/domain/metrics/metrics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  group('cumulativeCleanDays', () {
    test('fume tous les jours → 0 jour propre', () {
      final cigs = fakeSmoker(
        start: DateTime(2026, 7, 25),
        dailyTimes: const [(9, 0), (18, 0)],
        days: 3,
      );
      // « maintenant » = quelques jours après, tous les jours passés sont fumés.
      expect(cumulativeCleanDays(cigs, DateTime(2026, 7, 28, 12, 0)), 0);
    });

    test('arrêt après 2 jours fumés → les jours propres terminés comptent', () {
      // Fume les 25 et 26, plus rien ensuite.
      final cigs = fakeSmoker(
        start: DateTime(2026, 7, 25),
        dailyTimes: const [(9, 0)],
        days: 2,
      );
      // Le 30 à midi : 27, 28, 29 sont des jours propres terminés (pas le 30).
      expect(cumulativeCleanDays(cigs, DateTime(2026, 7, 30, 12, 0)), 3);
    });

    test('aujourd\'hui (en cours) ne compte pas encore', () {
      final cigs = fakeSmoker(
        start: DateTime(2026, 7, 25),
        dailyTimes: const [(9, 0)],
        days: 1,
      );
      // Le 26 : le 25 est fumé, le 26 est en cours → 0 jour propre terminé.
      expect(cumulativeCleanDays(cigs, DateTime(2026, 7, 26, 12, 0)), 0);
    });
  });

  group('recordGap (invariant de rechute)', () {
    test('inclut l\'abstinence en cours', () {
      final cigs = [cigWall(2026, 7, 30, 8, 0)];
      // `now` = 10 h après l'instant de la cigarette (indépendant du fuseau).
      final now = cigs.first.occurredAtUtc.toLocal().add(const Duration(hours: 10));
      expect(recordGap(cigs, now), const Duration(hours: 10));
    });

    test('une rechute laisse le record intact', () {
      // 12 jours d'écart entre deux cigarettes, puis rechute immédiate.
      final cigs = [
        cigWall(2026, 7, 1, 8, 0, id: 'a'),
        cigWall(2026, 7, 13, 8, 0, id: 'b'), // +12 j
      ];
      final justAfter = DateTime(2026, 7, 13, 8, 1); // streak courant ~0
      final rec = recordGap(cigs, justAfter);
      expect(rec, greaterThanOrEqualTo(const Duration(days: 12)));
    });
  });
}
