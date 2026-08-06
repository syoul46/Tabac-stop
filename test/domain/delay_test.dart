import 'package:cairn/data/database.dart';
import 'package:cairn/domain/journey/delay.dart';
import 'package:cairn/domain/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

JourneyEvent evt(JourneyEventKind kind, DateTime whenLocal) => JourneyEvent(
      id: '${kind.name}-${whenLocal.millisecondsSinceEpoch}',
      occurredAtUtc: whenLocal.toUtc(),
      kind: kind.name,
    );

void main() {
  final now = DateTime(2026, 7, 30, 15, 0);

  test('aucun événement → available', () {
    expect(resolveDelay(const [], now).status, DelayStatus.available);
  });

  test('démarré il y a 3 min → running, endsAt = +10', () {
    final started = now.subtract(const Duration(minutes: 3));
    final s = resolveDelay([evt(JourneyEventKind.delayStarted, started)], now);
    expect(s.status, DelayStatus.running);
    expect(s.endsAt, started.add(const Duration(minutes: 10)));
  });

  test('démarré il y a 12 min, non finalisé → elapsed', () {
    final started = now.subtract(const Duration(minutes: 12));
    expect(resolveDelay([evt(JourneyEventKind.delayStarted, started)], now).status,
        DelayStatus.elapsed);
  });

  test('après un délai tenu → available (relançable, plus de « 1/jour »)', () {
    final events = [
      evt(JourneyEventKind.delayStarted, now.subtract(const Duration(minutes: 20))),
      evt(JourneyEventKind.delayHeld, now.subtract(const Duration(minutes: 10))),
    ];
    expect(resolveDelay(events, now).status, DelayStatus.available);
  });

  test('après une rupture → available (relançable)', () {
    final events = [
      evt(JourneyEventKind.delayStarted, now.subtract(const Duration(minutes: 5))),
      evt(JourneyEventKind.delayBroken, now.subtract(const Duration(minutes: 4))),
    ];
    expect(resolveDelay(events, now).status, DelayStatus.available);
  });

  test('juste tenu (< fenêtre de feedback) → held (moment de succès)', () {
    final events = [
      evt(JourneyEventKind.delayStarted, now.subtract(const Duration(minutes: 10))),
      evt(JourneyEventKind.delayHeld, now.subtract(const Duration(seconds: 2))),
    ];
    expect(resolveDelay(events, now).status, DelayStatus.held);
  });

  test('juste rompu (< fenêtre de feedback) → broken', () {
    final events = [
      evt(JourneyEventKind.delayStarted, now.subtract(const Duration(minutes: 3))),
      evt(JourneyEventKind.delayBroken, now.subtract(const Duration(seconds: 2))),
    ];
    expect(resolveDelay(events, now).status, DelayStatus.broken);
  });

  test('relance : un nouveau délai après une manche close → running', () {
    final events = [
      evt(JourneyEventKind.delayStarted, now.subtract(const Duration(minutes: 40))),
      evt(JourneyEventKind.delayHeld, now.subtract(const Duration(minutes: 30))),
      evt(JourneyEventKind.delayStarted, now.subtract(const Duration(minutes: 3))),
    ];
    final s = resolveDelay(events, now);
    expect(s.status, DelayStatus.running);
    expect(s.endsAt,
        now.subtract(const Duration(minutes: 3)).add(const Duration(minutes: 10)));
  });

  test('plusieurs manches le même jour possibles (2 tenus le même jour)', () {
    final events = [
      evt(JourneyEventKind.delayStarted, now.subtract(const Duration(hours: 3))),
      evt(JourneyEventKind.delayHeld,
          now.subtract(const Duration(hours: 2, minutes: 50))),
      evt(JourneyEventKind.delayStarted, now.subtract(const Duration(hours: 1))),
      evt(JourneyEventKind.delayHeld, now.subtract(const Duration(minutes: 50))),
    ];
    // Dernière manche close → available (on peut relancer une 3ᵉ fois).
    expect(resolveDelay(events, now).status, DelayStatus.available);
    expect(stonesPlaced(events), 2);
  });

  test('stonesPlaced compte les délais tenus + les pierres bonus', () {
    final events = [
      evt(JourneyEventKind.delayHeld, now.subtract(const Duration(days: 2))),
      evt(JourneyEventKind.delayBroken, now.subtract(const Duration(days: 1))),
      evt(JourneyEventKind.delayHeld, now),
      evt(JourneyEventKind.bonusStone, now),
      evt(JourneyEventKind.bonusStone, now),
    ];
    expect(stonesPlaced(events), 4); // 2 tenus + 2 bonus
  });

  group('pendingBonusStones (tenir au-delà des 10 min)', () {
    Cigarette cig(DateTime whenLocal) => Cigarette(
          id: 'c-${whenLocal.millisecondsSinceEpoch}',
          occurredAtUtc: whenLocal.toUtc(),
          tzOffsetMin: 0,
          contextA: null,
          wasBoss: false,
          duringDelay: false,
        );

    test('après un délai tenu : +1 à 20 min, +1 à 30 min (plafond 2)', () {
      final start = now.subtract(const Duration(minutes: 25));
      final events = [
        evt(JourneyEventKind.delayStarted, start),
        evt(JourneyEventKind.delayHeld, start.add(const Duration(minutes: 10))),
      ];
      // 25 min après le lancement → 1 bonus dû (20 min franchi, pas 30).
      expect(pendingBonusStones(events, const [], now), 1);
      // 35 min après → 2 bonus dus.
      expect(
        pendingBonusStones(
            events, const [], start.add(const Duration(minutes: 35))),
        2,
      );
    });

    test('ne compte pas ce qui est déjà posé', () {
      final start = now.subtract(const Duration(minutes: 35));
      final events = [
        evt(JourneyEventKind.delayStarted, start),
        evt(JourneyEventKind.delayHeld, start.add(const Duration(minutes: 10))),
        evt(JourneyEventKind.bonusStone, start.add(const Duration(minutes: 20))),
      ];
      expect(pendingBonusStones(events, const [], now), 1); // 2 dus − 1 posé
    });

    test('une cigarette depuis le lancement coupe le bonus', () {
      final start = now.subtract(const Duration(minutes: 35));
      final events = [
        evt(JourneyEventKind.delayStarted, start),
        evt(JourneyEventKind.delayHeld, start.add(const Duration(minutes: 10))),
      ];
      final cigs = [cig(start.add(const Duration(minutes: 15)))];
      expect(pendingBonusStones(events, cigs, now), 0);
    });

    test('pas de bonus si la manche n’a pas été tenue', () {
      final start = now.subtract(const Duration(minutes: 35));
      final events = [evt(JourneyEventKind.delayStarted, start)];
      expect(pendingBonusStones(events, const [], now), 0);
    });

    test('relancer un délai remet le bonus à zéro', () {
      final first = now.subtract(const Duration(minutes: 40));
      final events = [
        evt(JourneyEventKind.delayStarted, first),
        evt(JourneyEventKind.delayHeld, first.add(const Duration(minutes: 10))),
        // nouvelle manche relancée récemment, pas encore tenue
        evt(JourneyEventKind.delayStarted, now.subtract(const Duration(minutes: 2))),
      ];
      expect(pendingBonusStones(events, const [], now), 0);
    });
  });
}
