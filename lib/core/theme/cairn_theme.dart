import 'package:flutter/material.dart';

/// Palette minérale de Cairn — cairn de basalte sur sable chaud.
/// **Zéro rouge, zéro picto médical.** Le **lagon** est la « voix » de l'app :
/// rare, réservé aux moments où elle parle (pierre posée, palier, révélation).
/// Le vert est une teinte de nature/structure ; l'ocre, les pierres chaudes.
abstract final class CairnColors {
  // Jour
  static const sand = Color(0xFFE7D5B6); // la plage
  static const sandSurface = Color(0xFFF1E4CC);
  static const basalt = Color(0xFF3A3A38); // pierres du cairn
  static const basaltLight = Color(0xFF565450);
  static const ocre = Color(0xFFB0743F); // pierres chaudes, paliers
  static const vert = Color(0xFF4E7A5A); // teinte nature/structure
  static const lagon = Color(0xFF0E877F); // accent — la voix de l'app (rare)
  static const ink = Color(0xFF241F19); // texte

  // Nuit (cairn au clair de lune)
  static const nightGround = Color(0xFF141D1C);
  static const nightSurface = Color(0xFF1C2727);
  static const nightInk = Color(0xFFECE0C8);
  static const vertNight = Color(0xFF7FB489);
  static const ocreNight = Color(0xFFCB925C);
  static const lagonNight = Color(0xFF34C3B4);
}

ThemeData buildCairnLightTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: CairnColors.lagon,
    brightness: Brightness.light,
  ).copyWith(
    primary: CairnColors.lagon, // la voix de l'app — à n'utiliser qu'à bon escient
    secondary: CairnColors.ocre,
    tertiary: CairnColors.vert,
    surface: CairnColors.sandSurface,
    onSurface: CairnColors.ink,
  );
  return _base(scheme, CairnColors.sand, CairnColors.ink);
}

ThemeData buildCairnDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: CairnColors.lagon,
    brightness: Brightness.dark,
  ).copyWith(
    primary: CairnColors.lagonNight,
    secondary: CairnColors.ocreNight,
    tertiary: CairnColors.vertNight,
    surface: CairnColors.nightSurface,
    onSurface: CairnColors.nightInk,
  );
  return _base(scheme, CairnColors.nightGround, CairnColors.nightInk);
}

ThemeData _base(ColorScheme scheme, Color scaffold, Color ink) {
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  return base.copyWith(
    scaffoldBackgroundColor: scaffold,
    // TODO(Jalon 0): remplacer par une humaniste chaude bundlée en asset
    // (Fraunces / Marcellus) via google_fonts, pour rester 100 % offline.
    textTheme: base.textTheme.apply(
      bodyColor: ink,
      displayColor: ink,
    ),
  );
}
