import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cigarette_repository.dart';
import '../../data/database.dart';
import '../../data/journey_repository.dart';
import '../../domain/boss/victory.dart';
import '../cairn/cairn_view.dart';

/// Overlay de **victoire de Boss** : quand un Boss est vaincu (délai tenu le
/// nombre de jours requis), on **hisse** un gros rocher au sommet du cairn et on
/// le célèbre — une seule fois. Déclenché par un événement (pas de ticker).
class BossVictoryReveal extends ConsumerStatefulWidget {
  const BossVictoryReveal({super.key});

  @override
  ConsumerState<BossVictoryReveal> createState() => _BossVictoryRevealState();
}

class _BossVictoryRevealState extends ConsumerState<BossVictoryReveal> {
  // Le rocher part absent puis est hissé (0 → 1) juste après l'apparition, ce
  // qui déclenche l'animation de hissage de CairnView.
  int _rocks = 0;
  bool _armed = false;

  void _armHoist() {
    if (_armed) return;
    _armed = true;
    // Laisse la carte apparaître, puis hisse le rocher.
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _rocks = 1);
    });
    // Buzz plus marqué au calage du rocher (fin du hissage).
    Future.delayed(const Duration(milliseconds: 720), () {
      if (mounted) HapticFeedback.heavyImpact();
    });
  }

  @override
  Widget build(BuildContext context) {
    final events =
        ref.watch(journeyEventsProvider).asData?.value ?? const <JourneyEvent>[];
    final cigs =
        ref.watch(allCigarettesProvider).asData?.value ?? const <Cigarette>[];
    final report = ref.watch(bossReportProvider);
    final key = pendingBossVictory(report, cigs, events);
    if (key == null) {
      // Réinitialise pour la prochaine victoire.
      _armed = false;
      _rocks = 0;
      return const SizedBox.shrink();
    }
    _armHoist();

    final name = bossForKey(report, key)?.name ?? 'un Boss';

    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final hibiscus = theme.brightness == Brightness.dark
        ? const Color(0xFFE07050)
        : const Color(0xFFCB5A38);

    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.6),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            builder: (context, tIn, child) => Opacity(
              opacity: tIn,
              child: Transform.scale(scale: 0.96 + 0.04 * tIn, child: child),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 30),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: hibiscus.withValues(alpha: 0.5)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'BOSS VAINCU',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                      color: hibiscus,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Le rocher est hissé au sommet (animation de CairnView).
                  CairnView(
                      stones: 3,
                      bossRocks: _rocks,
                      width: 150,
                      height: 150),
                  const SizedBox(height: 14),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tu l’as hissé en haut du cairn. Il n’y retombera pas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13.5,
                        height: 1.3,
                        color: c.onSurface.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: () => ref
                        .read(journeyRepositoryProvider)
                        .markBossDefeated(key),
                    style: FilledButton.styleFrom(
                        backgroundColor: hibiscus,
                        foregroundColor: Colors.white),
                    child: const Text('Continuer'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
