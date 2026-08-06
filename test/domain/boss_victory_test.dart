import 'dart:convert';

import 'package:cairn/data/database.dart';
import 'package:cairn/domain/boss/boss.dart';
import 'package:cairn/domain/boss/victory.dart';
import 'package:cairn/domain/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

Boss _boss(int hour, double hardness) => Boss(
      centerMinute: hour * 60,
      spreadMinutes: 5,
      occurrences: 10,
      daysPresent: 5,
      context: null,
      contextConsistency: 1,
      anchor: 0.5,
      hardness: hardness,
    );

/// Délai tenu à l'heure murale [h] h [m], le [day] janvier 2026.
JourneyEvent heldAt(int day, int h, int m) => JourneyEvent(
      id: 'h-$day-$h-$m',
      occurredAtUtc: DateTime(2026, 1, day, h, m).toUtc(),
      kind: JourneyEventKind.delayHeld.name,
    );

/// Cigarette à l'heure murale [h] h [m] le [day] janvier 2026 (offset 0).
Cigarette cigAt(int day, int h, int m) => Cigarette(
      id: 'c-$day-$h-$m',
      occurredAtUtc: DateTime.utc(2026, 1, day, h, m),
      tzOffsetMin: 0,
      contextA: null,
      wasBoss: false,
      duringDelay: false,
    );

JourneyEvent _defeated(String key) => JourneyEvent(
      id: 'd$key',
      occurredAtUtc: DateTime.utc(2026, 2, 1),
      kind: JourneyEventKind.bossDefeated.name,
      payload: jsonEncode({'bossKey': key}),
    );

/// Rapport à un seul Boss fragile (PVmax 3 jours) à l'heure [hour].
BossReport _reportEasy(int hour) {
  final b = _boss(hour, 0.2);
  return BossReport(bosses: [b], mostAnchored: b, easiestTarget: b);
}

void main() {
  test('bossKey = heure murale', () {
    expect(bossKey(_boss(7, 0.2)), 'h7');
    expect(bossKey(_boss(21, 0.9)), 'h21');
  });

  group('defeatedBossKeys (v2 — jours à l’heure du Boss)', () {
    test('vaincu à 3 jours distincts entamés, pas avant', () {
      final report = _reportEasy(7);
      final two = [heldAt(1, 7, 0), heldAt(2, 7, 0)];
      expect(defeatedBossKeys(report, const [], two), isEmpty);
      final three = [heldAt(1, 7, 0), heldAt(2, 7, 0), heldAt(3, 7, 0)];
      expect(defeatedBossKeys(report, const [], three), {'h7'});
    });

    test('une cigarette à l’heure retarde la victoire', () {
      final report = _reportEasy(7);
      final e = [heldAt(1, 7, 0), heldAt(2, 7, 0), heldAt(3, 7, 0)]; // 3 jours
      final cigs = [cigAt(1, 7, 20)]; // jour 1 aussi craqué → net 2
      expect(defeatedBossKeys(report, cigs, e), isEmpty);
    });

    test('les délais hors fenêtre ne vainquent personne', () {
      final report = _reportEasy(7);
      final e = [heldAt(1, 12, 0), heldAt(2, 12, 0), heldAt(3, 12, 0)];
      expect(defeatedBossKeys(report, const [], e), isEmpty);
    });

    test('une victoire déjà célébrée reste acquise (rocher ne retombe pas)', () {
      final report = _reportEasy(7);
      // aucun délai, mais un event bossDefeated → clé toujours dans defeated
      expect(defeatedBossKeys(report, const [], [_defeated('h7')]), {'h7'});
    });
  });

  group('pendingBossVictory', () {
    test('un Boss vaincu non révélé → à célébrer', () {
      final report = _reportEasy(7);
      final e = [heldAt(1, 7, 0), heldAt(2, 7, 0), heldAt(3, 7, 0)];
      expect(pendingBossVictory(report, const [], e), 'h7');
    });
    test('déjà révélé → plus rien', () {
      final report = _reportEasy(7);
      final e = [
        heldAt(1, 7, 0),
        heldAt(2, 7, 0),
        heldAt(3, 7, 0),
        _defeated('h7'),
      ];
      expect(pendingBossVictory(report, const [], e), isNull);
    });
  });

  group('nextTarget', () {
    final report = BossReport(
      bosses: [_boss(7, 0.8), _boss(15, 0.2), _boss(21, 0.5)],
      mostAnchored: _boss(7, 0.8),
      easiestTarget: _boss(15, 0.2),
    );
    test('le plus fragile non vaincu', () {
      expect(bossKey(nextTarget(report, {})!), 'h15');
    });
    test('saute les vaincus', () {
      expect(bossKey(nextTarget(report, {'h15'})!), 'h21');
    });
    test('tous vaincus → null', () {
      expect(nextTarget(report, {'h7', 'h15', 'h21'}), isNull);
    });
  });

  test('bossForKey retrouve le Boss', () {
    final report = BossReport(
      bosses: [_boss(7, 0.8), _boss(15, 0.2)],
      mostAnchored: _boss(7, 0.8),
      easiestTarget: _boss(15, 0.2),
    );
    expect(bossForKey(report, 'h15')!.hour, 15);
    expect(bossForKey(report, 'h99'), isNull);
  });
}
