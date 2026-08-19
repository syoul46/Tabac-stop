import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/cairn_theme.dart';
import '../core/update/update_service.dart';
import '../data/cigarette_repository.dart';
import '../data/database.dart';
import '../data/journey_repository.dart';
import '../domain/models/enums.dart';
import '../features/cairn/cairn_view.dart';
import '../features/help/how_it_works_screen.dart';
import '../features/reduction/reduction_home.dart';
import '../features/reveal/reveal_screen.dart';
import '../features/update/update_banner.dart';
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

  // Historique de ~3 semaines pour montrer la courbe d'évolution : 7 jours
  // d'observation (~6/j → rythme d'avant), puis réduction déclinante (~5 → 2).
  const hours = [7, 12, 18, 21, 8, 15, 10, 14, 16, 20];
  void addDay(int dayAgo, int count) {
    for (var k = 0; k < count; k++) {
      final h = hours[k % hours.length];
      final ctx = switch (h) {
        7 => CigContext.cafe.index,
        12 => CigContext.repas.index,
        21 => CigContext.alcool.index,
        _ => null,
      };
      cigs.add(c(dayAgo, h, (k * 13) % 60, ctx));
    }
  }

  for (var day = 20; day >= 14; day--) {
    addDay(day, 6); // observation
  }
  const reduction = [5, 5, 4, 5, 4, 4, 3, 4, 3, 2, 3, 2, 2, 2]; // jours 13 → 0
  for (var i = 0; i < reduction.length; i++) {
    addDay(13 - i, reduction[i]);
  }
  // Mode choisi au début du jour logique -13 → l'observation (jours 20..14)
  // devient la référence figée (« rythme d'avant » ≈ 6/j).
  final fightSince = DateTime.utc(now.year, now.month, now.day - 13, 4);

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
      // Un mode choisi → le bouton « Revoir ma révélation » apparaît dans les stats.
      currentModeProvider.overrideWith((ref) => Stream.value(JourneyMode.reduction)),
      // Date du choix → active « ce que tu as évité » + la ligne du rythme d'avant.
      currentModeSinceProvider.overrideWith((ref) => Stream.value(fightSince)),
      // Force une fausse mise à jour dispo (pour le preview du bandeau).
      updateCheckProvider.overrideWith((ref) => const UpdateInfo(
            version: '1.6.0',
            notes: '## Nouveautés\n\n'
                '- **Observation sur une semaine.** La révélation après 7 jours réels.\n'
                '- **Revoir ta révélation.** Change d\'approche quand tu veux.\n'
                '- **Annuler le dernier tap.** Corrige un enregistrement par erreur.\n\n'
                '## Corrigé\n\n'
                '- **Réduction** : le chrono reste toujours visible.\n',
            apkUrl: '',
            apkSize: 0,
            pageUrl: '',
          )),
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
        'combat' => const ReductionHome(),
        'dust' => const _AutoDrop(),
        'help' => const HowItWorksScreen(),
        'revisit' => const RevealScreen(revisit: true),
        'update' => const Scaffold(
            body: Stack(children: [Center(child: Text('écran de fond')), UpdateBanner()]),
          ),
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
