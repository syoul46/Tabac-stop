import 'package:flutter/material.dart';

/// Palette minérale de Cairn — cairn de basalte sur sable chaud.
/// **Zéro rouge, zéro picto médical.** Le vert discret est la « voix » de
/// l'app : rare, réservé aux moments où l'app parle (pierre posée, palier).
abstract final class CairnColors {
  // Jour
  static const sand = Color(0xFFE7D5B6); // la plage
  static const sandSurface = Color(0xFFF1E4CC);
  static const basalt = Color(0xFF3A3A38); // pierres du cairn
  static const basaltLight = Color(0xFF565450);
  static const ocre = Color(0xFFB0743F); // pierres chaudes, paliers
  static const vert = Color(0xFF4E7A5A); // accent — la voix de l'app
  static const ink = Color(0xFF241F19); // texte

  // Nuit (cairn au clair de lune)
  static const nightGround = Color(0xFF141D1C);
  static const nightSurface = Color(0xFF1C2727);
  static const nightInk = Color(0xFFECE0C8);
  static const vertNight = Color(0xFF7FB489);
  static const ocreNight = Color(0xFFCB925C);
}

ThemeData buildCairnLightTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: CairnColors.vert,
    brightness: Brightness.light,
  ).copyWith(
    primary: CairnColors.vert,
    secondary: CairnColors.ocre,
    surface: CairnColors.sandSurface,
    onSurface: CairnColors.ink,
  );
  return _base(scheme, CairnColors.sand, CairnColors.ink);
}

ThemeData buildCairnDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: CairnColors.vert,
    brightness: Brightness.dark,
  ).copyWith(
    primary: CairnColors.vertNight,
    secondary: CairnColors.ocreNight,
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
