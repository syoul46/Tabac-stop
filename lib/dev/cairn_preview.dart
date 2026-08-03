import 'package:flutter/material.dart';

import '../core/theme/cairn_theme.dart';
import '../features/cairn/cairn_view.dart';

/// Écran de prévisualisation (dev only) du cairn dessiné à plusieurs hauteurs.
/// Lancer : `flutter run -t lib/dev/cairn_preview.dart`.
void main() => runApp(const _PreviewApp());

class _PreviewApp extends StatelessWidget {
  const _PreviewApp();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildCairnLightTheme(),
      home: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: const [
                _Row(items: [
                  _Item(stones: 2, progress: 0.4, label: '2 · 20 min'),
                  _Item(stones: 4, progress: 0.6, label: '4 · 48 h'),
                ]),
                _Row(items: [
                  _Item(stones: 7, progress: 0.3, label: '7 · 2 sem.'),
                  _Item(stones: 6, bossRocks: 1, label: '6 + 1 Boss'),
                ]),
                _Row(items: [
                  _Item(stones: 8, bossRocks: 2, label: '8 + 2 Boss'),
                  _Item(stones: 10, progress: 1.0, label: '10 · 1 an'),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.items});
  final List<_Item> items;
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: items);
}

class _Item extends StatelessWidget {
  const _Item(
      {required this.stones,
      this.progress = 0,
      this.bossRocks = 0,
      required this.label});
  final int stones;
  final double progress;
  final int bossRocks;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CairnView(
            stones: stones,
            progress: progress,
            bossRocks: bossRocks,
            width: 160,
            height: 210),
        Text(label),
        const SizedBox(height: 8),
      ],
    );
  }
}
