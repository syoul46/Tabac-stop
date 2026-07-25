import 'package:flutter/foundation.dart';

/// Le « jour logique » de Cairn commence à **04:00 locale** (pas minuit), pour
/// ne pas couper les gros créneaux du soir en deux. Une cigarette à 1 h du matin
/// compte donc sur la journée de la veille.
///
/// Impacte le compteur du jour et les jours-propres cumulés.
@immutable
class LogicalDay {
  const LogicalDay._();

  /// Heure de bascule d'un jour logique au suivant.
  static const int startHour = 4;

  /// Date (à minuit) du jour logique auquel appartient l'instant [local]
  /// exprimé en **heure murale locale**.
  static DateTime dayOf(DateTime local) {
    final shifted = local.subtract(const Duration(hours: startHour));
    return DateTime(shifted.year, shifted.month, shifted.day);
  }

  /// Vrai si [a] et [b] (heures murales locales) tombent le même jour logique.
  static bool sameDay(DateTime a, DateTime b) => dayOf(a) == dayOf(b);
}
