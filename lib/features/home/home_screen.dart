import 'package:flutter/material.dart';

import '../../core/theme/cairn_theme.dart';

/// Placeholder du Jalon 0 : un cairn statique + le mot-marque, pour valider le
/// thème minéral. Le vrai écran (le bouton = poser une pierre) arrive au Jalon 1.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _CairnPlaceholder(),
              const SizedBox(height: 32),
              Text(
                'Cairn',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Jalon 0 — squelette prêt',
                style: TextStyle(color: onSurface.withValues(alpha: 0.55)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Petit cairn statique : des pierres empilées, largeur décroissante.
class _CairnPlaceholder extends StatelessWidget {
  const _CairnPlaceholder();

  @override
  Widget build(BuildContext context) {
    const stones = <(double, Color)>[
      (56, CairnColors.basaltLight),
      (74, CairnColors.ocre),
      (92, CairnColors.basalt),
      (110, CairnColors.basaltLight),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (width, color) in stones)
          Container(
            width: width,
            height: 22,
            margin: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
      ],
    );
  }
}
