import 'package:cairn/domain/boss/boss.dart';
import 'package:cairn/domain/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  test('moins de 2 jours de données → aucun Boss', () {
    final oneDay = [
      cigWall(2026, 7, 25, 7, 10, id: 'a'),
      cigWall(2026, 7, 25, 7, 12, id: 'b'),
      cigWall(2026, 7, 25, 7, 11, id: 'c'),
    ];
    expect(detectBosses(oneDay).isEmpty, isTrue);
  });

  group('fumeur régulier sur 3 jours', () {
    // Matin : café à 7 h 10 pile (très ancré, dur).
    // Après-midi : ~15 h avec un peu de jitter (fragile, creux → facile).
    // Soir : ~21 h avec jitter (médian).
    final cigs = <dynamic>[];
    void day(int d, List<(int, int, CigContext?)> times) {
      for (final (h, m, ctx) in times) {
        cigs.add(cigWall(2026, 7, d, h, m,
            offsetMin: 120, id: 'c${cigs.length}', context: ctx));
      }
    }

    day(25, [(7, 10, CigContext.cafe), (15, 0, null), (21, 0, null)]);
    day(26, [(7, 10, CigContext.cafe), (15, 10, null), (21, 10, null)]);
    day(27, [(7, 10, CigContext.cafe), (14, 50, null), (20, 50, null)]);

    final report = detectBosses(cigs.cast());

    test('trois Boss récurrents détectés', () {
      expect(report.bosses.length, 3);
    });

    test('le plus ancré = le Café de 7 h 10', () {
      final boss = report.mostAnchored!;
      expect(boss.centerMinute, 7 * 60 + 10);
      expect(boss.context, CigContext.cafe);
      expect(boss.name, 'le Café de 7 h 10');
      expect(boss.difficulty, BossDifficulty.hard); // 1ère du matin
    });

    test('la cible la plus facile = le creux d\'après-midi', () {
      final target = report.easiestTarget!;
      expect(target.hour, inInclusiveRange(14, 16));
      expect(target.difficulty, BossDifficulty.easy);
      // Jamais le matin ni le soir.
      expect(target.centerMinute, isNot(7 * 60 + 10));
    });
  });
}
