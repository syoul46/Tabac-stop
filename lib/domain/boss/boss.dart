import 'dart:math' as math;

import '../../data/database.dart';
import '../metrics/hourly.dart';
import '../metrics/metrics.dart';
import '../models/enums.dart';

/// Difficulté estimée pour s'attaquer à un Boss.
enum BossDifficulty { easy, medium, hard }

/// Un Boss = une cigarette qui revient chaque jour à peu près à la même heure,
/// idéalement liée à un contexte. C'est ce qui rend la révélation impossible à
/// obtenir ailleurs.
class Boss {
  const Boss({
    required this.centerMinute,
    required this.spreadMinutes,
    required this.occurrences,
    required this.daysPresent,
    required this.context,
    required this.contextConsistency,
    required this.anchor,
    required this.hardness,
  });

  /// Heure centrale du cluster, en minutes depuis minuit (heure murale locale).
  final int centerMinute;

  /// Écart-type des heures du cluster (minutes) — régularité.
  final double spreadMinutes;

  final int occurrences;
  final int daysPresent;

  /// Contexte dominant (ou null si aucun renseigné).
  final CigContext? context;

  /// Cohérence du contexte dans le cluster (1.0 si absent ou totalement cohérent).
  final double contextConsistency;

  /// Score d'ancrage 0..1 : récurrence × régularité × cohérence de contexte.
  final double anchor;

  /// Dureté 0..1 : plus c'est haut, plus le Boss est dur à déloger.
  final double hardness;

  BossDifficulty get difficulty => hardness < 0.35
      ? BossDifficulty.easy
      : hardness < 0.65
          ? BossDifficulty.medium
          : BossDifficulty.hard;

  int get hour => centerMinute ~/ 60;

  /// « 7 h 10 », « 21 h ».
  String get timeLabel {
    final m = centerMinute % 60;
    return m == 0 ? '$hour h' : '$hour h ${m.toString().padLeft(2, '0')}';
  }

  /// Nom donné au Boss dans la révélation, ex. « le Café de 7 h 10 ».
  String get name {
    switch (context) {
      case CigContext.cafe:
        return 'le Café de $timeLabel';
      case CigContext.repas:
        return 'le Repas de $timeLabel';
      case CigContext.alcool:
        return 'le Verre de $timeLabel';
      case null:
        return 'la cigarette de $timeLabel';
    }
  }
}

/// Rapport de détection : les Boss classés par ancrage, plus les deux choix qui
/// gouvernent le parcours — celui qu'on NOMME (le plus ancré) et celui qu'on
/// ATTAQUE en premier (le plus facile).
class BossReport {
  const BossReport({
    required this.bosses,
    required this.mostAnchored,
    required this.easiestTarget,
  });

  static const empty =
      BossReport(bosses: [], mostAnchored: null, easiestTarget: null);

  /// Classés par ancrage décroissant.
  final List<Boss> bosses;

  /// Le plus ancré → nommé à la révélation J+3.
  final Boss? mostAnchored;

  /// Le plus fragile → première cible J4 (garantir une victoire).
  final Boss? easiestTarget;

  bool get isEmpty => bosses.isEmpty;
}

int _minuteOfDay(Cigarette c) {
  final w = wallTimeOf(c);
  return w.hour * 60 + w.minute;
}

