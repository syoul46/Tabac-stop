import 'dart:convert';

import '../../core/time/logical_day.dart';
import '../../data/database.dart';
import '../metrics/hourly.dart';
import '../models/enums.dart';
import 'boss.dart';

/// Clé stable d'un Boss = son heure murale (les clusters sont horaires).
String bossKey(Boss b) => 'h${b.hour}';

// ── Combat par points de vie — v2, exigence de régularité (spec PLAN §15) ────
// La victoire se gagne sur des JOURS distincts, à l'HEURE du Boss :
//   PV = clamp(PVmax − joursEntamés + joursCraqués, 0, PVmax)
// - jour « entamé »  : ≥ 1 délai tenu dans la fenêtre horaire du Boss → −1 PV.
// - jour « craqué »  : ≥ 1 cigarette dans la fenêtre → +1 PV (le Boss se resoigne).
// Plusieurs délais/cigarettes le même jour comptent pour UN. Tout est dérivé des
// horodatages : aucun besoin de taguer les events avec le Boss. Le cairn, lui,
// monte de tout délai tenu (ailleurs) — c'est découplé, il ne recule jamais.

/// Demi-largeur de la fenêtre horaire d'un Boss (minutes), cohérent avec le
/// rayon de clustering `epsMinutes = 25` de la détection.
const int kBossWindowMin = 30;

/// PV max d'un Boss selon sa difficulté = nb de **jours** distincts à tenir pour
/// le vaincre : fragile 3 · tenace 4 · coriace 5.
int bossMaxHp(Boss b) => switch (b.difficulty) {
      BossDifficulty.easy => 3,
      BossDifficulty.medium => 4,
      BossDifficulty.hard => 5,
    };

/// Vrai si l'heure murale [wall] tombe dans la fenêtre du Boss (± [kBossWindowMin]).
/// Distance circulaire sur 24 h (gère le passage de minuit).
bool bossWindowContains(Boss b, DateTime wall) {
  final m = wall.hour * 60 + wall.minute;
  var diff = (m - b.centerMinute).abs();
  if (diff > 720) diff = 1440 - diff;
  return diff <= kBossWindowMin;
}

/// Nombre de **jours logiques distincts** où au moins un délai a été tenu dans la
/// fenêtre du Boss (les dégâts). Un délai tenu ailleurs ne compte pas ici.
int daysEngaged(Boss b, List<JourneyEvent> events) {
  final days = <DateTime>{};
  for (final e in events) {
    if (e.kind != JourneyEventKind.delayHeld.name) continue;
    final w = e.occurredAtUtc.toLocal();
    if (bossWindowContains(b, w)) days.add(LogicalDay.dayOf(w));
  }
  return days.length;
}

/// Nombre de **jours logiques distincts** où au moins une cigarette a été fumée
/// dans la fenêtre du Boss (les soins — le Boss regagne 1 PV/jour craqué).
int daysCracked(Boss b, List<Cigarette> cigs) {
  final days = <DateTime>{};
  for (final c in cigs) {
    final w = wallTimeOf(c);
    if (bossWindowContains(b, w)) days.add(LogicalDay.dayOf(w));
  }
  return days.length;
}

/// PV courants du Boss, bornés [0, PVmax].
int bossHp(Boss b, List<Cigarette> cigs, List<JourneyEvent> events) {
  final hp = bossMaxHp(b) - daysEngaged(b, events) + daysCracked(b, cigs);
  return hp.clamp(0, bossMaxHp(b));
}

/// Vaincu quand ses PV tombent à 0.
bool isBossDefeated(Boss b, List<Cigarette> cigs, List<JourneyEvent> events) =>
    bossHp(b, cigs, events) == 0;

/// Les Boss **vaincus** = PV à 0, OU dont la victoire a déjà été célébrée (le
/// rocher ne retombe jamais).
Set<String> defeatedBossKeys(
  BossReport report,
  List<Cigarette> cigs,
  List<JourneyEvent> events,
) {
  final out = revealedVictoryKeys(events).toSet();
  for (final b in report.bosses) {
    if (bossHp(b, cigs, events) == 0) out.add(bossKey(b));
  }
  return out;
}

/// Clés des Boss dont la victoire a déjà été révélée (event `bossDefeated`).
Set<String> revealedVictoryKeys(List<JourneyEvent> events) => {
      for (final e in events)
        if (e.kind == JourneyEventKind.bossDefeated.name)
          if (_payloadBossKey(e) != null) _payloadBossKey(e)!,
    };

/// La victoire à révéler maintenant : un Boss à 0 PV dont la victoire n'a pas
/// encore été annoncée. null s'il n'y a rien à célébrer.
String? pendingBossVictory(
  BossReport report,
  List<Cigarette> cigs,
  List<JourneyEvent> events,
) {
  final revealed = revealedVictoryKeys(events);
  for (final b in report.bosses) {
    final k = bossKey(b);
    if (bossHp(b, cigs, events) == 0 && !revealed.contains(k)) return k;
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
