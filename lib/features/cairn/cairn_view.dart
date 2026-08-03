import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/cairn_theme.dart';

/// Teinte hibiscus, réservée au Boss (seul écart chaud autorisé par le design).
const _hibiscus = Color(0xFFCB5A38);
const _hibiscusNight = Color(0xFFE07050);

/// Le cairn dessiné : des pierres empilées qui montent avec la progression.
/// [stones] = pierres pleines (fondation comprise) ; [progress] (0..1) fait
/// apparaître une pierre « en formation » au sommet, vers le prochain palier ;
/// [bossRocks] = gros rochers hibiscus hissés au sommet (Boss vaincus).
///
/// Rendu **stable** entre deux reconstructions (les variations organiques sont
/// dérivées de l'index de la pierre, pas d'un aléatoire).
class CairnView extends StatelessWidget {
  const CairnView({
    super.key,
    required this.stones,
    this.progress = 0,
    this.bossRocks = 0,
    this.width = 190,
    this.height = 210,
  });

  final int stones;
  final double progress;
  final int bossRocks;
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
          bossRocks: bossRocks.clamp(0, 8),
          palette: palette,
          boss: dark ? _hibiscusNight : _hibiscus,
          dark: dark,
        ),
      ),
    );
  }
}

// Types d'unités empilées, de la base au sommet.
const int _kStone = 0;
const int _kGhost = 1;
const int _kBoss = 2;

class _CairnPainter extends CustomPainter {
  _CairnPainter({
    required this.stones,
    required this.progress,
    required this.bossRocks,
    required this.palette,
    required this.boss,
    required this.dark,
  });

  final int stones;
  final double progress;
  final int bossRocks;
  final List<Color> palette;
  final Color boss;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    // Composition de bas en haut : pierres, puis rochers de Boss au sommet ;
    // la pierre en formation n'apparaît que s'il n'y a pas de rocher à couronner.
    final types = <int>[
      for (var i = 0; i < stones; i++) _kStone,
      if (bossRocks > 0)
        for (var i = 0; i < bossRocks; i++) _kBoss
      else if (progress > 0.02)
        _kGhost,
    ];
    final n = types.length;
    if (n == 0) return;

    double weight(int t) => t == _kBoss ? 1.5 : 1.0;
    final totalWeight = types.fold<double>(0, (s, t) => s + weight(t));

    const overlap = 0.78;
    final groundY = size.height - 8;
    final budget = size.height - 18;
    final baseStep = (budget / totalWeight).clamp(9.0, 24.0);

    final maxW = size.width * 0.92;
    final cx = size.width / 2;

    // Ombre douce au sol.
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, groundY + 2),
          width: maxW * 0.9,
          height: baseStep * 0.6),
      Paint()
        ..color = Colors.black.withValues(alpha: dark ? 0.35 : 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    var acc = 0.0; // hauteur cumulée depuis le sol
    for (var i = 0; i < n; i++) {
      final type = types[i];
      final wgt = weight(type);
      final sh = baseStep * wgt; // hauteur de la pierre
      final centerY = groundY - acc - sh / 2;
      acc += sh * overlap;

      final t = n <= 1 ? 0.0 : i / (n - 1);
      final taper = 1 - 0.52 * _easeOut(t);
      final wobble = 1 + 0.05 * math.sin(i * 1.9 + 0.7);
      var w = maxW * taper * wobble;
      if (type == _kBoss) w = math.max(w, maxW * 0.62); // le rocher est imposant

      final dx = maxW * 0.06 * math.sin(i * 1.7 + 0.3);
      final angle = 0.06 * math.sin(i * 2.7 + 1.1);
      final path = _pebble(w, sh, i);

      canvas.save();
      canvas.translate(cx + dx, centerY);
      canvas.rotate(angle);

      if (type == _kGhost) {
        final base = palette[i % palette.length];
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = base.withValues(alpha: 0.25 + 0.45 * progress),
        );
      } else {
        final base = type == _kBoss ? boss : palette[i % palette.length];
        _drawStone(canvas, path, Rect.fromCenter(
            center: Offset.zero, width: w, height: sh), base, boss: type == _kBoss);
      }
      canvas.restore();
    }
  }

  void _drawStone(Canvas canvas, Path path, Rect rect, Color base,
      {required bool boss}) {
    // Ombre portée.
    canvas.save();
    canvas.translate(0, boss ? 3 : 2.5);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: dark ? 0.34 : 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
    );
    canvas.restore();

    // Corps dégradé.
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _shift(base, dark ? 0.17 : 0.15),
            _shift(base, dark ? -0.15 : -0.13),
          ],
        ).createShader(rect),
    );

    // Filet de lumière au sommet (clippé).
    canvas.save();
    canvas.clipPath(path);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(-rect.width * 0.06, -rect.height * 0.32),
          width: rect.width * 0.7,
          height: rect.height * 0.5),
      Paint()
        ..color = Colors.white.withValues(alpha: dark ? 0.06 : 0.13)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.restore();

    // Un rocher de Boss porte un liseré discret pour se distinguer.
    if (boss) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = _shift(base, -0.2).withValues(alpha: 0.6),
      );
    }
  }

  /// Galet organique : blob fermé lissé passant par des points bruités.
  Path _pebble(double w, double h, int seed) {
    const n = 11;
    final rx = w / 2, ry = h / 2;
    final pts = <Offset>[];
    for (var k = 0; k < n; k++) {
      final a = 2 * math.pi * k / n;
      final jitter = 0.85 + 0.22 * _noise(seed * 12.9 + k * 3.1);
      pts.add(Offset(rx * math.cos(a) * jitter, ry * math.sin(a) * jitter));
    }
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

  double _noise(double x) {
    final s = math.sin(x * 91.7 + 0.13) * 43758.5453;
    return s - s.floorToDouble();
  }

  Color _shift(Color base, double amount) => amount >= 0
      ? Color.lerp(base, Colors.white, amount)!
      : Color.lerp(base, Colors.black, -amount)!;

  @override
  bool shouldRepaint(_CairnPainter old) =>
      old.stones != stones ||
      old.progress != progress ||
      old.bossRocks != bossRocks ||
      old.dark != dark;
}
