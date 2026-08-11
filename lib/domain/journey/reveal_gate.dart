import '../../data/database.dart';

/// Seuils de déclenchement de la révélation.
const int kRevealMinTaps = 30;

/// Fenêtre d'observation : **une semaine**, pour capter le rythme de la semaine
/// ET du week-end (habitudes souvent différentes) et fiabiliser les métriques.
const int kObservationDays = 7;

/// Durée d'observation **réelle** requise (mesurée en temps écoulé, pas en jours
/// de calendrier — commencer à 23 h ne doit pas « tricher » de deux bascules).
const Duration kRevealMinObservation = Duration(days: kObservationDays);

/// Délai avant de **reproposer** la révélation à qui a répondu « je ne sais pas
/// encore ». La 3ᵉ porte reste ouverte, mais elle ne doit pas être un cul-de-sac :
/// au bout de quelques jours de plus, les données se sont étoffées et la question
/// mérite d'être reposée — une fois, calmement, jamais en boucle.
const Duration kUndecidedRevealAgain = Duration(days: 5);

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
