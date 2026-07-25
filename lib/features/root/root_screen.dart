import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cigarette_repository.dart';
import '../../data/database.dart';
import '../../data/journey_repository.dart';
import '../../domain/journey/reveal_gate.dart';
import '../reveal/reveal_screen.dart';
import '../tap/tap_screen.dart';

/// Choisit l'écran selon l'état du journal :
/// - aucun tap ou observation en cours → l'écran du bouton ;
/// - seuil atteint et aucun mode encore choisi → la révélation J+3.
class RootScreen extends ConsumerWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cigs =
        ref.watch(allCigarettesProvider).asData?.value ?? const <Cigarette>[];
    final mode = ref.watch(currentModeProvider).asData?.value;

    if (cigs.isNotEmpty && mode == null && shouldReveal(cigs)) {
      return const RevealScreen();
    }
    return const TapScreen();
  }
}
