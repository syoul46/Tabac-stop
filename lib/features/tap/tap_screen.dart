import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/time/format.dart';
import '../../data/cigarette_repository.dart';
import '../../data/database.dart';
import '../../data/journey_repository.dart';
import '../../domain/metrics/hourly.dart';
import '../cairn/cairn_view.dart';
import '../help/how_it_works_screen.dart';
import '../observation/hourly_curve.dart';
import '../observation/observation_banner.dart';
import 'context_picker.dart';
import 'tap_stone.dart';
import 'undo_last_button.dart';

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

  /// Remet la fenêtre d'observation à zéro (premiers jours mal tapés → portrait
  /// faux → Boss faux). Destructif et irréversible : confirmation explicite,
  /// avec le nombre en clair.
  ///
  /// Copie strictement **factuelle** : on ne dit pas « tu as oublié de taper ».
  /// Personne n'a fauté — la fenêtre redémarre, c'est tout.
  Future<void> _resetObservation(int count) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recommencer l’observation ?'),
        content: Text(
          count <= 1
              ? 'La cigarette enregistrée sera effacée, et l’observation '
                    'repartira de ton prochain tap.\n\nC’est définitif.'
              : 'Tes $count cigarettes enregistrées seront effacées, et '
                    'l’observation repartira de ton prochain tap.'
                    '\n\nC’est définitif.',
        ),
        actions: [
          // « Garder » d'abord et en pleine couleur : c'est l'issue sûre, et
          // c'est elle qui doit se toucher sans réfléchir. L'effacement est
          // teinté en erreur — le seul endroit de l'app où cette couleur sert.
          FilledButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Garder mes données'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Tout effacer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    unawaited(HapticFeedback.selectionClick());
    await ref.read(cigaretteRepositoryProvider).resetObservation();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    final last = ref.watch(lastCigaretteProvider).asData?.value;
    final todays =
        ref.watch(todaysCigarettesProvider).asData?.value ??
        const <Cigarette>[];
    final first = ref.watch(firstCigaretteProvider).asData?.value;
    // Le reset ne concerne QUE la vraie observation : dès qu'un mode est choisi,
    // le journal porte des jours-propres et un record d'écart max — on n'y touche
    // pas depuis un bouton de correction.
    final mode = ref.watch(currentModeProvider).asData?.value;
    final all =
        ref.watch(allCigarettesProvider).asData?.value ?? const <Cigarette>[];

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
              // Centré quand il y a la place, scrollable sinon (petits écrans) —
              // évite tout débordement de la colonne centrale.
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                        const SizedBox(height: 6),
                        const UndoLastButton(),
                        // Sortie de secours quand les premiers jours n'ont pas
                        // été tapés fidèlement : plus discrète qu'« Annuler »,
                        // et jamais proposée par l'app d'elle-même.
                        if (mode == null)
                          TextButton(
                            onPressed: () => _resetObservation(all.length),
                            style: TextButton.styleFrom(
                              foregroundColor: onSurface.withValues(alpha: 0.38),
                              textStyle: const TextStyle(fontSize: 12),
                              visualDensity: VisualDensity.compact,
                            ),
                            child: const Text('Recommencer l’observation'),
                          ),
                      ],
                    ),
                  ),
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
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HowItWorksScreen()),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: onSurface.withValues(alpha: 0.5),
                ),
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
            fontSize: 18,
            color: color,
            fontWeight: FontWeight.w500,
          ),
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
