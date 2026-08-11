import '../../core/time/logical_day.dart';
import '../../data/database.dart';
import 'hourly.dart';

/// Portrait chiffré dérivé du journal. C'est ce qui nourrit la révélation J+3.
/// Purement calculé — jamais stocké comme source de vérité.
class MetricsSummary {
  const MetricsSummary({
    required this.total,
    required this.days,
    required this.perDay,
    required this.medianGap,
    required this.meanGap,
    required this.busiestHour,
    required this.busiestWindow,
  });

  /// Nombre total de cigarettes considérées.
  final int total;

  /// Nombre de jours logiques distincts couverts.
  final int days;

  /// Moyenne par jour logique.
  final double perDay;

  /// Écart médian entre deux cigarettes (robuste aux nuits) ; null si < 2 taps.
  final Duration? medianGap;

  /// Écart moyen entre deux cigarettes ; null si < 2 taps.
  final Duration? meanGap;

  /// Heure locale (0–23) la plus chargée ; null si aucune donnée.
  final int? busiestHour;

  /// Créneau [début, fin[ (heures) le plus chargé ; null si aucune donnée.
  final (int start, int end)? busiestWindow;

  static const empty = MetricsSummary(
    total: 0,
    days: 0,
    perDay: 0,
    medianGap: null,
    meanGap: null,
    busiestHour: null,
    busiestWindow: null,
  );
}

/// Écarts entre cigarettes consécutives (liste triée chronologiquement requise).
List<Duration> gapsOf(List<Cigarette> chronological) {
  final gaps = <Duration>[];
  for (var i = 1; i < chronological.length; i++) {
    gaps.add(chronological[i]
        .occurredAtUtc
        .difference(chronological[i - 1].occurredAtUtc));
  }
  return gaps;
}

Duration? meanDuration(List<Duration> ds) {
  if (ds.isEmpty) return null;
  final totalMs = ds.fold<int>(0, (s, d) => s + d.inMilliseconds);
  return Duration(milliseconds: totalMs ~/ ds.length);
}

Duration? medianDuration(List<Duration> ds) {
  if (ds.isEmpty) return null;
  final sorted = [...ds]..sort();
  final n = sorted.length;
  if (n.isOdd) return sorted[n ~/ 2];
  final a = sorted[n ~/ 2 - 1].inMilliseconds;
  final b = sorted[n ~/ 2].inMilliseconds;
  return Duration(milliseconds: (a + b) ~/ 2);
}

int distinctLogicalDays(Iterable<Cigarette> cigs) {
  final days = <DateTime>{};
  for (final c in cigs) {
    days.add(LogicalDay.dayOf(wallTimeOf(c)));
  }
  return days.length;
}

/// Heure la plus chargée (le premier max l'emporte) ; null si tout est à zéro.
int? busiestHour(List<int> counts) {
  var best = 0;
  int? bestH;
  for (var h = 0; h < counts.length; h++) {
    if (counts[h] > best) {
      best = counts[h];
      bestH = h;
    }
  }
  return bestH;
}

/// Fenêtre de largeur [width] heures dont la somme est maximale (non circulaire).
/// En cas d'égalité, on préfère le créneau **le plus tardif** (le soir, plus
/// intuitif comme « créneau chargé »). Renvoie null si tout est à zéro.
(int, int)? busiestWindow(List<int> counts, int width) {
  if (width <= 0 || counts.length < width) return null;
  var bestSum = 0;
  int? bestStart;
  for (var s = 0; s + width <= counts.length; s++) {
    var sum = 0;
    for (var k = 0; k < width; k++) {
      sum += counts[s + k];
    }
    if (sum > 0 && sum >= bestSum) {
      bestSum = sum;
      bestStart = s; // >= → la dernière fenêtre à égalité l'emporte
    }
  }
  return bestStart == null ? null : (bestStart, bestStart + width);
}

