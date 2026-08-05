import 'dart:convert';

import '../../data/database.dart';
import '../models/enums.dart';
import 'boss.dart';

/// Nombre de délais tenus (un par jour) sur un même Boss pour le **vaincre**.
const kBossVictoryHolds = 3;

/// Clé stable d'un Boss = son heure murale (les clusters sont horaires).
String bossKey(Boss b) => 'h${b.hour}';

String? _payloadBossKey(JourneyEvent e) {
  final p = e.payload;
  if (p == null) return null;
  final m = jsonDecode(p);
  if (m is Map) {
    final k = m['bossKey'];
    if (k is String) return k;
  }
  return null;
}

/// Nombre de délais tenus attribués à ce Boss.
int holdsForBoss(List<JourneyEvent> events, String key) => events
    .where((e) =>
        e.kind == JourneyEventKind.delayHeld.name && _payloadBossKey(e) == key)
    .length;

// ── Combat par points de vie (spec PLAN §15) ────────────────────────────────
// PV = PVmax − délais tenus + cigarettes fumées contre le Boss, borné [0, PVmax].
// Chaque délai tenu entame le Boss (−1) ; chaque cigarette le soigne (+1). On ne
// le vainc que si le net penche du bon côté. Le cairn, lui, ne recule jamais.

/// PV max d'un Boss selon sa difficulté = nb de délais tenus *nets* pour le
/// vaincre : fragile 3 · tenace 4 · coriace 5.
int bossMaxHp(Boss b) => switch (b.difficulty) {
      BossDifficulty.easy => 3,
      BossDifficulty.medium => 4,
      BossDifficulty.hard => 5,
    };

/// Soins reçus = cigarettes fumées contre ce Boss (event `delayBroken` tagué).
int healsForBoss(List<JourneyEvent> events, String key) => events
    .where((e) =>
        e.kind == JourneyEventKind.delayBroken.name &&
        _payloadBossKey(e) == key)
    .length;

/// PV courants du Boss, bornés [0, PVmax].
int bossHp(Boss b, List<JourneyEvent> events) {
  final k = bossKey(b);
  final hp = bossMaxHp(b) - holdsForBoss(events, k) + healsForBoss(events, k);
  return hp.clamp(0, bossMaxHp(b));
}

/// Vaincu quand ses PV tombent à 0.
bool isBossDefeated(Boss b, List<JourneyEvent> events) => bossHp(b, events) == 0;

/// Les Boss **vaincus** = ceux dont le seuil de délais tenus est atteint.
/// Purement dérivé du journal (jamais stocké comme vérité).
Set<String> defeatedBossKeys(List<JourneyEvent> events) {
  final counts = <String, int>{};
  for (final e in events) {
    if (e.kind != JourneyEventKind.delayHeld.name) continue;
    final k = _payloadBossKey(e);
    if (k != null) counts.update(k, (v) => v + 1, ifAbsent: () => 1);
  }
  return {
    for (final entry in counts.entries)
      if (entry.value >= kBossVictoryHolds) entry.key,
  };
}

/// Clés des Boss dont la victoire a déjà été révélée (event `bossDefeated`).
Set<String> revealedVictoryKeys(List<JourneyEvent> events) => {
      for (final e in events)
        if (e.kind == JourneyEventKind.bossDefeated.name)
          if (_payloadBossKey(e) != null) _payloadBossKey(e)!,
    };

/// La victoire à révéler maintenant : un Boss vaincu dont la victoire n'a pas
/// encore été annoncée. null s'il n'y a rien à célébrer.
String? pendingBossVictory(List<JourneyEvent> events) {
  final revealed = revealedVictoryKeys(events);
  for (final k in defeatedBossKeys(events)) {
    if (!revealed.contains(k)) return k;
  }
  return null;
}

/// Prochaine cible = le Boss le plus fragile **pas encore vaincu**. null si tous
/// vaincus (ou aucun Boss).
Boss? nextTarget(BossReport report, Set<String> defeated) {
  final live = [
    for (final b in report.bosses)
      if (!defeated.contains(bossKey(b))) b,
  ];
  if (live.isEmpty) return null;
  return live.reduce((a, b) => a.hardness <= b.hardness ? a : b);
}

/// Le Boss correspondant à une clé, s'il est encore dans le rapport.
Boss? bossForKey(BossReport report, String key) {
  for (final b in report.bosses) {
    if (bossKey(b) == key) return b;
  }
  return null;
}
