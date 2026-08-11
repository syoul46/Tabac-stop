import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cigarette_repository.dart';

/// « Annuler » : supprime la **dernière** cigarette enregistrée — un mis-tap.
///
/// Discret et toujours disponible : un tap par erreur peut se remarquer bien
/// plus tard. Avec confirmation, parce que la suppression est définitive.
///
/// **Ne défait que la cigarette.** Les événements de parcours déjà journalisés
/// (un délai rompu, par exemple) restent : le temps a passé, et faire
/// ressusciter un délai interrompu ouvrirait une porte pour gagner un Boss sans
/// l'avoir tenu. Les délais sont relançables — on en repart un, c'est tout.
class UndoLastButton extends ConsumerWidget {
  const UndoLastButton({super.key});

  Future<void> _undo(BuildContext context, WidgetRef ref) async {
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
    if (confirmed != true || !context.mounted) return;
    unawaited(HapticFeedback.selectionClick());
    await ref.read(cigaretteRepositoryProvider).undoLastCigarette();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return TextButton.icon(
      onPressed: () => _undo(context, ref),
      icon: const Icon(Icons.undo, size: 16),
      label: const Text('Annuler'),
      style: TextButton.styleFrom(
        foregroundColor: onSurface.withValues(alpha: 0.5),
      ),
    );
  }
}
