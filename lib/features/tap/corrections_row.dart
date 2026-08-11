import 'package:flutter/material.dart';

import 'forgot_sheet.dart';
import 'undo_last_button.dart';

/// Les deux corrections, **côte à côte** : « Annuler » et « J'ai oublié ».
///
/// Empilées, elles mangeaient deux lignes et poussaient le contenu jusque sur
/// la courbe horaire. Sur une même ligne, elles tiennent la place d'une seule —
/// et ces deux gestes se ressemblent assez pour vivre ensemble.
class CorrectionsRow extends StatelessWidget {
  const CorrectionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(child: UndoLastButton()),
        SizedBox(width: 4),
        Flexible(child: ForgotButton()),
      ],
    );
  }
}
