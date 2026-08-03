import '../../data/database.dart';

/// Un palier santé = une altitude du cairn atteinte après une certaine durée
/// d'**abstinence continue**, et le fait physiologique vrai qu'elle révèle.
///
/// Repères classiques de récupération après l'arrêt du tabac (NHS/CDC).
class HealthMilestone {
  const HealthMilestone({
    required this.after,
    required this.altitudeMeters,
    required this.title,
    required this.fact,
  });

  /// Durée d'abstinence continue à partir de laquelle le palier est atteint.
  final Duration after;

  /// Altitude métaphorique du cairn (croît avec les paliers).
  final int altitudeMeters;

  /// Nom court du palier (ex. « 24 heures »).
  final String title;

  /// Le fait révélé — une phrase, un gain, jamais une perte.
  final String fact;
}

/// Table figée v1 (extensible), **triée par durée croissante**.
const List<HealthMilestone> kHealthMilestones = [
  HealthMilestone(
    after: Duration(minutes: 20),
    altitudeMeters: 300,
    title: '20 minutes',
    fact: 'Ton pouls et ta tension redescendent.',
  ),
  HealthMilestone(
    after: Duration(hours: 8),
    altitudeMeters: 800,
    title: '8 heures',
    fact: 'Le monoxyde de carbone reflue, l’oxygène remonte.',
  ),
  HealthMilestone(
    after: Duration(hours: 24),
    altitudeMeters: 1000,
    title: '24 heures',
    fact: 'Ton corps est débarrassé du monoxyde de carbone.',
  ),
  HealthMilestone(
    after: Duration(hours: 48),
    altitudeMeters: 1500,
    title: '48 heures',
    fact: 'Le goût et l’odorat reviennent.',
  ),
  HealthMilestone(
    after: Duration(hours: 72),
    altitudeMeters: 2000,
    title: '72 heures',
    fact: 'Les bronches se détendent, respirer devient plus facile.',
  ),
  HealthMilestone(
    after: Duration(days: 14),
    altitudeMeters: 3000,
    title: '2 semaines',
    fact: 'Ta circulation s’améliore.',
  ),
  HealthMilestone(
    after: Duration(days: 30),
    altitudeMeters: 3500,
    title: '1 mois',
    fact: 'Tes poumons se nettoient, tu t’essouffles moins.',
  ),
  HealthMilestone(
    after: Duration(days: 90),
    altitudeMeters: 4000,
    title: '3 mois',
    fact: 'Ta fonction pulmonaire remonte nettement.',
  ),
  HealthMilestone(
    after: Duration(days: 365),
    altitudeMeters: 5000,
    title: '1 an',
    fact: 'Ton risque de maladie cardiaque est divisé par deux.',
  ),
];

/// Abstinence continue = `now − dernière cigarette`. Zéro si aucun tap (ou si
/// l'horloge est en retard sur la dernière donnée). Ne suppose pas la liste triée.
Duration currentAbstinence(Iterable<Cigarette> cigs, DateTime now) {
  DateTime? last;
  for (final c in cigs) {
    if (last == null || c.occurredAtUtc.isAfter(last)) last = c.occurredAtUtc;
  }
  if (last == null) return Duration.zero;
  final d = now.difference(last.toLocal());
  return d.isNegative ? Duration.zero : d;
}

/// Index du plus haut palier atteint pour cette abstinence ; -1 si aucun.
int reachedIndex(Duration abstinence) {
  var idx = -1;
  for (var i = 0; i < kHealthMilestones.length; i++) {
    if (abstinence >= kHealthMilestones[i].after) {
      idx = i;
    } else {
      break; // table triée → inutile d'aller plus loin
    }
  }
  return idx;
}

/// Le palier courant (le plus haut atteint), ou null si sous le premier.
HealthMilestone? milestoneAt(Duration abstinence) {
  final i = reachedIndex(abstinence);
  return i < 0 ? null : kHealthMilestones[i];
}

/// Le prochain palier à viser, ou null si tous atteints.
HealthMilestone? nextMilestoneAfter(Duration abstinence) {
  for (final m in kHealthMilestones) {
    if (abstinence < m.after) return m;
  }
  return null;
}

/// Index du plus haut palier déjà **révélé**, dérivé des seuils (en minutes)
/// journalisés. -1 si aucun. On ne journalise que le plus haut, mais cette
/// fonction tolère un ensemble quelconque.
int highestRevealedIndex(Set<int> revealedAfterMinutes) {
  var idx = -1;
  for (var i = 0; i < kHealthMilestones.length; i++) {
    if (revealedAfterMinutes.contains(kHealthMilestones[i].after.inMinutes)) {
      idx = i;
    }
  }
  return idx;
}

/// Le palier à révéler maintenant : le plus haut atteint qui n'a pas encore été
/// révélé. null s'il n'y a rien de neuf à annoncer.
///
/// Comme on ne compare qu'au **plus haut** déjà révélé, une rechute puis une
/// re-montée ne re-révèle jamais un palier (l'app reste silencieuse).
HealthMilestone? pendingMilestoneReveal({
  required Duration abstinence,
  required int highestRevealed,
}) {
  final reached = reachedIndex(abstinence);
  return reached > highestRevealed ? kHealthMilestones[reached] : null;
}
