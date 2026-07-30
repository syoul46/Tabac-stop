import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cigarette_repository.dart';
import '../../data/database.dart';
import '../../data/journey_repository.dart';
import '../../domain/journey/backup_prompt.dart';
import '../../domain/journey/journey_state.dart';
import '../backup/backup_screen.dart';
import '../coldturkey/cold_turkey_home.dart';
import '../reduction/reduction_home.dart';
import '../reveal/reveal_screen.dart';
import '../tap/tap_screen.dart';

/// Point d'entrée : résout la phase du parcours (machine à états pure) et montre
/// l'écran correspondant.
class RootScreen extends ConsumerWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cigs =
        ref.watch(allCigarettesProvider).asData?.value ?? const <Cigarette>[];
    final mode = ref.watch(currentModeProvider).asData?.value;

    switch (resolvePhase(cigs: cigs, mode: mode)) {
      case JourneyPhase.revealReady:
        return const RevealScreen();
      case JourneyPhase.reduction:
        return const _WithBackupAccess(child: ReductionHome());
      case JourneyPhase.coldTurkey:
        return const _WithBackupAccess(child: ColdTurkeyHome());
      case JourneyPhase.firstLaunch:
        return const TapScreen();
      case JourneyPhase.observing:
      case JourneyPhase.undecided:
        return const _WithBackupAccess(child: TapScreen());
    }
  }
}

/// Ajoute un accès discret à la sauvegarde (coin haut-droit) et, une seule fois
/// (≥ 3 jours de données), un bandeau doux proposant de sauvegarder. Pas sur
/// l'Écran 1 ni la révélation, qui restent purs.
class _WithBackupAccess extends ConsumerWidget {
  const _WithBackupAccess({required this.child});
  final Widget child;

  void _openBackup(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const BackupScreen()),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cigs =
        ref.watch(allCigarettesProvider).asData?.value ?? const <Cigarette>[];
    final events =
        ref.watch(journeyEventsProvider).asData?.value ?? const <JourneyEvent>[];
    final offer = shouldOfferBackup(cigs, events);

    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          right: 4,
          child: SafeArea(
            child: IconButton(
              icon: Icon(
                Icons.shield_outlined,
                color:
                    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
              ),
              tooltip: 'Sauvegarde',
              onPressed: () => _openBackup(context),
            ),
          ),
        ),
        if (offer)
          Positioned(
            left: 16,
            right: 16,
            bottom: 0,
            child: SafeArea(
              child: _BackupPrompt(
                onLater: () =>
                    ref.read(journeyRepositoryProvider).markBackupPromptSeen(),
                onSave: () {
                  ref.read(journeyRepositoryProvider).markBackupPromptSeen();
                  _openBackup(context);
                },
              ),
            ),
          ),
      ],
    );
  }
}

/// Bandeau du J4 : proposé une seule fois. Factuel, pas culpabilisant.
class _BackupPrompt extends StatelessWidget {
  const _BackupPrompt({required this.onLater, required this.onSave});
  final VoidCallback onLater;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Tu as 3 jours d’historique. Sauvegarde-les — chiffré, '
            'sur ton téléphone.',
            style: TextStyle(
                fontSize: 13.5,
                height: 1.35,
                color: c.onSurface.withValues(alpha: 0.85)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onLater,
                style: TextButton.styleFrom(
                    foregroundColor: c.onSurface.withValues(alpha: 0.6)),
                child: const Text('Plus tard'),
              ),
              const SizedBox(width: 4),
              FilledButton(
                onPressed: onSave,
                style: FilledButton.styleFrom(
                    backgroundColor: c.primary, foregroundColor: c.onPrimary),
                child: const Text('Sauvegarder'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
