import 'package:flutter/material.dart';

/// Petite courbe qui se remplit au fil de la journée : un bâtonnet par heure
/// locale (0–23), hauteur = nombre de cigarettes. Repères horaires sous les
/// barres (0 h, 4 h, …, 20 h) pour situer les pics. Sobre, informatif.
class HourlyCurve extends StatelessWidget {
  const HourlyCurve({super.key, required this.counts});

  /// Liste de 24 entiers (index = heure locale).
  final List<int> counts;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final color = c.tertiary;
    final labelColor = c.onSurface.withValues(alpha: 0.4);
    final maxV = counts.fold<int>(0, (m, v) => v > m ? v : m);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 46,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final v in counts)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: FractionallySizedBox(
                        heightFactor: maxV == 0 ? 0.05 : (0.10 + 0.90 * v / maxV),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: v == 0 ? 0.14 : 0.72),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(2)),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          // Repères horaires alignés sous les barres correspondantes. Hauteur
          // bornée + largeur débordante (OverflowBox) pour centrer sous la barre
          // sans être coupé par la largeur d'une colonne (les voisines sont vides).
          SizedBox(
            height: 13,
            child: Row(
              children: [
                for (var h = 0; h < 24; h++)
                  Expanded(
                    child: h % 4 == 0
                        ? OverflowBox(
                            minWidth: 0,
                            maxWidth: 40,
                            maxHeight: 13,
                            child: Text(
                              '${h}h',
                              style:
                                  TextStyle(fontSize: 9.5, color: labelColor),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
