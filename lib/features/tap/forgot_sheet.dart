import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/time/logical_day.dart';
import '../../data/cigarette_repository.dart';
import '../../data/journey_repository.dart';

/// « J'ai oublié… » — les corrections d'oubli, sur les **trois** écrans de tap.
///
/// Une seule entrée discrète plutôt que deux boutons de plus : l'Écran 1 doit
/// rester un bouton. L'app ne propose jamais ça d'elle-même — c'est une porte
/// que l'utilisateur pousse quand il sait que ses données sont fausses.
class ForgotButton extends ConsumerWidget {
  const ForgotButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return TextButton(
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => const _ForgotSheet(),
      ),
      style: TextButton.styleFrom(
        foregroundColor: onSurface.withValues(alpha: 0.38),
        textStyle: const TextStyle(fontSize: 12),
        visualDensity: VisualDensity.compact,
      ),
      child: const Text('J’ai oublié de taper'),
    );
  }
}

class _ForgotSheet extends ConsumerWidget {
  const _ForgotSheet();

  /// Une cigarette dont on connaît l'heure. L'horodatage est **vrai** (« il est
  /// 18 h, je n'ai pas tapé celle de 17 h ») : il peut donc nourrir la détection
  /// des Boss sans la fausser — contrairement à des heures inventées en masse.
  Future<void> _addForgotten(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.subtract(const Duration(hours: 1))),
      helpText: 'Elle était à quelle heure ?',
    );
    if (picked == null || !context.mounted) return;

    var when = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
    // Une heure « dans le futur » ne peut désigner qu'hier soir.
    if (when.isAfter(now)) when = when.subtract(const Duration(days: 1));

    await ref.read(cigaretteRepositoryProvider).logSmoke(at: when);
    unawaited(HapticFeedback.selectionClick());
    if (context.mounted) Navigator.pop(context);
  }

  /// Une journée entière non tapée. **Aucune heure inventée** : on ne connaît
  /// pas les cigarettes de ce jour-là, on déclare seulement qu'on ne sait pas.
  /// Le jour devient neutre — ni propre, ni fumé, le cairn se met en pause.
  Future<void> _declareDay(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.subtract(const Duration(days: 1)),
      firstDate: now.subtract(const Duration(days: 60)),
      lastDate: now,
      helpText: 'Quel jour n’as-tu rien tapé ?',
    );
    if (picked == null || !context.mounted) return;

    await ref
        .read(journeyRepositoryProvider)
        .declareDayNotLogged(LogicalDay.dayOf(picked));
    unawaited(HapticFeedback.selectionClick());
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = Theme.of(context).colorScheme;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Ajouter une cigarette oubliée'),
            subtitle: const Text('tu te souviens de l’heure'),
            onTap: () => _addForgotten(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.event_busy),
            title: const Text('Je n’ai rien tapé de la journée'),
            subtitle: const Text('la journée ne comptera ni pour ni contre'),
            onTap: () => _declareDay(context, ref),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text(
              'Une journée non tapée n’est pas une journée sans tabac. '
              'La déclarer évite qu’elle compte comme une victoire.',
              style: TextStyle(
                fontSize: 11.5,
                color: c.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
