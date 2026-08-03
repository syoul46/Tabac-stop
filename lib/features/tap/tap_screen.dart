import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/time/format.dart';
import '../../core/time/logical_day.dart';
import '../../data/cigarette_repository.dart';
import '../../data/database.dart';
import '../../domain/metrics/hourly.dart';
import '../cairn/cairn_view.dart';
import '../observation/hourly_curve.dart';
import '../observation/observation_banner.dart';
import 'context_picker.dart';
import 'tap_stone.dart';

/// Fenêtre pendant laquelle les icônes de contexte restent proposées après un tap.
const _contextWindow = Duration(seconds: 6);

/// Écran 1 / phase d'observation. Au premier lancement : le bouton + une phrase.
/// Ensuite : bandeau « Jour X sur 3 », chrono, compte du jour, courbe horaire,
/// et — brièvement après chaque tap — les 3 icônes de contexte.
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
    final todays = ref.watch(todaysCigarettesProvider).asData?.value ??
        const <Cigarette>[];
    final first = ref.watch(firstCigaretteProvider).asData?.value;

    if (last == null) return _firstLaunch(onSurface);

    final now = DateTime.now();
    final since = now.difference(last.occurredAtUtc.toLocal());
    final dayIndex = first == null
        ? 1
        : LogicalDay.indexSince(wallTimeOf(first), now).clamp(1, 3);
    final showContext = last.contextA == null && since < _contextWindow;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 14),
            ObservationBanner(dayIndex: dayIndex),
            const SizedBox(height: 4),
            // Mini-cairn silencieux : il se forme au fil des jours d'observation
            // (une pierre par jour), sans un mot — l'app ne parle pas en J1-3.
            CairnView(
              stones: dayIndex,
              haptics: false,
              width: 132,
              height: 96,
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ChronoLabel(since: since),
                    const SizedBox(height: 24),
                    TapStone(onTap: _onTap, child: _glyph(onSurface)),
                    const SizedBox(height: 18),
                    Text(
                      '${todays.length} aujourd’hui',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ContextPicker(
                      visible: showContext,
                      onSelect: (ctx) => ref
                          .read(cigaretteRepositoryProvider)
                          .setContext(last.id, ctx),
                    ),
                  ],
                ),
              ),
            ),
            HourlyCurve(counts: hourlyCounts(todays)),
            const SizedBox(height: 26),
          ],
        ),
      ),
    );
  }

  Widget _firstLaunch(Color onSurface) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TapStone(onTap: _onTap, child: _glyph(onSurface)),
              const SizedBox(height: 28),
              _InvitePhrase(color: onSurface),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glyph(Color onSurface) => Text(
        '✦',
        style: TextStyle(fontSize: 40, color: onSurface.withValues(alpha: 0.5)),
      );
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
