import '../../data/database.dart';
import '../models/enums.dart';

/// Répartition des **contextes** notés au moment du tap (☕ café · 🍽️ repas ·
/// 🍷 alcool). C'est une donnée déjà captée mais jamais exploitée : la révéler
/// donne un angle d'attaque en plus des Boss horaires — factuel, sans jugement.
class TriggerBreakdown {
  const TriggerBreakdown({
    required this.counts,
    required this.tagged,
    required this.total,
  });

  /// Nombre de cigarettes pour chaque contexte.
  final Map<CigContext, int> counts;

  /// Cigarettes portant un contexte (celles sur lesquelles porte l'analyse).
  final int tagged;

  /// Total de cigarettes considérées (taguées ou non).
  final int total;

  /// Contexte le plus fréquent, ou null si rien n'est tagué.
  CigContext? get dominant {
    CigContext? best;
    var bestN = 0;
    for (final c in CigContext.values) {
      final n = counts[c] ?? 0;
      if (n > bestN) {
        bestN = n;
        best = c;
      }
    }
    return best;
  }

  /// Part d'un contexte **parmi les cigarettes taguées** (0 si aucune).
  double share(CigContext c) => tagged == 0 ? 0 : (counts[c] ?? 0) / tagged;
}

/// Seuil minimal de cigarettes taguées avant d'oser une révélation : en dessous,
/// la répartition est trop fragile pour être honnête — on se tait.
const int kTriggersMinTagged = 8;

/// Compte les contextes sur [cigs]. Robuste à un index hors bornes (enum figée
/// v1 mais extensible — un ancien index inconnu est simplement ignoré).
TriggerBreakdown triggerBreakdown(Iterable<Cigarette> cigs) {
  final counts = {for (final c in CigContext.values) c: 0};
  var tagged = 0;
  var total = 0;
  for (final cig in cigs) {
    total++;
    final idx = cig.contextA;
    if (idx == null || idx < 0 || idx >= CigContext.values.length) continue;
    final ctx = CigContext.values[idx];
    counts[ctx] = counts[ctx]! + 1;
    tagged++;
  }
  return TriggerBreakdown(counts: counts, tagged: tagged, total: total);
}
