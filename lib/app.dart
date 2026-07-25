import 'package:flutter/material.dart';

import 'core/theme/cairn_theme.dart';
import 'features/home/home_screen.dart';

/// Racine de l'app. Le thème suit le système (jour / nuit), les deux étant
/// dessinés — jamais inversés.
class CairnApp extends StatelessWidget {
  const CairnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cairn',
      debugShowCheckedModeBanner: false,
      theme: buildCairnLightTheme(),
      darkTheme: buildCairnDarkTheme(),
      home: const HomeScreen(),
    );
  }
}
