import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/time/format.dart';
import '../../data/cigarette_repository.dart';
import 'tap_stone.dart';

/// Écran 1 / phase d'observation. Au premier lancement : juste le bouton + une
/// phrase. Dès qu'il y a un historique : chrono « depuis la dernière » + compte
/// du jour. Le tap enregistre en silence (validation silencieuse).
class TapScreen extends ConsumerStatefulWidget {
  const TapScreen({super.key});

  @override
  ConsumerState<TapScreen> createState() => _TapScreenState();
}

class _TapScreenState extends ConsumerState<TapScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Rafraîchit le chrono chaque seconde.
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
    // Retour franc, puis on enregistre. Rien d'autre — aucune consolation.
    unawaited(HapticFeedback.mediumImpact());
    await ref.read(cigaretteRepositoryProvider).logSmoke();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final last = ref.watch(lastCigaretteProvider).asData?.value;
    final count = ref.watch(todayCountProvider).asData?.value ?? 0;
    final hasHistory = last != null;

    final since = hasHistory
        ? DateTime.now().difference(last.occurredAtUtc.toLocal())
        : Duration.zero;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasHistory) ...[
                _ChronoLabel(since: since),
                const SizedBox(height: 26),
              ],
              TapStone(
                onTap: _onTap,
                child: Text(
                  '✦',
                  style: TextStyle(
                    fontSize: 40,
                    color: onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              if (hasHistory)
                Text(
                  '$count aujourd’hui',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: onSurface.withValues(alpha: 0.6)),
                )
              else
                _InvitePhrase(color: onSurface),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChronoLabel extends StatelessWidget {
  const _ChronoLabel({required this.since});
  final Duration since;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formatSinceLast(since),
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w300,
            color: onSurface,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'depuis la dernière',
          style: TextStyle(
            fontSize: 12,
            color: onSurface.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

class _InvitePhrase extends StatelessWidget {
  const _InvitePhrase({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Tape quand tu fumes.',
          style: TextStyle(
              fontSize: 18, color: color, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          "C'est tout, pour l'instant.",
          style: TextStyle(fontSize: 14, color: color.withValues(alpha: 0.6)),
        ),
      ],
    );
  }
}
