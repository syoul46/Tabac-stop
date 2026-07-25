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
(int, int)? busiestWindow(List<int> counts, int width) {
  if (width <= 0 || counts.length < width) return null;
  var bestSum = 0;
  int? bestStart;
  for (var s = 0; s + width <= counts.length; s++) {
    var sum = 0;
    for (var k = 0; k < width; k++) {
      sum += counts[s + k];
    }
    if (sum > bestSum) {
      bestSum = sum;
      bestStart = s;
    }
  }
  return bestStart == null ? null : (bestStart, bestStart + width);
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
