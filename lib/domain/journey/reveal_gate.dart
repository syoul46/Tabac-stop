import '../../data/database.dart';
import '../metrics/metrics.dart';

/// Seuils de déclenchement de la révélation.
const int kRevealMinTaps = 30;
const int kRevealMinDays = 3;

/// La révélation ne se déclenche que quand l'app a de quoi parler juste :
/// **≥ 30 taps ET ≥ 3 jours logiques**. En dessous (même à 72 h), on prolonge
/// l'observation en silence — jamais de portrait maigre.
bool shouldReveal(Iterable<Cigarette> cigs) {
  final list = cigs is List<Cigarette> ? cigs : cigs.toList();
  return list.length >= kRevealMinTaps &&
      distinctLogicalDays(list) >= kRevealMinDays;
}
