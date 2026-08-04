import 'dart:convert';

import 'package:cairn/data/database.dart';
import 'package:cairn/domain/health/milestones.dart';
import 'package:cairn/domain/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

Cigarette _cigAt(DateTime utc) => Cigarette(
      id: 'x',
      occurredAtUtc: utc,
      tzOffsetMin: 0,
      wasBoss: false,
      duringDelay: false,
    );

void main() {
  group('table', () {
    test('triée par durée croissante', () {
      for (var i = 1; i < kHealthMilestones.length; i++) {
        expect(kHealthMilestones[i].after > kHealthMilestones[i - 1].after, isTrue);
      }
    });
    test('altitudes croissantes', () {
      for (var i = 1; i < kHealthMilestones.length; i++) {
        expect(kHealthMilestones[i].altitudeMeters >
            kHealthMilestones[i - 1].altitudeMeters, isTrue);
      }
    });
  });

  group('currentAbstinence', () {
    test('zéro si aucune cigarette', () {
      expect(currentAbstinence(const [], DateTime.now()), Duration.zero);
    });
    test('now − dernière (prend le max, liste non triée)', () {
      final now = DateTime.utc(2026, 1, 2, 12);
      final cigs = [
        _cigAt(DateTime.utc(2026, 1, 1, 12)), // -24 h
        _cigAt(DateTime.utc(2026, 1, 2, 6)), // -6 h  (la plus récente)
        _cigAt(DateTime.utc(2026, 1, 1, 20)),
      ];
      // now est en UTC ; occurredAt.toLocal() dépend du fuseau machine, donc on
      // compare l'ordre de grandeur (~6 h) sans exiger la précision au fuseau.
      final d = currentAbstinence(cigs, now.toLocal());
      expect(d.inHours, inInclusiveRange(5, 7));
    });
    test('jamais négatif si l’horloge est en retard', () {
      final last = DateTime.utc(2026, 1, 2, 12);
      final d = currentAbstinence([_cigAt(last)], last.toLocal().subtract(const Duration(hours: 1)));
      expect(d, Duration.zero);
    });
  });

  group('reachedIndex / milestoneAt / next', () {
    test('sous le premier palier', () {
      const d = Duration(minutes: 10);
      expect(reachedIndex(d), -1);
      expect(milestoneAt(d), isNull);
      expect(nextMilestoneAfter(d)!.after, const Duration(minutes: 20));
    });
    test('paliers ajoutés entre 20 min et 72 h', () {
      expect(nextMilestoneAfter(const Duration(minutes: 20))!.title, '2 heures');
      expect(milestoneAt(const Duration(hours: 2))!.altitudeMeters, 400);
      expect(milestoneAt(const Duration(hours: 12))!.title, '12 heures');
      expect(milestoneAt(const Duration(hours: 12))!.altitudeMeters, 800);
    });
    test('pile sur un palier (borne incluse)', () {
      expect(milestoneAt(const Duration(hours: 24))!.title, '24 heures');
    });
    test('entre deux paliers', () {
      const d = Duration(hours: 30); // ≥24 h, <48 h
      expect(milestoneAt(d)!.altitudeMeters, 1000);
      expect(nextMilestoneAfter(d)!.title, '48 heures');
    });
    test('tous atteints → next null', () {
      expect(nextMilestoneAfter(const Duration(days: 400)), isNull);
      expect(milestoneAt(const Duration(days: 400))!.title, '1 an');
    });
  });

  group('pendingMilestoneReveal', () {
    test('révèle le plus haut atteint non encore révélé', () {
      final m = pendingMilestoneReveal(
        abstinence: const Duration(hours: 30), // atteint 24 h (index 4)
        highestRevealed: 1, // 2 h déjà révélé
      );
      expect(m!.title, '24 heures');
    });
    test('rien à révéler si déjà au niveau', () {
      final m = pendingMilestoneReveal(
        abstinence: const Duration(hours: 30), // 24 h = index 4
        highestRevealed: 4,
      );
      expect(m, isNull);
    });
  });

  group('highestRevealedIndex', () {
    test('déduit du plus haut seuil en minutes', () {
      final set = {
        const Duration(hours: 8).inMinutes,
        const Duration(hours: 24).inMinutes,
      };
      expect(highestRevealedIndex(set), 4); // index de 24 h
    });
    test('vide → -1', () {
      expect(highestRevealedIndex(const {}), -1);
    });
  });

  group('revealedMinutesSince (rejoue après une rechute)', () {
    JourneyEvent revealed(int afterMinutes, DateTime at) => JourneyEvent(
          id: 'r$afterMinutes${at.millisecondsSinceEpoch}',
          occurredAtUtc: at,
          kind: JourneyEventKind.milestoneRevealed.name,
          payload: jsonEncode({'afterMinutes': afterMinutes}),
        );

    test('ne garde que les paliers révélés après la dernière cigarette', () {
      final lastCig = DateTime.utc(2026, 1, 2, 10);
      final events = [
        // Montée précédente (avant la dernière cigarette) → ignorée.
        revealed(20, DateTime.utc(2026, 1, 1, 8)),
        revealed(120, DateTime.utc(2026, 1, 1, 10)),
        // Montée en cours (après la dernière cigarette) → comptée.
        revealed(20, DateTime.utc(2026, 1, 2, 11)),
      ];
      final since = revealedMinutesSince(events, lastCig);
      expect(since, {20});
      // Donc, à 25 h d'abstinence, tout est de nouveau à révéler à partir de 2 h.
      expect(highestRevealedIndex(since), 0); // seul 20 min (index 0) est vu
    });

    test('sans cigarette (since null) : tout compte', () {
      final events = [
        revealed(20, DateTime.utc(2026, 1, 1, 8)),
        revealed(480, DateTime.utc(2026, 1, 1, 16)),
      ];
      expect(revealedMinutesSince(events, null), {20, 480});
    });
  });
}
