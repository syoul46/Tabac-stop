import 'package:cairn/domain/metrics/avoided.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  // Observation : 4 jours à 12/jour (1ᵉʳ au 4 janvier), puis le mode est choisi.
  final observation = [
    for (var d = 1; d <= 4; d++)
      for (var h = 8; h < 20; h++) cigWall(2026, 1, d, h, 0, id: 'o$d-$h'),
  ];
  final modeSince = DateTime.utc(2026, 1, 5, 4, 0);

  group('référence', () {
    test('moyenne/jour de la phase d\'observation', () {
      expect(baselinePerDay(observation, modeSince), 12);
    });

    test('silencieuse tant qu\'on n\'a pas de quoi l\'estimer', () {
      final deuxJours = [
        for (var d = 1; d <= 2; d++)
          for (var h = 8; h < 20; h++) cigWall(2026, 1, d, h, 0, id: 'x$d-$h'),
      ];
      expect(baselinePerDay(deuxJours, modeSince), isNull);
    });

    test('sans mode choisi, aucune référence', () {
      expect(baselinePerDay(observation, null), isNull);
    });

    test('ne bouge pas quand on réduit — c\'est tout l\'intérêt', () {
      // Deux jours de réduction à 4/jour : la référence reste 12.
      final apres = [
        ...observation,
        for (var d = 5; d <= 6; d++)
          for (var h = 8; h < 12; h++) cigWall(2026, 1, d, h, 0, id: 'r$d-$h'),
      ];
      expect(baselinePerDay(apres, modeSince), 12);
    });
  });

  group('évitées', () {
    test('un jour à 4 cigarettes sur une référence de 12 → 8 évitées', () {
      final jour = [
        for (var h = 8; h < 12; h++) cigWall(2026, 1, 5, h, 0, id: 'j$h'),
      ];
      expect(avoidedOn(jour, 12, DateTime(2026, 1, 5, 10, 0)), 8);
    });

    test('fumer plus que son rythme d\'avant ne crée pas de dette', () {
      final gros = [
        for (var h = 0; h < 20; h++) cigWall(2026, 1, 5, h, 0, id: 'g$h'),
      ];
      expect(avoidedOn(gros, 12, DateTime(2026, 1, 5, 10, 0)), 0);
    });

    test('cumul sur les jours terminés, la journée en cours exclue', () {
      final apres = [
        ...observation,
        for (var d = 5; d <= 6; d++)
          for (var h = 8; h < 12; h++) cigWall(2026, 1, d, h, 0, id: 'r$d-$h'),
      ];
      // On est le 7 : les 5 et 6 sont terminés (8 évitées chacun), pas le 7.
      final now = DateTime(2026, 1, 7, 10, 0);
      expect(avoidedSince(apres, modeSince, now), 16);
    });

    test('un jour déclaré « pas tapé » ne rapporte rien', () {
      final apres = [
        ...observation,
        for (var h = 8; h < 12; h++) cigWall(2026, 1, 5, h, 0, id: 'r5-$h'),
        // le 6 : rien de tapé, et l'utilisateur l'a déclaré
      ];
      final now = DateTime(2026, 1, 7, 10, 0);
      expect(avoidedSince(apres, modeSince, now), 8 + 12); // 5ᵉ : 8, 6ᵉ : 12
      expect(
        avoidedSince(apres, modeSince, now,
            notLogged: {DateTime(2026, 1, 6)}),
        8, // le 6 ne compte plus : pas de preuve, pas de mérite
      );
    });

    test('sans référence, on ne prétend rien', () {
      expect(avoidedSince(observation, null, DateTime(2026, 1, 7)), 0);
    });
  });
}
