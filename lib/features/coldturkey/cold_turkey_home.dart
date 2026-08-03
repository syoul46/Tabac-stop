import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/time/format.dart';
import '../../data/cigarette_repository.dart';
import '../../data/database.dart';
import '../../data/journey_repository.dart';
import '../../domain/health/milestones.dart';
import '../../domain/metrics/metrics.dart';
import '../../domain/models/enums.dart';
import '../cairn/cairn_view.dart';
import '../health/altitude_view.dart';
import '../tap/tap_stone.dart';

/// Au-delà de ce streak rompu, on propose (sans insister) de souffler en réduction.
const _relapseOfferThreshold = Duration(hours: 1);

/// Mode arrêt net. Le streak repart à zéro à la rechute (honnête), mais les
/// **jours propres cumulés** et le **record d'écart** ne bougent jamais — le
/// cairn ne perd pas ses pierres. Après une vraie rechute, une porte discrète
/// vers la réduction s'ouvre, sans insistance.
class ColdTurkeyHome extends ConsumerStatefulWidget {
  const ColdTurkeyHome({super.key});

  @override
  ConsumerState<ColdTurkeyHome> createState() => _ColdTurkeyHomeState();
}

class _ColdTurkeyHomeState extends ConsumerState<ColdTurkeyHome> {
  Timer? _ticker;
  bool _showOffer = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _onTap() async {
    final now = DateTime.now();
    final last = ref.read(lastCigaretteProvider).asData?.value;
    final before = last == null
        ? Duration.zero
        : now.difference(last.occurredAtUtc.toLocal());

    // Silencieux : le streak repart de zéro, sans commentaire.
    unawaited(HapticFeedback.mediumImpact());
    await ref.read(cigaretteRepositoryProvider).logSmoke();

    if (before >= _relapseOfferThreshold) {
      await ref.read(journeyRepositoryProvider).markRelapse();
      if (mounted) setState(() => _showOffer = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final now = DateTime.now();

    final last = ref.watch(lastCigaretteProvider).asData?.value;
    final cigs =
        ref.watch(allCigarettesProvider).asData?.value ?? const <Cigarette>[];

    final streak = last == null
        ? Duration.zero
        : now.difference(last.occurredAtUtc.toLocal());
    final cleanDays = cumulativeCleanDays(cigs, now);
    final record = recordGap(cigs, now);

    // Le cairn monte avec l'altitude : une pierre de fondation + une par palier
    // santé atteint ; la pierre en formation progresse vers le prochain palier.
    final stones = reachedIndex(streak) + 2;
    final current = milestoneAt(streak);
    final next = nextMilestoneAfter(streak);
    final lower = current?.after ?? Duration.zero;
    final progress = next == null
        ? 1.0
        : ((streak - lower).inSeconds / (next.after - lower).inSeconds)
            .clamp(0.0, 1.0);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),
                  // Le cairn : l'écran principal, c'est lui qui grandit.
                  CairnView(stones: stones, progress: progress),
                  const SizedBox(height: 14),
                  Text(
                    formatStreak(streak),
                    style: theme.textTheme.displaySmall?.copyWith(
                        color: c.primary, fontWeight: FontWeight.w600),
                  ),
                  Text('sans fumer',
                      style:
                          TextStyle(color: c.onSurface.withValues(alpha: 0.6))),
                  const SizedBox(height: 16),
                  AltitudeView(abstinence: streak),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _MiniStat(
                        value: '$cleanDays',
                        label: cleanDays <= 1 ? 'jour propre' : 'jours propres',
                      ),
                      const SizedBox(width: 40),
                      _MiniStat(
                          value: formatStreak(record), label: 'plus haut cairn'),
                    ],
                  ),
                  const SizedBox(height: 22),
                  TapStone(
                    onTap: _onTap,
                    diameter: 104,
                    child: Text('✦',
                        style: TextStyle(
                            fontSize: 26,
                            color: c.onSurface.withValues(alpha: 0.5))),
                  ),
                  const SizedBox(height: 10),
                  Text('tape si tu as fumé',
                      style: TextStyle(
                          fontSize: 12.5,
                          color: c.onSurface.withValues(alpha: 0.5))),
                  if (_showOffer) ...[
                    const SizedBox(height: 24),
                    _ReductionOffer(
                      onAccept: () => ref
                          .read(journeyRepositoryProvider)
                          .setMode(JourneyMode.reduction),
                      onDismiss: () => setState(() => _showOffer = false),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: c.onSurface.withValues(alpha: 0.85),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                fontSize: 11.5, color: c.onSurface.withValues(alpha: 0.55))),
      ],
    );
  }
}

/// Porte discrète vers la réduction, proposée après une rechute — jamais une
/// leçon ni une consolation, juste une option pratique qu'on peut ignorer.
class _ReductionOffer extends StatelessWidget {
  const _ReductionOffer({required this.onAccept, required this.onDismiss});
  final VoidCallback onAccept;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 28),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      decoration: BoxDecoration(
        color: c.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.onSurface.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Text(
            'Repasser en réduction quelques jours ?',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14, color: c.onSurface.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: onDismiss,
                style: TextButton.styleFrom(
                    foregroundColor: c.onSurface.withValues(alpha: 0.6)),
                child: const Text('Non, je continue'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onAccept,
                style: FilledButton.styleFrom(
                    backgroundColor: c.primary, foregroundColor: c.onPrimary),
                child: const Text('Réduction'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
