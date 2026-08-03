import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/cairn_theme.dart';
import '../data/cigarette_repository.dart';
import '../data/database.dart';
import '../data/journey_repository.dart';
import '../domain/models/enums.dart';
import '../features/cairn/cairn_view.dart';
import '../features/help/how_it_works_screen.dart';
import '../features/stats/stats_screen.dart';
import '../features/tap/tap_screen.dart';

/// Preview (dev only) des écrans avec de fausses données injectées par overrides.
/// `flutter run -t lib/dev/screens_preview.dart`.
void main() {
  final now = DateTime.now();
  final cigs = <Cigarette>[];
  var id = 0;
  Cigarette c(int dayAgo, int h, int m, [int? ctx]) {
    final d = DateTime.utc(now.year, now.month, now.day - dayAgo, h, m);
    return Cigarette(
      id: 'c${id++}',
      occurredAtUtc: d,
      tzOffsetMin: 0,
      contextA: ctx,
      wasBoss: false,
      duringDelay: false,
    );
  }

  for (var day = 2; day >= 0; day--) {
    cigs.add(c(day, 7, 10, CigContext.cafe.index));
    cigs.add(c(day, 8, 0));
    cigs.add(c(day, 12, 30, CigContext.repas.index));
    cigs.add(c(day, 15, 0));
    cigs.add(c(day, 18, 0));
    cigs.add(c(day, 21, 0, CigContext.alcool.index));
  }

  JourneyEvent ev(String kind, {String? bossKey, int i = 0}) => JourneyEvent(
        id: 'e$kind$i',
        occurredAtUtc: now.toUtc().subtract(Duration(days: i)),
        kind: kind,
        payload: bossKey == null ? null : jsonEncode({'bossKey': bossKey}),
      );

  final events = <JourneyEvent>[
    ev(JourneyEventKind.delayHeld.name, bossKey: 'h15', i: 3),
    ev(JourneyEventKind.delayHeld.name, bossKey: 'h15', i: 2),
    ev(JourneyEventKind.delayHeld.name, bossKey: 'h15', i: 1),
    ev(JourneyEventKind.bossDefeated.name, bossKey: 'h15'),
    ev(JourneyEventKind.delayHeld.name, bossKey: 'h7', i: 0),
  ];

  // Observation : peu de données (jour 1, quelques taps) pour le mini-cairn.
  final obsCigs = [c(0, 7, 10, CigContext.cafe.index), c(0, 8, 30)];

  runApp(ProviderScope(
    overrides: [
      allCigarettesProvider.overrideWith((ref) => Stream.value(cigs)),
      journeyEventsProvider.overrideWith((ref) => Stream.value(events)),
      lastCigaretteProvider.overrideWith((ref) => Stream.value(obsCigs.last)),
      todaysCigarettesProvider.overrideWith((ref) => Stream.value(obsCigs)),
      firstCigaretteProvider.overrideWith((ref) => Stream.value(obsCigs.first)),
    ],
    child: const _App(),
  ));
}

class _App extends StatelessWidget {
  const _App();
  @override
  Widget build(BuildContext context) {
    const screen = String.fromEnvironment('SCREEN', defaultValue: 'stats');
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildCairnLightTheme(),
      home: switch (screen) {
        'obs' => const TapScreen(),
        'dust' => const _AutoDrop(),
        'help' => const HowItWorksScreen(),
        _ => const StatsScreen(),
      },
    );
  }
}

/// Fait tomber une pierre toute seule en boucle, pour filmer la poussière sans
/// dépendre du tactile.
class _AutoDrop extends StatefulWidget {
  const _AutoDrop();
  @override
  State<_AutoDrop> createState() => _AutoDropState();
}

class _AutoDropState extends State<_AutoDrop> {
  int _stones = 2;
  @override
  void initState() {
    super.initState();
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 1600));
      if (!mounted) return false;
      setState(() => _stones = _stones >= 7 ? 2 : _stones + 1);
      return true;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: CairnView(
              stones: _stones, haptics: false, width: 260, height: 340),
        ),
      );
}
