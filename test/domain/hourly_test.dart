import 'package:cairn/core/time/logical_day.dart';
import 'package:cairn/data/database.dart';
import 'package:cairn/domain/metrics/hourly.dart';
import 'package:flutter_test/flutter_test.dart';

Cigarette cig(DateTime utc, int offsetMin) => Cigarette(
      id: 'x',
      occurredAtUtc: utc,
      tzOffsetMin: offsetMin,
      wasBoss: false,
      duringDelay: false,
    );

void main() {
  group('hourlyCounts', () {
    test('reconstitue l\'heure locale via le décalage capturé', () {
      // 05:00 UTC + 2 h de décalage → 07:00 locale.
      final cigs = [
        cig(DateTime.utc(2026, 7, 25, 5, 0), 120),
        cig(DateTime.utc(2026, 7, 25, 5, 30), 120),
        cig(DateTime.utc(2026, 7, 25, 19, 0), 120), // 21:00 locale
      ];
      final counts = hourlyCounts(cigs);
      expect(counts.length, 24);
      expect(counts[7], 2);
      expect(counts[21], 1);
      expect(counts[0], 0);
    });

    test('liste vide → 24 zéros', () {
      expect(hourlyCounts(const []), List.filled(24, 0));
    });
  });

  group('LogicalDay.indexSince', () {
    test('même jour → 1', () {
      final first = DateTime(2026, 7, 25, 10, 0);
      final now = DateTime(2026, 7, 25, 22, 0);
      expect(LogicalDay.indexSince(first, now), 1);
    });

    test('2 jours logiques plus tard → 3', () {
      final first = DateTime(2026, 7, 25, 10, 0);
      final now = DateTime(2026, 7, 27, 9, 0);
      expect(LogicalDay.indexSince(first, now), 3);
    });

    test('avant 04:00 → encore le jour logique précédent', () {
      final first = DateTime(2026, 7, 24, 10, 0);
      final now = DateTime(2026, 7, 25, 2, 0); // 2 h du matin
      expect(LogicalDay.indexSince(first, now), 1);
    });
  });
}
