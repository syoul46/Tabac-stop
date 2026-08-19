import '../../core/time/logical_day.dart';
import '../../data/database.dart';
import 'hourly.dart';

/// Consommation d'un jour logique, pour la courbe d'évolution.
class DailyCount {
  const DailyCount(this.day, this.count, {this.notLogged = false});

  /// Jour logique (à minuit, bascule 04:00 — cf. [LogicalDay]).
  final DateTime day;

  /// Nombre de cigarettes tapées ce jour-là.
  final int count;

  /// Jour déclaré « pas tapé » par l'utilisateur : **neutre** (ni un vrai 0, ni
  /// fumé). À afficher différemment d'un jour propre pour ne pas mentir.
  final bool notLogged;
}

/// Consommation **jour par jour**, du premier jour tapé à aujourd'hui inclus,
/// les trous comblés à 0. Purement dérivé du journal — jamais stocké.
///
/// Aujourd'hui est **partiel** (il grandit au fil de la journée) : c'est voulu,
/// la dernière barre reflète l'instant présent. [notLogged] = jours neutres.
List<DailyCount> dailyCounts(
  Iterable<Cigarette> cigs,
  DateTime now, {
  Set<DateTime> notLogged = const {},
}) {
  final counts = <DateTime, int>{};
  DateTime? firstDay;
  for (final cig in cigs) {
    final d = LogicalDay.dayOf(wallTimeOf(cig));
    counts.update(d, (v) => v + 1, ifAbsent: () => 1);
    if (firstDay == null || d.isBefore(firstDay)) firstDay = d;
  }
  if (firstDay == null) return const [];

  final today = LogicalDay.dayOf(now);
  final out = <DailyCount>[];
  for (var d = firstDay; !d.isAfter(today); d = DateTime(d.year, d.month, d.day + 1)) {
    out.add(DailyCount(d, counts[d] ?? 0, notLogged: notLogged.contains(d)));
  }
  return out;
}

/// Moyenne mobile (fenêtre glissante **arrière**) des comptes journaliers, pour
/// lisser le bruit jour-à-jour et lire la tendance. Chaque point = moyenne des
/// [window] derniers jours (ou moins au début). Même longueur que [days].
///
/// Les jours **non tapés** sont neutres (inconnus) : on les exclut de la moyenne
/// (ni au numérateur ni au dénominateur) pour ne pas fabriquer une fausse baisse.
/// Si toute la fenêtre est neutre, on reporte le dernier point connu (0 au tout
/// début).
List<double> rollingDailyAverage(List<DailyCount> days, {int window = 7}) {
  final out = <double>[];
  for (var i = 0; i < days.length; i++) {
    final start = (i - window + 1) < 0 ? 0 : i - window + 1;
    var sum = 0;
    var n = 0;
    for (var k = start; k <= i; k++) {
      if (days[k].notLogged) continue;
      sum += days[k].count;
      n++;
    }
    out.add(n == 0 ? (out.isEmpty ? 0 : out.last) : sum / n);
  }
  return out;
}
