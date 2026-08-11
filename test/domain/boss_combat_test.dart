import 'package:cairn/data/database.dart';
import 'package:cairn/domain/boss/boss.dart';
import 'package:cairn/domain/boss/victory.dart';
import 'package:cairn/domain/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

Boss _boss({double hardness = 0.2, int hour = 7, int minute = 0}) => Boss(
      centerMinute: hour * 60 + minute,
      spreadMinutes: 5,
      occurrences: 10,
      daysPresent: 5,
      context: null,
      contextConsistency: 1,
      anchor: 0.5,
      hardness: hardness,
    );

/// Délai tenu à l'heure murale locale [h]:[m], le [day] janvier 2026.
/// (on construit en local puis `.toUtc()` : `bossHp` relit via `.toLocal()`.)
JourneyEvent heldAt(int day, int h, int m) => JourneyEvent(
      id: 'h-$day-$h-$m',
      occurredAtUtc: DateTime(2026, 1, day, h, m).toUtc(),
      kind: JourneyEventKind.delayHeld.name,
    );

/// Cigarette à l'heure murale [h]:[m] le [day] janvier 2026 (offset 0 →
/// `wallTimeOf` = l'heure UTC, indépendant du fuseau de test).
Cigarette cigAt(int day, int h, int m) => Cigarette(
      id: 'c-$day-$h-$m',
      occurredAtUtc: DateTime.utc(2026, 1, day, h, m),
      tzOffsetMin: 0,
      contextA: null,
      wasBoss: false,
      duringDelay: false,
    );

