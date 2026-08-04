import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cigarette_repository.dart';
import '../../data/database.dart';
import '../../data/journey_repository.dart';
import '../../domain/health/milestones.dart';

/// Overlay qui, au franchissement d'un palier santé, révèle le fait — **une fois
/// par montée** : après une rechute, remonter les rejoue (la récupération repart
/// vraiment de zéro). Monté uniquement dans un mode (arrêt net / réduction),
/// jamais pendant l'observation ni sur l'Écran 1. Un léger ticker rattrape les
/// franchissements « par le temps qui passe » (sans service en arrière-plan).
class MilestoneReveal extends ConsumerStatefulWidget {
  const MilestoneReveal({super.key});

  @override
  ConsumerState<MilestoneReveal> createState() => _MilestoneRevealState();
}

class _MilestoneRevealState extends ConsumerState<MilestoneReveal> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Les seuils (20 min, 8 h…) ne demandent pas la seconde près.
    _ticker = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cigs =
        ref.watch(allCigarettesProvider).asData?.value ?? const <Cigarette>[];
    final events =
        ref.watch(journeyEventsProvider).asData?.value ?? const <JourneyEvent>[];

    final now = DateTime.now();
    final lastCig = lastCigaretteAt(cigs);
    final abstinence = currentAbstinence(cigs, now);
    // On ne regarde que les paliers révélés DEPUIS la dernière cigarette : une
    // nouvelle montée rejoue donc les paliers.
    final revealed =
        highestRevealedIndex(revealedMinutesSince(events, lastCig));
    final pending = pendingMilestoneReveal(
      abstinence: abstinence,
      highestRevealed: revealed,
    );
    if (pending == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final c = theme.colorScheme;

    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.55),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.primary.withValues(alpha: 0.45)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'NOUVEAU PALIER',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                    color: c.primary, // lagon
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '${pending.altitudeMeters} m',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: c.primary,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  pending.title,
                  style: TextStyle(
                      fontSize: 13, color: c.onSurface.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 16),
                Text(
                  pending.fact,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(height: 1.3),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => ref
                      .read(journeyRepositoryProvider)
                      .markMilestoneRevealed(pending.after.inMinutes),
                  style: FilledButton.styleFrom(
                      backgroundColor: c.primary, foregroundColor: c.onPrimary),
                  child: const Text('Continuer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
