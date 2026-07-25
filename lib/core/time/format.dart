/// Formatage du temps « depuis la dernière » — sobre, sans fioriture.
String formatSinceLast(Duration d) {
  if (d.inSeconds < 60) return "à l'instant";
  if (d.inMinutes < 60) return '${d.inMinutes} min';
  final h = d.inHours;
  final m = d.inMinutes % 60;
  return m == 0 ? '$h h' : '$h h ${m.toString().padLeft(2, '0')}';
}
