import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cigarette_repository.dart';
import '../../data/database.dart';
import '../../data/journey_repository.dart';
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

/// Ajoute un accès discret à la sauvegarde (coin haut-droit) — pas sur l'Écran 1
/// ni la révélation, qui restent purs.
class _WithBackupAccess extends StatelessWidget {
  const _WithBackupAccess({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
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
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
              ),
              tooltip: 'Sauvegarde',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BackupScreen()),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
