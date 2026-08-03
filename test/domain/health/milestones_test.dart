import 'package:cairn/data/database.dart';
import 'package:cairn/domain/health/milestones.dart';
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

  group('pendingMilestoneReveal (révélation une fois pour toutes)', () {
    test('révèle le plus haut atteint non encore révélé', () {
      final m = pendingMilestoneReveal(
        abstinence: const Duration(hours: 30), // atteint 24 h (index 2)
        highestRevealed: 1, // 8 h déjà révélé
      );
      expect(m!.title, '24 heures');
    });
    test('rien à révéler si déjà au niveau', () {
      final m = pendingMilestoneReveal(
        abstinence: const Duration(hours: 30),
        highestRevealed: 2,
      );
      expect(m, isNull);
    });
    test('rechute puis re-montée ne re-révèle pas', () {
      // Déjà révélé jusqu'à 72 h (index 4). Re-montée à 25 h → rien.
      final m = pendingMilestoneReveal(
        abstinence: const Duration(hours: 25),
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
      expect(highestRevealedIndex(set), 2); // index de 24 h
    });
    test('vide → -1', () {
      expect(highestRevealedIndex(const {}), -1);
    });
  });
}
