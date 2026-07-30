import '../../data/database.dart';
import '../metrics/metrics.dart';
import '../models/enums.dart';

/// Nombre de jours logiques de données à partir duquel on propose une sauvegarde.
const int kBackupPromptMinDays = 3;

/// Vrai s'il faut proposer la sauvegarde : au moins [kBackupPromptMinDays] jours
/// d'historique ET jamais proposée jusqu'ici. C'est l'argument du J4 :
/// « tu as 3 jours d'historique, ce serait bête de les perdre ».
bool shouldOfferBackup(
  List<Cigarette> cigs,
  List<JourneyEvent> events, {
  int minDays = kBackupPromptMinDays,
}) {
  final seen =
      events.any((e) => e.kind == JourneyEventKind.backupPromptSeen.name);
  if (seen) return false;
  return distinctLogicalDays(cigs) >= minDays;
}
