import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/cairn_theme.dart';

/// Le cairn dessiné : des pierres empilées qui montent avec la progression.
/// [stones] = pierres pleines (fondation comprise) ; [progress] (0..1) fait
/// apparaître une pierre « en formation » au sommet, vers le prochain palier.
///
/// Rendu **stable** entre deux reconstructions (les variations organiques sont
/// dérivées de l'index de la pierre, pas d'un aléatoire).
class CairnView extends StatelessWidget {
  const CairnView({
    super.key,
    required this.stones,
    this.progress = 0,
    this.width = 190,
    this.height = 210,
  });

  final int stones;
  final double progress;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final palette = dark
        ? const [
            Color(0xFF565450),
            CairnColors.ocreNight,
            Color(0xFF6B6864),
            CairnColors.vertNight,
          ]
        : const [
            CairnColors.basalt,
            CairnColors.ocre,
            CairnColors.basaltLight,
            CairnColors.vert,
          ];
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _CairnPainter(
          stones: stones.clamp(0, 40),
          progress: progress.clamp(0.0, 1.0),
          palette: palette,
          dark: dark,
        ),
      ),
    );
  }
}

class _CairnPainter extends CustomPainter {
  _CairnPainter({
    required this.stones,
    required this.progress,
    required this.palette,
    required this.dark,
  });

  final int stones;
  final double progress;
  final List<Color> palette;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final ghost = progress > 0.02 ? 1 : 0;
    final visual = stones + ghost;
    if (visual == 0) return;

    // Hauteur de pierre calée pour tenir dans le budget vertical, chevauchement
    // léger pour l'effet « empilé ».
    const overlap = 0.78;
    final groundY = size.height - 8;
    final budget = size.height - 18;
    var stoneH = budget / (visual * overlap + (1 - overlap));
    stoneH = stoneH.clamp(12.0, 30.0);
    final step = stoneH * overlap;

    final maxW = size.width * 0.92;
    final cx = size.width / 2;

    // Ombre douce au sol.
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, groundY + 2), width: maxW * 0.9, height: stoneH * 0.6),
      Paint()
        ..color = Colors.black.withValues(alpha: dark ? 0.35 : 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // De la base vers le sommet.
    for (var i = 0; i < visual; i++) {
      final isGhost = i >= stones;
      final t = visual <= 1 ? 0.0 : i / (visual - 1); // 0 base → 1 sommet
      final taper = 1 - 0.52 * _easeOut(t);
      final wobble = 1 + 0.05 * math.sin(i * 1.9 + 0.7);
      final w = maxW * taper * wobble;
      final h = stoneH * (0.90 + 0.16 * _noise(i * 0.37 + 3));

      final dx = maxW * 0.06 * math.sin(i * 1.7 + 0.3);
      final centerY = groundY - stoneH * 0.5 - i * step;
      final angle = 0.06 * math.sin(i * 2.7 + 1.1);

      final baseColor = palette[i % palette.length];
      final path = _pebble(w, h, i);

      canvas.save();
      canvas.translate(cx + dx, centerY);
      canvas.rotate(angle);

      if (isGhost) {
        // Pierre en formation : discrète, opacité = progression.
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = baseColor.withValues(alpha: 0.25 + 0.45 * progress),
        );
      } else {
        // Ombre portée.
        canvas.save();
        canvas.translate(0, 2.5);
        canvas.drawPath(
          path,
          Paint()
            ..color = Colors.black.withValues(alpha: dark ? 0.32 : 0.20)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
        );
        canvas.restore();

        // Corps : dégradé vertical (clair en haut, sombre en bas) → volume.
        final rect = Rect.fromCenter(
            center: Offset.zero, width: w, height: h);
        canvas.drawPath(
          path,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _shift(baseColor, dark ? 0.17 : 0.15),
                _shift(baseColor, dark ? -0.15 : -0.13),
              ],
            ).createShader(rect),
        );

        // Filet de lumière au sommet (clippé à la pierre).
        canvas.save();
        canvas.clipPath(path);
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(-w * 0.06, -h * 0.32),
              width: w * 0.7,
              height: h * 0.5),
          Paint()
            ..color = Colors.white.withValues(alpha: dark ? 0.06 : 0.13)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
        canvas.restore();
      }
      canvas.restore();
    }
  }

  /// Galet organique : un blob fermé lissé passant par des points répartis sur
  /// une ellipse, avec un rayon légèrement bruité (déterministe via [seed]).
  Path _pebble(double w, double h, int seed) {
    const n = 11;
    final rx = w / 2, ry = h / 2;
    final pts = <Offset>[];
    for (var k = 0; k < n; k++) {
      final a = 2 * math.pi * k / n;
      final jitter = 0.85 + 0.22 * _noise(seed * 12.9 + k * 3.1);
      pts.add(Offset(rx * math.cos(a) * jitter, ry * math.sin(a) * jitter));
    }
    // Lissage : courbes quadratiques passant par les milieux, points de
    // contrôle = les sommets bruités → contour doux et fermé.
    final path = Path();
    Offset mid(Offset a, Offset b) => (a + b) / 2;
    final start = mid(pts[n - 1], pts[0]);
    path.moveTo(start.dx, start.dy);
    for (var k = 0; k < n; k++) {
      final cur = pts[k];
      final nextMid = mid(pts[k], pts[(k + 1) % n]);
      path.quadraticBezierTo(cur.dx, cur.dy, nextMid.dx, nextMid.dy);
    }
    path.close();
    return path;
  }

  double _easeOut(double t) => 1 - math.pow(1 - t, 2).toDouble();

  /// Bruit pseudo-aléatoire déterministe 0..1.
  double _noise(double x) {
    final s = math.sin(x * 91.7 + 0.13) * 43758.5453;
    return s - s.floorToDouble();
  }

  /// Éclaircit ([amount]>0) ou assombrit ([amount]<0) une couleur.
  Color _shift(Color base, double amount) => amount >= 0
      ? Color.lerp(base, Colors.white, amount)!
      : Color.lerp(base, Colors.black, -amount)!;

  @override
  bool shouldRepaint(_CairnPainter old) =>
      old.stones != stones || old.progress != progress || old.dark != dark;
}
