import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cigarette_repository.dart';
import '../../data/journey_repository.dart';
import '../../domain/models/enums.dart';
import 'notification_service.dart';

/// (Re)planifie les notifications de **paliers santé** quand la dernière
/// cigarette ou le mode change — les deux seuls moments où la cible bouge.
///
/// Uniquement **en mode** (réduction / arrêt net) : les paliers sont une notion
/// de mode (comme leur révélation à l'écran). En observation ou sur l'Écran 1,
/// on n'a rien à annoncer, donc rien n'est planifié (et aucune permission
/// réclamée). Hors mode, on annule ce qui traînait.
class MilestoneNotifier extends ConsumerWidget {
  const MilestoneNotifier({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Les notifications n'existent que sur mobile ; hors Android/iOS (bureau,
    // `flutter test`) le plugin n'est pas enregistré et l'appeler planterait.
    if (!Platform.isAndroid && !Platform.isIOS) return child;

    final mode = ref.watch(currentModeProvider).asData?.value;
    final last = ref.watch(lastCigaretteProvider).asData?.value;
    final svc = ref.read(notificationServiceProvider);

    final inMode =
        mode == JourneyMode.reduction || mode == JourneyMode.coldTurkey;
    if (inMode && last != null) {
      final lastLocal = last.occurredAtUtc.toLocal();
      final raw = DateTime.now().difference(lastLocal);
      final abstinence = raw.isNegative ? Duration.zero : raw;
      svc.scheduleHealthMilestones(
        lastLocal: lastLocal,
        abstinenceNow: abstinence,
      );
    } else {
      svc.cancelHealthMilestones();
    }
    return child;
  }
}
