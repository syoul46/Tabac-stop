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

  /// Instant local (04:00) de début du jour logique contenant [local].
  static DateTime startOf(DateTime local) {
    final d = dayOf(local);
    return DateTime(d.year, d.month, d.day, startHour);
  }

  /// Vrai si [a] et [b] (heures murales locales) tombent le même jour logique.
  static bool sameDay(DateTime a, DateTime b) => dayOf(a) == dayOf(b);

  /// Index (1-based) du jour logique de [now] par rapport à celui de [first].
  /// Le jour du premier tap = 1.
  static int indexSince(DateTime firstWall, DateTime nowWall) =>
      dayOf(nowWall).difference(dayOf(firstWall)).inDays + 1;
}
