import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cigarette_repository.dart';

/// Canal natif partagé avec `MainActivity.kt`.
const _native = MethodChannel('cairn/installer');

/// Pousse vers le widget d'écran d'accueil ce qu'il doit afficher : l'**instant**
/// de la dernière cigarette et le compte du jour.
///
/// On envoie des données brutes, jamais du texte déjà mis en forme : le widget
/// doit rester juste quand l'app ne tourne pas, et Android ne le rafraîchit au
/// mieux que toutes les 30 min. C'est lui qui fait avancer le chrono.
///
/// **Android uniquement** — aucun plugin n'est utilisé pour ça, précisément pour
/// ne rien ajouter au build iOS (cf. PLAN §17.4).
class WidgetSync extends ConsumerWidget {
  const WidgetSync({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (Platform.isAndroid) {
      final last = ref.watch(lastCigaretteProvider).asData?.value;
      final today = ref.watch(todayCountProvider).asData?.value;
      // `listen`-like : on pousse à chaque rebuild utile. L'appel est idempotent
      // et coûte une écriture de préférences — inutile de mémoriser l'état.
      _push(
        lastSmokeAt: last?.occurredAtUtc.millisecondsSinceEpoch,
        todayCount: today,
      );
    }
    return child;
  }

  static void _push({int? lastSmokeAt, int? todayCount}) {
    _native.invokeMethod<void>('updateWidget', {
      'lastSmokeAt': lastSmokeAt ?? -1,
      'todayCount': todayCount ?? -1,
    }).catchError((_) {
      // Le widget est un bonus : s'il échoue, l'app continue en silence.
    });
  }
}
