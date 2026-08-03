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
    // léger (0.80) pour l'effet « empilé ».
    const overlap = 0.80;
    final groundY = size.height - 8;
    final budget = size.height - 18;
    var stoneH = budget / (visual * overlap + (1 - overlap));
    stoneH = stoneH.clamp(10.0, 26.0);
    final step = stoneH * overlap;

    final maxW = size.width * 0.92;
    final cx = size.width / 2;

    // Ombre douce au sol.
    final groundPaint = Paint()
      ..color = Colors.black.withValues(alpha: dark ? 0.35 : 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, groundY + 2), width: maxW * 0.9, height: stoneH * 0.7),
      groundPaint,
    );

    // De la base vers le sommet.
    for (var i = 0; i < visual; i++) {
      final isGhost = i >= stones;
      final t = visual <= 1 ? 0.0 : i / (visual - 1); // 0 base → 1 sommet
      // Largeur : rétrécit en montant, avec une petite variation organique.
      final taper = 1 - 0.52 * _easeOut(t);
      final wobble = 1 + 0.05 * math.sin(i * 1.9 + 0.7);
      final w = maxW * taper * wobble;
      final h = stoneH * (0.92 + 0.12 * _frac(i * 0.37));

      final dx = maxW * 0.055 * math.sin(i * 1.7 + 0.3);
      final centerY = groundY - stoneH * 0.5 - i * step;
      final angle = 0.05 * math.sin(i * 2.7 + 1.1);

      final baseColor = palette[i % palette.length];
      canvas.save();
      canvas.translate(cx + dx, centerY);
      canvas.rotate(angle);

      final rect = Rect.fromCenter(center: Offset.zero, width: w, height: h);
      final rr = RRect.fromRectAndRadius(rect, Radius.circular(h * 0.46));

      if (isGhost) {
        // Pierre en formation : discrète, opacité = progression.
        final gp = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = baseColor.withValues(alpha: 0.25 + 0.45 * progress);
        canvas.drawRRect(rr, gp);
      } else {
        // Ombre portée de la pierre.
        canvas.drawRRect(
          rr.shift(const Offset(0, 2)),
          Paint()
            ..color = Colors.black.withValues(alpha: dark ? 0.30 : 0.18)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
        // Corps : dégradé vertical (clair en haut, sombre en bas) → volume.
        final fill = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _shift(baseColor, dark ? 0.16 : 0.14),
              _shift(baseColor, dark ? -0.14 : -0.12),
            ],
          ).createShader(rect);
        canvas.drawRRect(rr, fill);
        // Filet de lumière au sommet.
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(0, -h * 0.16), width: w * 0.82, height: h * 0.5),
            Radius.circular(h * 0.4),
          ),
          Paint()..color = Colors.white.withValues(alpha: dark ? 0.05 : 0.10),
        );
      }
      canvas.restore();
    }
  }

  double _easeOut(double t) => 1 - math.pow(1 - t, 2).toDouble();
  double _frac(double x) => x - x.floorToDouble();

  /// Éclaircit ([amount]>0) ou assombrit ([amount]<0) une couleur.
  Color _shift(Color base, double amount) => amount >= 0
      ? Color.lerp(base, Colors.white, amount)!
      : Color.lerp(base, Colors.black, -amount)!;

  @override
  bool shouldRepaint(_CairnPainter old) =>
      old.stones != stones ||
      old.progress != progress ||
      old.dark != dark;
}