/// Détecte les Boss par clustering 1D (type DBSCAN) sur l'heure murale locale.
///
/// [epsMinutes] : rayon de voisinage. Un cluster n'est retenu comme Boss que
/// s'il est présent sur au moins 60 % des jours (récurrence réelle).
BossReport detectBosses(
  Iterable<Cigarette> input, {
  double epsMinutes = 25,
}) {
  final cigs = input.toList();
  if (cigs.isEmpty) return BossReport.empty;

  final totalDays = distinctLogicalDays(cigs);
  if (totalDays < 2) return BossReport.empty;

  final minPresence = math.max(2, (0.6 * totalDays).ceil());

  final minutes = [for (final c in cigs) _minuteOfDay(c)];
  final clusters = _dbscan(minutes, epsMinutes, minPresence);

  final bosses = <Boss>[];
  for (final cluster in clusters) {
    final members = [for (final i in cluster) cigs[i]];
    final daysPresent = distinctLogicalDays(members);
    if (daysPresent < minPresence) continue; // doit revenir la plupart des jours

    final ms = [for (final i in cluster) minutes[i]];
    final center = (ms.reduce((a, b) => a + b) / ms.length).round();
    final spread = _stdDev(ms);

    final ctx = _dominantContext(members);
    final recurrence = daysPresent / totalDays;
    final regularity = 1 - math.min(spread / epsMinutes, 1.0);
    final anchor = recurrence * regularity * ctx.consistency;

    bosses.add(Boss(
      centerMinute: center,
      spreadMinutes: spread,
      occurrences: members.length,
      daysPresent: daysPresent,
      context: ctx.context,
      contextConsistency: ctx.consistency,
      anchor: anchor,
      hardness: _hardness(center, anchor, ctx.context),
    ));
  }

  if (bosses.isEmpty) return BossReport.empty;
  bosses.sort((a, b) => b.anchor.compareTo(a.anchor));

  final easiest =
      bosses.reduce((a, b) => a.hardness <= b.hardness ? a : b);

  return BossReport(
    bosses: bosses,
    mostAnchored: bosses.first,
    easiestTarget: easiest,
  );
}

double _hardness(int centerMinute, double anchor, CigContext? context) {
  var h = anchor * 0.5; // plus c'est ancré, plus c'est dur
  final hour = centerMinute ~/ 60;
  if (hour >= 6 && hour < 9) h += 0.4; // la première du matin
  if (context == CigContext.alcool) h += 0.4; // l'apéro / le social
  if (hour >= 14 && hour < 17) h -= 0.2; // le creux d'après-midi, plus fragile
  return h.clamp(0.0, 1.0);
}

({CigContext? context, double consistency}) _dominantContext(
    List<Cigarette> members) {
  final counts = <int, int>{};
  for (final c in members) {
    final a = c.contextA;
    if (a != null) counts.update(a, (v) => v + 1, ifAbsent: () => 1);
  }
  if (counts.isEmpty) return (context: null, consistency: 1.0);
  final withCtx = counts.values.reduce((a, b) => a + b);
  final best = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
  return (
    context: CigContext.values[best.key],
    consistency: 0.7 + 0.3 * (best.value / withCtx),
  );
}

double _stdDev(List<int> xs) {
  if (xs.length < 2) return 0;
  final mean = xs.reduce((a, b) => a + b) / xs.length;
  final variance =
      xs.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) /
          xs.length;
  return math.sqrt(variance);
}

/// DBSCAN 1D O(n²) — suffisant pour le volume d'un journal de cigarettes.
List<List<int>> _dbscan(List<int> values, double eps, int minPts) {
  const unvisited = -2;
  const noise = -1;
  final n = values.length;
  final labels = List<int>.filled(n, unvisited);

  List<int> region(int i) => [
        for (var j = 0; j < n; j++)
          if ((values[j] - values[i]).abs() <= eps) j,
      ];

  var clusterId = -1;
  for (var i = 0; i < n; i++) {
    if (labels[i] != unvisited) continue;
    final neighbors = region(i);
    if (neighbors.length < minPts) {
      labels[i] = noise;
      continue;
    }
    clusterId++;
    labels[i] = clusterId;
    final seeds = [
      for (final j in neighbors)
        if (j != i) j
    ];
    for (var k = 0; k < seeds.length; k++) {
      final q = seeds[k];
      if (labels[q] == noise) labels[q] = clusterId;
      if (labels[q] != unvisited) continue;
      labels[q] = clusterId;
      final qn = region(q);
      if (qn.length >= minPts) {
        for (final x in qn) {
          if (!seeds.contains(x)) seeds.add(x);
        }
      }
    }
  }

  final clusters = <int, List<int>>{};
  for (var i = 0; i < n; i++) {
    if (labels[i] >= 0) clusters.putIfAbsent(labels[i], () => []).add(i);
  }
  return clusters.values.toList();
}
