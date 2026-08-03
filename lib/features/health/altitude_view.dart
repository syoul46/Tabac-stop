import 'package:flutter/material.dart';

import '../../core/time/format.dart';
import '../../domain/health/milestones.dart';

/// Ligne d'altitude sous le streak : le palier courant (fait déjà acquis) et le
/// prochain à viser. Voix **lagon** (l'app ne parle que sur un fait). Sobre.
class AltitudeView extends StatelessWidget {
  const AltitudeView({super.key, required this.abstinence});

  final Duration abstinence;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final current = milestoneAt(abstinence);
    final next = nextMilestoneAfter(abstinence);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (current != null) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('▲ ', style: TextStyle(fontSize: 13, color: c.primary)),
              Text(
                '${current.altitudeMeters} m',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: c.primary, // lagon
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            current.fact,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12.5, color: c.onSurface.withValues(alpha: 0.7)),
          ),
        ],
        if (next != null) ...[
          const SizedBox(height: 8),
          Text(
            current == null
                ? 'prochain palier : ${next.altitudeMeters} m dans ${_remaining(next)}'
                : 'prochain : ${next.altitudeMeters} m dans ${_remaining(next)}',
            style: TextStyle(
                fontSize: 11.5, color: c.onSurface.withValues(alpha: 0.45)),
          ),
        ],
      ],
    );
  }

  String _remaining(HealthMilestone m) => formatStreak(m.after - abstinence);
}
