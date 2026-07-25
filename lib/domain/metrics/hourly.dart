import '../../data/database.dart';

/// Heure murale locale au moment du tap, reconstituée depuis l'instant UTC + le
/// décalage capturé (`tzOffsetMin`) — indépendant du fuseau courant de lecture.
/// C'est cette heure-là qu'on clusterisera pour détecter les Boss.
DateTime wallTimeOf(Cigarette c) =>
    c.occurredAtUtc.toUtc().add(Duration(minutes: c.tzOffsetMin));

/// Heure locale (0–23) où la cigarette a été fumée.
int localHourOf(Cigarette c) => wallTimeOf(c).hour;

/// Comptes par heure locale : liste de 24 entiers (index = heure).
List<int> hourlyCounts(Iterable<Cigarette> cigs) {
  final buckets = List<int>.filled(24, 0);
  for (final c in cigs) {
    buckets[localHourOf(c)]++;
  }
  return buckets;
}
