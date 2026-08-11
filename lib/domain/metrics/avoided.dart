import '../../core/time/logical_day.dart';
import '../../data/database.dart';
import 'hourly.dart';
import 'metrics.dart';

/// « Ce que tu as évité » — estimation des cigarettes non fumées depuis le choix
/// du mode, par rapport au rythme d'**avant**.
///
/// La référence est **figée au choix du mode** (la moyenne/jour de la phase
/// d'observation), et ne bouge plus jamais. Une moyenne glissante tomberait dans
/// le piège qui rendait les Boss imbattables : comparé en permanence à son moi
/// récent, quelqu'un qui progresse ne verrait jamais rien monter.
///
/// Tout est **dérivé du journal**, rien n'est stocké.

/// Nombre minimal de jours observés avant d'oser une estimation. En dessous, la
/// moyenne est trop fragile pour qu'on affiche un chiffre : on se tait.
const int kAvoidedMinBaselineDays = 3;

/// Rythme de référence : moyenne de cigarettes par jour **avant** [since]
/// (la phase d'observation). `null` si on n'a pas de quoi l'estimer honnêtement.
double? baselinePerDay(List<Cigarette> cigs, DateTime? since) {
  if (since == null) return null;
  final before = [
    for (final c in cigs)
      if (c.occurredAtUtc.isBefore(since)) c,
  ];
  if (before.isEmpty) return null;
  final days = distinctLogicalDays(before);
  if (days < kAvoidedMinBaselineDays) return null;
  return before.length / days;
}

/// Estimation des cigarettes évitées sur le jour logique **contenant** l'instant
/// [moment] : `référence − fumées ce jour-là`, jamais négatif (fumer plus que
/// son rythme d'avant n'est pas une dette — le cairn ne recule pas).
int avoidedOn(List<Cigarette> cigs, double baseline, DateTime moment) =>
    _avoidedOnDay(cigs, baseline, LogicalDay.dayOf(moment));

/// [dayKey] est une **clé** de jour logique (celle que renvoie
/// `LogicalDay.dayOf`), surtout pas un instant : la repasser dans `dayOf`
/// donnerait la veille, puisqu'une clé est à minuit et que le jour bascule à 4 h.
int _avoidedOnDay(List<Cigarette> cigs, double baseline, DateTime dayKey) {
  var smoked = 0;
  for (final c in cigs) {
    if (LogicalDay.dayOf(wallTimeOf(c)) == dayKey) smoked++;
  }
  final avoided = baseline.round() - smoked;
  return avoided > 0 ? avoided : 0;
}

/// Cumul des cigarettes évitées depuis [since], sur les jours logiques
/// **terminés** uniquement — la journée en cours n'est pas finie, la compter
/// gonflerait le chiffre à chaque matin.
///
/// [notLogged] : les jours déclarés « pas tapés » sont **exclus** — on ne sait
/// pas ce qui s'y est passé, donc on ne s'en attribue pas le mérite.
int avoidedSince(
  List<Cigarette> cigs,
  DateTime? since,
  DateTime now, {
  Set<DateTime> notLogged = const {},
}) {
  final baseline = baselinePerDay(cigs, since);
  if (baseline == null || since == null) return 0;

  final today = LogicalDay.dayOf(now);
  var total = 0;
  for (var d = LogicalDay.dayOf(since.toLocal());
      d.isBefore(today);
      d = DateTime(d.year, d.month, d.day + 1)) {
    if (notLogged.contains(d)) continue;
    total += _avoidedOnDay(cigs, baseline, d);
  }
  return total;
}
