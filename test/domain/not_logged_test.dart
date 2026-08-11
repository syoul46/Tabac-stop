import 'dart:convert';

import 'package:cairn/domain/journey/not_logged.dart';
import 'package:cairn/domain/metrics/metrics.dart';
import 'package:cairn/domain/models/enums.dart';
import 'package:cairn/data/database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

JourneyEvent _skipped(DateTime day) => JourneyEvent(
      id: 'e-${dayKey(day)}',
      occurredAtUtc: DateTime.utc(2026, 8, 1),
      kind: JourneyEventKind.dayNotLogged.name,
      payload: jsonEncode({'day': dayKey(day)}),
    );

void main() {
  group('notLoggedDays', () {
    test('extrait les jours déclarés, ignore le reste', () {
      final events = [
        _skipped(DateTime(2026, 7, 26)),
        JourneyEvent(
          id: 'x',
          occurredAtUtc: DateTime.utc(2026, 7, 27),
          kind: JourneyEventKind.delayHeld.name,
        ),
      ];
      expect(notLoggedDays(events), {DateTime(2026, 7, 26)});
    });

    test('payload illisible → ignoré, pas de crash', () {
      final events = [
        JourneyEvent(
          id: 'x',
          occurredAtUtc: DateTime.utc(2026, 7, 27),
          kind: JourneyEventKind.dayNotLogged.name,
          payload: 'pas du json',
        ),
      ];
      expect(notLoggedDays(events), isEmpty);
    });
  });

  group('un jour oublié ne doit pas devenir une victoire', () {
    // Fumeur régulier : 25 et 27 juillet tapés, le 26 « oublié ».
    final cigs = [
      cigWall(2026, 7, 25, 9, 0, id: 'a'),
      cigWall(2026, 7, 25, 20, 0, id: 'b'),
      cigWall(2026, 7, 27, 9, 0, id: 'c'),
      cigWall(2026, 7, 27, 20, 0, id: 'd'),
    ];
    final now = DateTime(2026, 7, 28, 12, 0);
    final skipped = {DateTime(2026, 7, 26)};

    test('sans déclaration, le trou est compté propre (le bug qu\'on corrige)',
        () {
      expect(cumulativeCleanDays(cigs, now), 1);
    });

    test('déclaré, le jour devient neutre', () {
      expect(cumulativeCleanDays(cigs, now, notLogged: skipped), 0);
    });

    test('un écart qui enjambe un jour déclaré ne peut pas être un record', () {
      // 25 à 20 h → 27 à 9 h = 37 h, le plus long de la série.
      expect(recordGap(cigs, now).inHours, 37);
      // Déclaré : ce faux record est disqualifié. Ce qui reste (11 h entre deux
      // cigarettes, ou l'abstinence en cours) est forcément plus court.
      expect(recordGap(cigs, now, notLogged: skipped),
          lessThan(const Duration(hours: 37)));
    });

    test('l\'abstinence en cours est disqualifiée si elle enjambe un trou', () {
      final recent = [cigWall(2026, 7, 25, 20, 0)];
      expect(
        recordGap(recent, now, notLogged: skipped),
        Duration.zero, // rien de prouvable : ni écart, ni record
      );
    });

    test('un jour déclaré ne touche pas aux jours réellement propres', () {
      // 26 déclaré, mais le 28 est un vrai jour sans tabac terminé.
      final later = DateTime(2026, 7, 29, 12, 0);
      expect(cumulativeCleanDays(cigs, later, notLogged: skipped), 1);
    });
  });
}
