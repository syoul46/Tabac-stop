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

  test('stonesPlaced compte les délais tenus', () {
    final events = [
      evt(JourneyEventKind.delayHeld, now.subtract(const Duration(days: 2))),
      evt(JourneyEventKind.delayBroken, now.subtract(const Duration(days: 1))),
      evt(JourneyEventKind.delayHeld, now),
    ];
    expect(stonesPlaced(events), 2);
  });
}
