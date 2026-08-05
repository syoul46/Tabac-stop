import '../../data/database.dart';

/// Seuils de déclenchement de la révélation.
const int kRevealMinTaps = 30;

/// Fenêtre d'observation : **une semaine**, pour capter le rythme de la semaine
/// ET du week-end (habitudes souvent différentes) et fiabiliser les métriques.
const int kObservationDays = 7;

/// Durée d'observation **réelle** requise (mesurée en temps écoulé, pas en jours
/// de calendrier — commencer à 23 h ne doit pas « tricher » de deux bascules).
const Duration kRevealMinObservation = Duration(days: kObservationDays);

/// La révélation ne se déclenche que quand l'app a de quoi parler juste :
/// **≥ 30 taps ET ≥ 7 jours d'observation réelle** (`now − 1ʳᵉ cigarette`).
/// En dessous, on prolonge l'observation en silence — jamais de portrait maigre.
bool shouldReveal(Iterable<Cigarette> cigs, DateTime now) {
  final list = cigs is List<Cigarette> ? cigs : cigs.toList();
  if (list.length < kRevealMinTaps) return false;
  DateTime? first;
  for (final c in list) {
    if (first == null || c.occurredAtUtc.isBefore(first)) {
      first = c.occurredAtUtc;
    }
  }
  if (first == null) return false;
  return now.difference(first.toLocal()) >= kRevealMinObservation;
}
