import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/time/format.dart';
import '../../data/cigarette_repository.dart';
import '../../data/database.dart';
import '../../domain/metrics/hourly.dart';
import '../cairn/cairn_view.dart';
import '../help/how_it_works_screen.dart';
import '../observation/hourly_curve.dart';
import '../observation/observation_banner.dart';
import 'context_picker.dart';
import 'tap_stone.dart';

/// Fenêtre pendant laquelle les icônes de contexte restent proposées après un tap.
const _contextWindow = Duration(seconds: 6);

/// Écran 1 / phase d'observation. Au premier lancement : le bouton + une phrase.
/// Ensuite : bandeau « Jour X sur 7 », chrono, compte du jour, courbe horaire,
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

  /// Annule le dernier tap (mis-tap) — persistant (un tap par erreur peut se
  /// remarquer bien plus tard), avec une confirmation pour éviter une
  /// suppression accidentelle.
  Future<void> _undo() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: const Text('Veux-tu supprimer cette cigarette ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    unawaited(HapticFeedback.selectionClick());
    await ref.read(cigaretteRepositoryProvider).undoLastCigarette();
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
    // Jour d'observation basé sur la **durée réelle** depuis le 1ᵉʳ tap (bloc de
    // 24 h). Pas de plafond : au-delà de la fenêtre (petit fumeur, <30 taps), on
    // continue « Jour 8 », « Jour 9 »… (le bandeau lâche le « sur 7 »).
    final elapsedDays = first == null
        ? 1
        : now.difference(first.occurredAtUtc.toLocal()).inHours ~/ 24 + 1;
    final dayIndex = elapsedDays < 1 ? 1 : elapsedDays;
    final showContext = last.contextA == null && since < _contextWindow;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Laisse passer la rangée d'icônes flottantes (stats / aide) en
            // haut à gauche, pour que le bandeau ne soit jamais recouvert.
            const SizedBox(height: 52),
            ObservationBanner(dayIndex: dayIndex),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pierre-graine : une seule pierre fixe pendant l'observation.
                    // Elle ne grandit PAS avec les jours (ce serait trompeur — en
                    // J1-3 on ne résiste à rien). Groupée avec le chrono, centrée.
                    const CairnView(
                      stones: 1,
                      haptics: false,
                      width: 132,
                      height: 96,
                    ),
                    const SizedBox(height: 6),
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
                    // « Annuler » discret, toujours disponible (un mis-tap peut
                    // se remarquer tard) — avec confirmation avant suppression.
                    const SizedBox(height: 6),
                    TextButton.icon(
                      onPressed: _undo,
                      icon: const Icon(Icons.undo, size: 16),
                      label: const Text('Annuler'),
                      style: TextButton.styleFrom(
                        foregroundColor: onSurface.withValues(alpha: 0.5),
                      ),
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
              const SizedBox(height: 18),
              TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const HowItWorksScreen())),
                style: TextButton.styleFrom(
                    foregroundColor: onSurface.withValues(alpha: 0.5)),
                child: const Text('Comment ça marche ?'),
              ),
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
