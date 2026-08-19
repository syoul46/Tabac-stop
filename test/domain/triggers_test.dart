import 'package:cairn/domain/metrics/triggers.dart';
import 'package:cairn/domain/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  test('liste vide → rien de tagué', () {
    final b = triggerBreakdown(const []);
    expect(b.tagged, 0);
    expect(b.total, 0);
    expect(b.dominant, isNull);
    expect(b.share(CigContext.cafe), 0);
  });

  test('compte les contextes, ignore les non taguées', () {
    final cigs = [
      cigWall(2026, 1, 1, 7, 0, id: 'a', context: CigContext.cafe),
      cigWall(2026, 1, 1, 8, 0, id: 'b', context: CigContext.cafe),
      cigWall(2026, 1, 1, 12, 0, id: 'c', context: CigContext.repas),
      cigWall(2026, 1, 1, 15, 0, id: 'd'), // sans contexte
    ];
    final b = triggerBreakdown(cigs);
    expect(b.total, 4);
    expect(b.tagged, 3);
    expect(b.counts[CigContext.cafe], 2);
    expect(b.counts[CigContext.repas], 1);
    expect(b.counts[CigContext.alcool], 0);
    expect(b.dominant, CigContext.cafe);
    expect(b.share(CigContext.cafe), closeTo(2 / 3, 1e-9));
  });

  test('dominant = null si aucune cigarette taguée', () {
    final cigs = [cigWall(2026, 1, 1, 9, 0), cigWall(2026, 1, 1, 10, 0, id: 'x')];
    final b = triggerBreakdown(cigs);
    expect(b.tagged, 0);
    expect(b.dominant, isNull);
  });
}
