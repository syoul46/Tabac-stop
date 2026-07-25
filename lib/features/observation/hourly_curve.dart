import 'package:flutter/material.dart';

/// Petite courbe qui se remplit au fil de la journée : un bâtonnet par heure
/// locale (0–23), hauteur = nombre de cigarettes. Sobre, informatif.
class HourlyCurve extends StatelessWidget {
  const HourlyCurve({super.key, required this.counts});

  /// Liste de 24 entiers (index = heure locale).
  final List<int> counts;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.tertiary;
    final maxV = counts.fold<int>(0, (m, v) => v > m ? v : m);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: SizedBox(
        height: 46,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final v in counts)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: FractionallySizedBox(
                    heightFactor:
                        maxV == 0 ? 0.05 : (0.10 + 0.90 * v / maxV),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: v == 0 ? 0.14 : 0.72),
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(2)),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
