import 'package:flutter/material.dart';

import '../core/theme/cairn_theme.dart';
import '../features/cairn/cairn_view.dart';

/// Écran de prévisualisation (dev only) du cairn dessiné et de son animation de
/// pose. Lancer : `flutter run -t lib/dev/cairn_preview.dart`.
void main() => runApp(const _PreviewApp());

class _PreviewApp extends StatelessWidget {
  const _PreviewApp();
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildCairnLightTheme(),
        home: const _Preview(),
      );
}

class _Preview extends StatefulWidget {
  const _Preview();
  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview> {
  int stones = 2;
  int bossRocks = 0;
  double progress = 0.4;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            CairnView(
                stones: stones,
                progress: progress,
                bossRocks: bossRocks,
                width: 240,
                height: 320),
            const Spacer(),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton(
                  onPressed: () => setState(() => stones++),
                  child: const Text('Poser une pierre'),
                ),
                FilledButton.tonal(
                  onPressed: () => setState(() => bossRocks++),
                  child: const Text('Rocher de Boss'),
                ),
                OutlinedButton(
                  onPressed: () => setState(() {
                    stones = 2;
                    bossRocks = 0;
                  }),
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