/// **Jours-propres cumulés** : nombre de jours logiques *terminés* (avant
/// aujourd'hui) sans aucune cigarette, depuis le tout premier tap.
///
/// **Ne décroît jamais avec le temps** — c'est le compteur qui empêche
/// l'effondrement « tout est foutu » après une rechute (le cairn ne perd pas ses
/// pierres). Il peut en revanche baisser sur une **correction explicite de
/// l'utilisateur** — déclarer un jour non tapé, ou recommencer l'observation :
/// on retire alors une victoire qui n'avait jamais eu lieu. C'est l'inverse
/// d'une érosion, et ça reste à son initiative.
///
/// [notLogged] = jours logiques que l'utilisateur a déclarés « pas tapés ». Ils
/// sont **neutres** : ni propres, ni fumés. Sans eux, une journée oubliée serait
/// comptée comme une victoire — et comme ce compteur ne redescend jamais, le
/// mensonge serait définitif.
int cumulativeCleanDays(
  Iterable<Cigarette> cigs,
  DateTime now, {
  Set<DateTime> notLogged = const {},
}) {
  final list = cigs.toList();
  if (list.isEmpty) return 0;

  final smoky = <DateTime>{};
  DateTime? firstDay;
  for (final c in list) {
    final d = LogicalDay.dayOf(wallTimeOf(c));
    smoky.add(d);
    if (firstDay == null || d.isBefore(firstDay)) firstDay = d;
  }

  final today = LogicalDay.dayOf(now);
  var clean = 0;
  for (var d = firstDay!;
      d.isBefore(today);
      d = DateTime(d.year, d.month, d.day + 1)) {
    if (!smoky.contains(d) && !notLogged.contains(d)) clean++;
  }
  return clean;
}

/// **Record d'écart max** : le plus long intervalle jamais atteint entre deux
/// cigarettes, en incluant l'abstinence en cours ([now] − dernière).
///
/// Ne décroît jamais **par le temps ni par une rechute** : celle-ci remet le
/// streak à zéro mais laisse ce record intact. Seule une correction explicite
/// de l'utilisateur peut le réduire (un jour déclaré non tapé disqualifie
/// l'écart qui l'enjambe — on ne garde pas un trophée sans preuve).
/// [notLogged] : un écart qui **enjambe** un jour déclaré « pas tapé » ne peut
/// pas devenir un record — on ne sait simplement pas ce qui s'y est passé.
/// C'est la contrepartie du silence : pas de preuve, pas de trophée.
Duration recordGap(
  Iterable<Cigarette> cigs,
  DateTime now, {
  Set<DateTime> notLogged = const {},
}) {
  final list = [...cigs]
    ..sort((a, b) => a.occurredAtUtc.compareTo(b.occurredAtUtc));
  var maxG = Duration.zero;
  for (var i = 1; i < list.length; i++) {
    // Les heures murales servent à savoir QUELS jours l'écart traverse ; sa
    // durée, elle, se mesure en absolu (un changement de fuseau ne doit pas
    // rallonger un record).
    if (_spansNotLogged(
        wallTimeOf(list[i - 1]), wallTimeOf(list[i]), notLogged)) {
      continue;
    }
    final g = list[i].occurredAtUtc.difference(list[i - 1].occurredAtUtc);
    if (g > maxG) maxG = g;
  }
  if (list.isNotEmpty) {
    if (!_spansNotLogged(wallTimeOf(list.last), now, notLogged)) {
      final current = now.difference(list.last.occurredAtUtc.toLocal());
      if (current > maxG) maxG = current;
    }
  }
  return maxG;
}

/// Vrai si l'intervalle [from]..[to] (heures murales) touche un jour déclaré.
bool _spansNotLogged(DateTime from, DateTime to, Set<DateTime> notLogged) {
  if (notLogged.isEmpty) return false;
  for (var d = LogicalDay.dayOf(from);
      !d.isAfter(LogicalDay.dayOf(to));
      d = DateTime(d.year, d.month, d.day + 1)) {
    if (notLogged.contains(d)) return true;
  }
  return false;
}

/// Calcule le portrait chiffré. [windowWidth] = largeur du créneau chargé (h).
MetricsSummary computeMetrics(Iterable<Cigarette> input, {int windowWidth = 2}) {
  final cigs = [...input]
    ..sort((a, b) => a.occurredAtUtc.compareTo(b.occurredAtUtc));
  final total = cigs.length;
  if (total == 0) return MetricsSummary.empty;

  final days = distinctLogicalDays(cigs);
  final counts = hourlyCounts(cigs);
  final gaps = gapsOf(cigs);

  return MetricsSummary(
    total: total,
    days: days,
    perDay: days == 0 ? total.toDouble() : total / days,
    medianGap: medianDuration(gaps),
    meanGap: meanDuration(gaps),
    busiestHour: busiestHour(counts),
    busiestWindow: busiestWindow(counts, windowWidth),
  );
}
