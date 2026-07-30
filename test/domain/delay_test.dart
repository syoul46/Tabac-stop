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
  final now = DateTime(2026, 7, 30, 15, 0); // 15 h, jour logique du 30

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

  test('tenu aujourd\'hui → held', () {
    final events = [
      evt(JourneyEventKind.delayStarted, now.subtract(const Duration(minutes: 20))),
      evt(JourneyEventKind.delayHeld, now.subtract(const Duration(minutes: 10))),
    ];
    expect(resolveDelay(events, now).status, DelayStatus.held);
  });

  test('rompu aujourd\'hui → broken (une seule tentative par jour)', () {
    final events = [
      evt(JourneyEventKind.delayStarted, now.subtract(const Duration(minutes: 5))),
      evt(JourneyEventKind.delayBroken, now.subtract(const Duration(minutes: 4))),
    ];
    expect(resolveDelay(events, now).status, DelayStatus.broken);
  });

  test('délai tenu hier n\'affecte pas aujourd\'hui → available', () {
    final yesterday = now.subtract(const Duration(days: 1));
    final events = [
      evt(JourneyEventKind.delayStarted, yesterday),
      evt(JourneyEventKind.delayHeld, yesterday.add(const Duration(minutes: 10))),
    ];
    expect(resolveDelay(events, now).status, DelayStatus.available);
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
