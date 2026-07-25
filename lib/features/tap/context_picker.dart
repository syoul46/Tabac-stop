import 'package:flutter/material.dart';

import '../../domain/models/enums.dart';

/// Les 3 icônes de contexte, montrées brièvement après un tap. Facultatives,
/// tapables en une seconde, jamais obligatoires. Occupe toujours sa place pour
/// éviter tout saut de mise en page ; seule l'opacité change.
class ContextPicker extends StatelessWidget {
  const ContextPicker({
    super.key,
    required this.visible,
    required this.onSelect,
  });

  final bool visible;
  final ValueChanged<CigContext> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 220),
        child: IgnorePointer(
          ignoring: !visible,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _chip(context, CigContext.cafe, Icons.local_cafe_outlined, 'café'),
              const SizedBox(width: 12),
              _chip(context, CigContext.repas, Icons.restaurant_outlined, 'repas'),
              const SizedBox(width: 12),
              _chip(context, CigContext.alcool, Icons.wine_bar_outlined, 'alcool'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    CigContext ctx,
    IconData icon,
    String label,
  ) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Semantics(
      button: true,
      label: label,
      child: InkResponse(
        onTap: () => onSelect(ctx),
        radius: 28,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: onSurface.withValues(alpha: 0.20)),
          ),
          child: Icon(icon, size: 20, color: onSurface.withValues(alpha: 0.70)),
        ),
      ),
    );
  }
}
