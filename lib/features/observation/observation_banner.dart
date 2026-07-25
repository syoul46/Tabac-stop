import 'package:flutter/material.dart';

/// Bandeau de la phase d'observation. Ton calme (vert de nature, pas le lagon
/// réservé aux succès). Donne la permission de fumer normalement.
class ObservationBanner extends StatelessWidget {
  const ObservationBanner({super.key, required this.dayIndex});

  final int dayIndex;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: c.tertiary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.tertiary.withValues(alpha: 0.30)),
      ),
      child: Text(
        'Jour $dayIndex sur 3 — on observe',
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: c.tertiary,
        ),
      ),
    );
  }
}
