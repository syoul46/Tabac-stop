import 'package:cairn/domain/metrics/daily.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  test('liste vide → aucun jour', () {
    expect(dailyCounts(const [], DateTime(2026, 1, 10)), isEmpty);
  });

  test('comble les trous à 0, du premier jour à aujourd\'hui inclus', () {
    // Deux cigarettes le 6, une le 8 ; le 7 est un trou ; aujourd'hui = 9.
    final cigs = [
      cigWall(2026, 1, 6, 9, 0, id: 'a'),
      cigWall(2026, 1, 6, 18, 0, id: 'b'),
      cigWall(2026, 1, 8, 12, 0, id: 'c'),
    ];
    final days = dailyCounts(cigs, DateTime(2026, 1, 9, 15));
    expect(days.map((d) => d.count).toList(), [2, 0, 1, 0]);
    expect(days.first.day, DateTime(2026, 1, 6));
    expect(days.last.day, DateTime(2026, 1, 9));
  });

  test('la bascule 04:00 range une cigarette de 1 h sur la veille', () {
    final cigs = [cigWall(2026, 1, 6, 1, 30)];
    final days = dailyCounts(cigs, DateTime(2026, 1, 6, 12));
    // 1 h 30 le 6 → jour logique du 5. Aujourd'hui (12 h le 6) → jour du 6.
    expect(days.length, 2);
    expect(days.first.day, DateTime(2026, 1, 5));
    expect(days.first.count, 1);
    expect(days.last.count, 0);
  });

  test('marque les jours déclarés non tapés', () {
    final cigs = [
      cigWall(2026, 1, 6, 9, 0, id: 'a'),
      cigWall(2026, 1, 8, 9, 0, id: 'b'),
    ];
    final days = dailyCounts(
      cigs,
      DateTime(2026, 1, 8, 15),
      notLogged: {DateTime(2026, 1, 7)},
    );
    expect(days[1].notLogged, isTrue); // le 7
    expect(days[0].notLogged, isFalse);
    expect(days[2].notLogged, isFalse);
  });

  group('rollingDailyAverage', () {
    List<DailyCount> mk(List<int> counts, {Set<int> neutral = const {}}) => [
          for (var i = 0; i < counts.length; i++)
            DailyCount(DateTime(2026, 1, 1 + i), counts[i],
                notLogged: neutral.contains(i)),
        ];

    test('moyenne arrière, fenêtre partielle au début', () {
      final avg = rollingDailyAverage(mk([6, 4, 2]), window: 7);
      expect(avg, [6, 5, 4]); // 6 ; (6+4)/2 ; (6+4+2)/3
    });

    test('fenêtre glissante bornée à sa largeur', () {
      final avg = rollingDailyAverage(mk([3, 3, 3, 9]), window: 3);
      // dernier point = (3+3+9)/3 = 5, pas la moyenne globale
      expect(avg.last, 5);
    });

    test('les jours non tapés sont exclus de la moyenne', () {
      // Le jour 1 (index 1) est neutre → ignoré au num. et au dénom.
      final avg = rollingDailyAverage(mk([4, 99, 2], neutral: {1}), window: 7);
      expect(avg, [4, 4, 3]); // 4 ; (4)/1 ; (4+2)/2
    });
  });
}
