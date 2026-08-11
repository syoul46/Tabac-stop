import 'dart:convert';

import '../../core/time/logical_day.dart';
import '../../data/database.dart';
import '../models/enums.dart';

/// Format de la clé de jour dans le payload de [JourneyEventKind.dayNotLogged].
/// Une date nue (pas un instant) : le jour logique, pas une heure.
String dayKey(DateTime logicalDay) =>
    '${logicalDay.year.toString().padLeft(4, '0')}-'
    '${logicalDay.month.toString().padLeft(2, '0')}-'
    '${logicalDay.day.toString().padLeft(2, '0')}';

/// Les jours logiques déclarés « je n'ai rien tapé » par l'utilisateur.
///
/// Fonction pure. Ces jours sont **neutres** partout : ni propres, ni fumés.
/// Sans eux, une journée oubliée passerait pour une victoire — et comme les
/// jours-propres cumulés et le record d'écart ne redescendent jamais, le
/// mensonge serait définitif.
Set<DateTime> notLoggedDays(Iterable<JourneyEvent> events) {
  final out = <DateTime>{};
  for (final e in events) {
    if (e.kind != JourneyEventKind.dayNotLogged.name) continue;
    final payload = e.payload;
    if (payload == null) continue;
    try {
      final raw = (jsonDecode(payload) as Map)['day'] as String?;
      if (raw == null) continue;
      final parts = raw.split('-');
      if (parts.length != 3) continue;
      out.add(DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      ));
    } catch (_) {
      continue; // payload illisible : on l'ignore plutôt que de planter
    }
  }
  return out;
}

/// Vrai si [wall] (heure murale locale) tombe un jour déclaré non tapé.
bool isNotLogged(DateTime wall, Set<DateTime> days) =>
    days.contains(LogicalDay.dayOf(wall));
