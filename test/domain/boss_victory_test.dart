import 'dart:convert';

import 'package:cairn/data/database.dart';
import 'package:cairn/domain/boss/boss.dart';
import 'package:cairn/domain/boss/victory.dart';
import 'package:cairn/domain/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

JourneyEvent _held(String? key, {int i = 0}) => JourneyEvent(
      id: 'h$i',
      occurredAtUtc: DateTime.utc(2026, 1, 1).add(Duration(days: i)),
      kind: JourneyEventKind.delayHeld.name,
      payload: key == null ? null : jsonEncode({'bossKey': key}),
    );

JourneyEvent _defeated(String key) => JourneyEvent(
      id: 'd$key',
      occurredAtUtc: DateTime.utc(2026, 2, 1),
      kind: JourneyEventKind.bossDefeated.name,
      payload: jsonEncode({'bossKey': key}),
    );

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

void main() {
  test('bossKey = heure murale', () {
    expect(bossKey(_boss(7, 0.2)), 'h7');
    expect(bossKey(_boss(21, 0.9)), 'h21');
  });

  group('holds & defeated', () {
    test('compte les délais tenus par Boss', () {
      final events = [_held('h7', i: 0), _held('h7', i: 1), _held('h15', i: 2)];
      expect(holdsForBoss(events, 'h7'), 2);
      expect(holdsForBoss(events, 'h15'), 1);
    });

    test('vaincu au seuil (3), pas avant', () {
      final two = [for (var i = 0; i < 2; i++) _held('h7', i: i)];
      expect(defeatedBossKeys(two), isEmpty);
      final three = [for (var i = 0; i < 3; i++) _held('h7', i: i)];
      expect(defeatedBossKeys(three), {'h7'});
    });

    test('les délais non attribués (payload nul) ne vainquent personne', () {
      final events = [for (var i = 0; i < 5; i++) _held(null, i: i)];
      expect(defeatedBossKeys(events), isEmpty);
    });
  });

  group('pendingBossVictory', () {
    test('un Boss vaincu non révélé → à célébrer', () {
      final events = [for (var i = 0; i < 3; i++) _held('h7', i: i)];
      expect(pendingBossVictory(events), 'h7');
    });
    test('déjà révélé → plus rien', () {
      final events = [
        for (var i = 0; i < 3; i++) _held('h7', i: i),
        _defeated('h7'),
      ];
      expect(pendingBossVictory(events), isNull);
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
