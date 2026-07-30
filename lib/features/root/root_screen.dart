import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cigarette_repository.dart';
import '../../data/database.dart';
import '../../data/journey_repository.dart';
import '../../domain/journey/journey_state.dart';
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
        return const ReductionHome();
      case JourneyPhase.coldTurkey:
        return const ColdTurkeyHome();
      case JourneyPhase.firstLaunch:
      case JourneyPhase.observing:
      case JourneyPhase.undecided:
        return const TapScreen();
    }
  }
}
