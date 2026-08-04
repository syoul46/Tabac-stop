import 'dart:convert';

import '../../data/database.dart';
import '../models/enums.dart';

/// Un palier santé = une altitude du cairn atteinte après une certaine durée
/// d'**abstinence continue**, et le fait physiologique vrai qu'elle révèle.
///
/// Repères classiques de récupération après l'arrêt du tabac (NHS / CDC / AHA).
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
    altitudeMeters: 200,
    title: '20 minutes',
    fact: 'Ton pouls et ta tension redescendent.',
  ),
  HealthMilestone(
    after: Duration(hours: 2),
    altitudeMeters: 400,
    title: '2 heures',
    fact: 'Ta circulation repart : tes mains et tes pieds se réchauffent.',
  ),
  HealthMilestone(
    after: Duration(hours: 8),
    altitudeMeters: 600,
    title: '8 heures',
    fact: 'Le monoxyde de carbone dans ton sang a déjà diminué de moitié.',
  ),
  HealthMilestone(
    after: Duration(hours: 12),
    altitudeMeters: 800,
    title: '12 heures',
    fact: 'Le monoxyde de carbone est revenu à la normale — plus d’oxygène '
        'pour tes organes.',
  ),
  HealthMilestone(
    after: Duration(hours: 24),
    altitudeMeters: 1000,
    title: '24 heures',
    fact: 'Ton risque de crise cardiaque commence déjà à baisser.',
  ),
  HealthMilestone(
    after: Duration(hours: 48),
    altitudeMeters: 1500,
    title: '48 heures',
    fact: 'Le goût et l’odorat reviennent : tes terminaisons nerveuses '
        'repoussent.',
  ),
  HealthMilestone(
    after: Duration(hours: 72),
    altitudeMeters: 2000,
    title: '72 heures',
    fact: 'Tes bronches se détendent, respirer devient plus facile, '
        'l’énergie remonte.',
  ),
  HealthMilestone(
    after: Duration(days: 14),
    altitudeMeters: 3000,
    title: '2 semaines',
    fact: 'Ta circulation s’améliore, marcher devient plus facile.',
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
  final last = lastCigaretteAt(cigs);
  if (last == null) return Duration.zero;
  final d = now.difference(last.toLocal());
  return d.isNegative ? Duration.zero : d;
}

/// Instant (UTC) de la dernière cigarette, ou null si aucune.
DateTime? lastCigaretteAt(Iterable<Cigarette> cigs) {
  DateTime? last;
  for (final c in cigs) {
    if (last == null || c.occurredAtUtc.isAfter(last)) last = c.occurredAtUtc;
  }
  return last;
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
/// journalisés. -1 si aucun.
int highestRevealedIndex(Set<int> revealedAfterMinutes) {
  var idx = -1;
  for (var i = 0; i < kHealthMilestones.length; i++) {
    if (revealedAfterMinutes.contains(kHealthMilestones[i].after.inMinutes)) {
      idx = i;
    }
  }
  return idx;
}

/// Seuils (en minutes) des paliers révélés **depuis [since]** (les révélations
/// antérieures sont ignorées). En passant l'instant de la dernière cigarette,
/// une **nouvelle montée rejoue** les paliers déjà vus lors des montées passées.
Set<int> revealedMinutesSince(List<JourneyEvent> events, DateTime? since) {
  final out = <int>{};
  for (final e in events) {
    if (e.kind != JourneyEventKind.milestoneRevealed.name) continue;
    if (since != null && e.occurredAtUtc.isBefore(since)) continue;
    final p = e.payload;
    if (p == null) continue;
    final m = (jsonDecode(p) as Map)['afterMinutes'];
    if (m is int) out.add(m);
  }
  return out;
}

/// Le palier à révéler maintenant : le plus haut atteint qui n'a pas encore été
/// révélé (sur la montée en cours). null s'il n'y a rien de neuf à annoncer.
HealthMilestone? pendingMilestoneReveal({
  required Duration abstinence,
  required int highestRevealed,
}) {
  final reached = reachedIndex(abstinence);
  return reached > highestRevealed ? kHealthMilestones[reached] : null;
}
