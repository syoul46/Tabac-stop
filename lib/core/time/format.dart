/// Formatage du temps « depuis la dernière » — sobre, sans fioriture.
String formatSinceLast(Duration d) {
  if (d.inSeconds < 60) return "à l'instant";
  if (d.inMinutes < 60) return '${d.inMinutes} min';
  final h = d.inHours;
  final m = d.inMinutes % 60;
  return m == 0 ? '$h h' : '$h h ${m.toString().padLeft(2, '0')}';
}

/// Formatage d'un streak (peut durer des jours) — « 2 j 5 h », « 3 h 20 »…
String formatStreak(Duration d) {
  if (d.inDays >= 1) {
    final h = d.inHours % 24;
    return h == 0 ? '${d.inDays} j' : '${d.inDays} j $h h';
  }
  return formatSinceLast(d);
}
