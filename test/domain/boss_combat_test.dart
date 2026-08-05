import 'dart:convert';

import 'package:cairn/data/database.dart';
import 'package:cairn/domain/boss/boss.dart';
import 'package:cairn/domain/boss/victory.dart';
import 'package:cairn/domain/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

Boss _boss({double hardness = 0.2, int hour = 7}) => Boss(
      centerMinute: hour * 60,
      spreadMinutes: 5,
      occurrences: 10,
      daysPresent: 5,
      context: null,
      contextConsistency: 1,
      anchor: 0.5,
      hardness: hardness,
    );

JourneyEvent _held(String key, int i) => JourneyEvent(
      id: 'h$i',
      occurredAtUtc: DateTime.utc(2026, 1, 1).add(Duration(days: i)),
      kind: JourneyEventKind.delayHeld.name,
      payload: jsonEncode({'bossKey': key}),
    );

JourneyEvent _broken(String key, int i) => JourneyEvent(
      id: 'b$i',
      occurredAtUtc: DateTime.utc(2026, 1, 1).add(Duration(days: i)),
      kind: JourneyEventKind.delayBroken.name,
      payload: jsonEncode({'bossKey': key}),
    );

void main() {
  test('PV max par difficulté (fragile 3 · tenace 4 · coriace 5)', () {
    expect(bossMaxHp(_boss(hardness: 0.2)), 3);
    expect(bossMaxHp(_boss(hardness: 0.5)), 4);
    expect(bossMaxHp(_boss(hardness: 0.8)), 5);
  });

  test('un délai tenu enlève 1 PV, une cigarette en redonne 1', () {
    final b = _boss(hardness: 0.2); // PVmax 3, clé h7
    final k = bossKey(b);
    expect(bossHp(b, const []), 3); // frais → plein
    expect(bossHp(b, [_held(k, 0), _held(k, 1)]), 1); // 3 − 2
    expect(bossHp(b, [_held(k, 0), _held(k, 1), _broken(k, 2)]), 2); // 3 − 2 + 1
  });

  test('vaincu à 0 PV (3 délais tenus sur un fragile)', () {
    final b = _boss(hardness: 0.2);
    final k = bossKey(b);
    final e = [_held(k, 0), _held(k, 1), _held(k, 2)];
    expect(bossHp(b, e), 0);
    expect(isBossDefeated(b, e), isTrue);
  });

  test('PV bornés : jamais < 0 ni > PVmax', () {
    final b = _boss(hardness: 0.2); // max 3
    final k = bossKey(b);
    expect(bossHp(b, [for (var i = 0; i < 5; i++) _held(k, i)]), 0); // pas négatif
    expect(bossHp(b, [_broken(k, 0), _broken(k, 1), _broken(k, 2)]), 3); // pas > max
  });

  test('plus coriace = plus de PV : le coriace tient 5 délais', () {
    final b = _boss(hardness: 0.8); // max 5
    final k = bossKey(b);
    final held4 = [for (var i = 0; i < 4; i++) _held(k, i)];
    expect(isBossDefeated(b, held4), isFalse); // 5 − 4 = 1
    expect(isBossDefeated(b, [...held4, _held(k, 4)]), isTrue); // 5 − 5 = 0
  });

  test('les événements d’un autre Boss ne comptent pas', () {
    final b = _boss(hardness: 0.2, hour: 7); // clé h7
    final e = [_held('h15', 0), _held('h15', 1), _broken('h15', 2)];
    expect(bossHp(b, e), 3); // aucun tag h7 → PV pleins
  });
}
