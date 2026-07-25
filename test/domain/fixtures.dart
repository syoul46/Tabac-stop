import 'package:cairn/data/database.dart';

/// Construit une cigarette dont l'heure MURALE locale est [y-mo-d h:mi], avec le
/// décalage [offsetMin]. On stocke l'instant UTC correspondant, de sorte que
/// `wallTimeOf` reconstitue exactement cette heure murale (indépendante du fuseau).
Cigarette cigWall(
  int y,
  int mo,
  int d,
  int h,
  int mi, {
  int offsetMin = 0,
  String id = 'c',
}) {
  final wall = DateTime.utc(y, mo, d, h, mi);
  return Cigarette(
    id: id,
    occurredAtUtc: wall.subtract(Duration(minutes: offsetMin)),
    tzOffsetMin: offsetMin,
    wasBoss: false,
    duringDelay: false,
  );
}

/// Faux fumeur régulier : répète [dailyTimes] (heures murales, ex. `[(7,10),(21,0)]`)
/// sur [days] jours consécutifs à partir du [start].
List<Cigarette> fakeSmoker({
  required DateTime start,
  required List<(int, int)> dailyTimes,
  int days = 3,
  int offsetMin = 0,
}) {
  final out = <Cigarette>[];
  var i = 0;
  for (var day = 0; day < days; day++) {
    for (final (h, m) in dailyTimes) {
      out.add(cigWall(
        start.year,
        start.month,
        start.day + day,
        h,
        m,
        offsetMin: offsetMin,
        id: 'c${i++}',
      ));
    }
  }
  return out;
}
