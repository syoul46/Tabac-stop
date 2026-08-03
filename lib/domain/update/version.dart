/// Comparaison de versions sémantiques, en Dart pur (testable, zéro dépendance).
///
/// Tolère un préfixe `v` (tags GitHub type `v1.2.3`) et un suffixe de build
/// (`1.2.3+4` de pubspec) qui est ignoré pour la comparaison.
library;

/// Normalise `v1.2.3+4` → `[1, 2, 3]`. Les parties non numériques valent 0.
List<int> parseVersion(String raw) {
  var s = raw.trim();
  if (s.startsWith('v') || s.startsWith('V')) s = s.substring(1);
  // Retire un éventuel suffixe de build/pré-release (`+4`, `-beta`).
  final cut = s.indexOf(RegExp(r'[+\-]'));
  if (cut != -1) s = s.substring(0, cut);
  final parts = s.split('.');
  return [
    for (final p in parts) int.tryParse(p.trim()) ?? 0,
  ];
}

/// -1 si a < b, 0 si égales, 1 si a > b. Les longueurs différentes sont
/// complétées par des 0 (`1.2` == `1.2.0`).
int compareVersions(String a, String b) {
  final va = parseVersion(a);
  final vb = parseVersion(b);
  final n = va.length > vb.length ? va.length : vb.length;
  for (var i = 0; i < n; i++) {
    final x = i < va.length ? va[i] : 0;
    final y = i < vb.length ? vb[i] : 0;
    if (x != y) return x < y ? -1 : 1;
  }
  return 0;
}

/// `true` si `latest` est strictement plus récente que `current`.
bool isNewer(String latest, String current) => compareVersions(latest, current) > 0;
