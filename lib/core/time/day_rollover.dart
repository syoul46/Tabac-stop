import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cigarette_repository.dart';
import 'logical_day.dart';

/// Tick d'horloge murale. Certaines décisions d'UI dépendent de l'heure sans que
/// rien ne change en base à l'instant du basculement — la plus critique étant la
/// re-révélation « tous les 5 jours » de qui a répondu « je ne sais pas encore »
/// (`resolvePhase` compare `now` à la date du choix). `RootScreen` ne se
/// recalcule que sur émission d'un provider ; il faut donc le pousser quand le
/// temps avance. [DayRollover] incrémente ce tick au retour au premier plan et à
/// chaque bascule de 04:00.
class WallClockTick extends Notifier<int> {
  @override
  int build() => 0;
  void tick() => state++;
}

final wallClockTickProvider =
    NotifierProvider<WallClockTick, int>(WallClockTick.new);

/// Le compteur « du jour » et la courbe horaire sont des flux drift dont la
/// borne de début (04:00 du jour logique) est calculée **une seule fois**, à
/// l'abonnement. drift ne réémet que sur changement de table, jamais au passage
/// du temps : si l'app survit à la bascule de 04:00 en arrière-plan, la borne
/// reste celle de la veille et le compteur additionne encore le jour d'avant
/// (« 15 au réveil »). Un redémarrage à froid recalcule la borne et corrige —
/// d'où l'aléatoire « parfois 15, parfois 0 » selon qu'Android a recyclé l'app.
///
/// Ce garde recalcule la borne à chaque bascule de jour logique : au retour au
/// premier plan, et via un timer armé sur le prochain 04:00 tant que l'app reste
/// ouverte. Il invalide alors les providers dérivés, qui se ré-abonnent avec la
/// bonne borne.
class DayRollover extends ConsumerStatefulWidget {
  const DayRollover({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<DayRollover> createState() => _DayRolloverState();
}

class _DayRolloverState extends ConsumerState<DayRollover>
    with WidgetsBindingObserver {
  DateTime _day = LogicalDay.dayOf(DateTime.now());
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _armTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // L'horloge a pu franchir 04:00 pendant la veille : on recalcule et on
    // ré-arme le timer sur la nouvelle borne.
    _refreshIfDayChanged();
    _tickClock(); // pousse les décisions d'UI temporelles (re-révélation J+5)
    _armTimer();
  }

  /// Arme un timer sur le prochain 04:00 local (+1 s de marge pour être sûr
  /// d'être passé de l'autre côté de la borne).
  void _armTimer() {
    _timer?.cancel();
    final now = DateTime.now();
    final next = LogicalDay.startOf(now).add(const Duration(days: 1));
    _timer = Timer(next.difference(now) + const Duration(seconds: 1), () {
      _refreshIfDayChanged();
      _tickClock();
      _armTimer();
    });
  }

  void _tickClock() => ref.read(wallClockTickProvider.notifier).tick();

  void _refreshIfDayChanged() {
    final today = LogicalDay.dayOf(DateTime.now());
    if (today == _day) return;
    _day = today;
    ref.invalidate(todayCountProvider);
    ref.invalidate(todaysCigarettesProvider);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