void main() {
  test('PV max par difficulté (fragile 3 · tenace 4 · coriace 5)', () {
    expect(bossMaxHp(_boss(hardness: 0.2)), 3);
    expect(bossMaxHp(_boss(hardness: 0.5)), 4);
    expect(bossMaxHp(_boss(hardness: 0.8)), 5);
  });

  group('bossWindowContains (heure ± 30 min, circulaire)', () {
    final b = _boss(hour: 7, minute: 10); // 7 h 10
    test('dans la fenêtre', () {
      expect(bossWindowContains(b, DateTime(2026, 1, 1, 7, 0)), isTrue);
      expect(bossWindowContains(b, DateTime(2026, 1, 1, 7, 39)), isTrue);
      expect(bossWindowContains(b, DateTime(2026, 1, 1, 6, 41)), isTrue);
    });
    test('hors fenêtre', () {
      expect(bossWindowContains(b, DateTime(2026, 1, 1, 8, 0)), isFalse);
      expect(bossWindowContains(b, DateTime(2026, 1, 1, 6, 0)), isFalse);
    });
    test('passage de minuit', () {
      final n = _boss(hour: 23, minute: 50); // 23 h 50
      expect(bossWindowContains(n, DateTime(2026, 1, 1, 0, 10)), isTrue); // +20
      expect(bossWindowContains(n, DateTime(2026, 1, 1, 1, 0)), isFalse);
    });
  });

  test('un jour entamé enlève 1 PV, un jour craqué en redonne 1', () {
    final b = _boss(hardness: 0.2); // PVmax 3, Boss 7 h
    expect(bossHp(b, const [], const []), 3); // frais → plein
    // 2 jours distincts entamés à l'heure → 3 − 2 = 1
    expect(bossHp(b, const [], [heldAt(1, 7, 0), heldAt(2, 7, 10)]), 1);
    // + 1 jour craqué (cigarette en fenêtre) → 3 − 2 + 1 = 2
    expect(
      bossHp(b, [cigAt(3, 7, 15)], [heldAt(1, 7, 0), heldAt(2, 7, 10)]),
      2,
    );
  });

  test('plusieurs délais le même jour = 1 seul jour de progrès (anti-rafale)', () {
    final b = _boss(hardness: 0.2); // PVmax 3
    final e = [heldAt(1, 6, 40), heldAt(1, 7, 0), heldAt(1, 7, 20)];
    expect(bossHp(b, const [], e), 2); // 3 − 1 (un seul jour)
    expect(isBossDefeated(b, const [], e), isFalse);
  });

  test('hors de sa fenêtre horaire, rien ne compte', () {
    final b = _boss(hardness: 0.2); // Boss 7 h
    // délais tenus à 9 h + cigarettes à 9 h → aucun effet
    final e = [heldAt(1, 9, 0), heldAt(2, 9, 0), heldAt(3, 9, 0)];
    expect(bossHp(b, [cigAt(1, 9, 0)], e), 3);
  });

  test('vaincu à 0 PV : 3 jours distincts entamés (fragile)', () {
    final b = _boss(hardness: 0.2);
    final e = [heldAt(1, 7, 0), heldAt(2, 7, 5), heldAt(3, 6, 55)];
    expect(bossHp(b, const [], e), 0);
    expect(isBossDefeated(b, const [], e), isTrue);
  });

  test('plusieurs cigarettes le même jour = 1 seul soin', () {
    final b = _boss(hardness: 0.2); // PVmax 3
    final e = [heldAt(1, 7, 0), heldAt(2, 7, 0), heldAt(3, 7, 0)]; // -3
    final cigs = [cigAt(1, 7, 20), cigAt(1, 7, 25), cigAt(1, 7, 28)]; // 1 jour
    expect(bossHp(b, cigs, e), 1); // 3 − 3 + 1
    expect(isBossDefeated(b, cigs, e), isFalse);
  });

  test('un même jour entamé ET craqué → net 0 ce jour-là', () {
    final b = _boss(hardness: 0.2);
    final e = [heldAt(1, 7, 0), heldAt(2, 7, 0), heldAt(3, 7, 0)]; // 3 jours
    final cigs = [cigAt(1, 7, 20)]; // jour 1 aussi craqué
    expect(bossHp(b, cigs, e), 1); // 3 − 3 + 1 → il faut un jour de plus
  });

  test('PV bornés : jamais < 0 ni > PVmax', () {
    final b = _boss(hardness: 0.2); // max 3
    final e = [for (var i = 1; i <= 5; i++) heldAt(i, 7, 0)];
    expect(bossHp(b, const [], e), 0); // pas négatif
    final cigs = [for (var i = 1; i <= 5; i++) cigAt(i, 7, 0)];
    expect(bossHp(b, cigs, const []), 3); // pas > max
  });

  test('plus coriace = plus de jours : le coriace tient 5 jours', () {
    final b = _boss(hardness: 0.8); // max 5
    final held4 = [for (var i = 1; i <= 4; i++) heldAt(i, 7, 0)];
    expect(isBossDefeated(b, const [], held4), isFalse); // 5 − 4 = 1
    expect(isBossDefeated(b, const [], [...held4, heldAt(5, 7, 0)]), isTrue);
  });

  test('engagedToday : entamé aujourd’hui uniquement (jour + fenêtre)', () {
    final b = _boss(hour: 7);
    final today = DateTime(2026, 1, 5, 12, 0); // jour logique 5
    expect(engagedToday(b, [heldAt(5, 7, 0)], today), isTrue);
    expect(engagedToday(b, [heldAt(4, 7, 0)], today), isFalse); // hier
    expect(engagedToday(b, [heldAt(5, 12, 0)], today), isFalse); // hors fenêtre
  });

  group('le combat ne compte qu\'à partir de son début (régression)', () {
    final b = _boss(hour: 14, minute: 0); // fragile → 3 PV
    // 8 jours d'observation : on fume à 14 h chaque jour, comme l'app l'invite
    // explicitement à le faire. Le combat ne commence qu'après.
    final observation = [for (var d = 1; d <= 8; d++) cigAt(d, 14, 0)];
    final fightStart = DateTime(2026, 1, 9, 0, 0).toUtc();

    test('sans borne, les jours d\'observation rendaient le Boss imbattable', () {
      // Le bug d'origine : 8 jours « craqués » hérités de l'observation.
      expect(daysCracked(b, observation), 8);
      final troisJoursParfaits = [for (var d = 9; d <= 11; d++) heldAt(d, 14, 0)];
      expect(bossHp(b, observation, troisJoursParfaits), 3); // aucun mouvement
    });

    test('borné au début du combat, l\'observation ne compte plus', () {
      expect(daysCracked(b, observation, since: fightStart), 0);
      expect(bossHp(b, observation, const [], since: fightStart), 3);
    });

    test('3 jours parfaits suffisent à abattre un Boss fragile', () {
      final held = [for (var d = 9; d <= 11; d++) heldAt(d, 14, 0)];
      expect(bossHp(b, observation, held, since: fightStart), 0);
      expect(isBossDefeated(b, observation, held, since: fightStart), isTrue);
    });

    test('craquer pendant le combat resoigne bien le Boss', () {
      final held = [for (var d = 9; d <= 11; d++) heldAt(d, 14, 0)];
      final cigs = [...observation, cigAt(10, 14, 5)]; // craqué le 2ᵉ jour
      expect(bossHp(b, cigs, held, since: fightStart), 1);
    });
  });
}
