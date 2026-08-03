import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/cairn_theme.dart';

/// Teinte hibiscus, réservée au Boss (seul écart chaud autorisé par le design).
const _hibiscus = Color(0xFFCB5A38);
const _hibiscusNight = Color(0xFFE07050);

/// Le cairn dessiné : des pierres empilées qui montent avec la progression.
/// [stones] = pierres pleines (fondation comprise) ; [progress] (0..1) fait
/// apparaître une pierre « en formation » au sommet, vers le prochain palier ;
/// [bossRocks] = gros rochers hibiscus hissés au sommet (Boss vaincus).
///
/// Quand [stones] ou [bossRocks] **augmente**, la nouvelle pierre **tombe et se
/// pose** (chute + fondu + léger rebond). Le reste du rendu est stable (les
/// variations organiques sont dérivées de l'index, pas d'un aléatoire).
class CairnView extends StatefulWidget {
  const CairnView({
    super.key,
    required this.stones,
    this.progress = 0,
    this.bossRocks = 0,
    this.haptics = true,
    this.width = 190,
    this.height = 210,
  });

  final int stones;
  final double progress;
  final int bossRocks;

  /// Retour haptique au calage d'une pierre. Coupé en observation (silence).
  final bool haptics;

  final double width;
  final double height;

  @override
  State<CairnView> createState() => _CairnViewState();
}

class _CairnViewState extends State<CairnView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
    value: 1, // au montage, tout est déjà posé (pas d'animation d'entrée)
  );

  // Index (dans la pile de bas en haut) de l'unité qui se pose, -1 si aucune.
  int _animIndex = -1;

  @override
  void didUpdateWidget(CairnView old) {
    super.didUpdateWidget(old);
    if (widget.bossRocks > old.bossRocks) {
      _animIndex = widget.stones + widget.bossRocks - 1; // le rocher du sommet
      _ctrl.forward(from: 0);
      // Pas d'haptique ici : le rocher de Boss est déjà accompagné d'un buzz
      // par son reveal de victoire (éviter le double).
    } else if (widget.stones > old.stones) {
      _animIndex = widget.stones - 1; // la nouvelle pierre du sommet
      _ctrl.forward(from: 0);
      _hapticOnLanding();
    }
  }

  /// Petit « tac » au moment où la pierre se cale (≈ fin de la chute).
  void _hapticOnLanding() {
    if (!widget.haptics) return;
    Future.delayed(const Duration(milliseconds: 320), () {
      if (mounted) HapticFeedback.lightImpact();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

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
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) => CustomPaint(
          painter: _CairnPainter(
            stones: widget.stones.clamp(0, 40),
            progress: widget.progress.clamp(0.0, 1.0),
            bossRocks: widget.bossRocks.clamp(0, 8),
            palette: palette,
            boss: dark ? _hibiscusNight : _hibiscus,
            dark: dark,
            entranceT: _ctrl.value,
            animIndex: _ctrl.isAnimating ? _animIndex : -1,
          ),
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
    required this.entranceT,
    required this.animIndex,
  });

  final int stones;
  final double progress;
  final int bossRocks;
  final List<Color> palette;
  final Color boss;
  final bool dark;

  /// Progression (0..1) de la pierre qui se pose.
  final double entranceT;

  /// Index de l'unité en train de se poser (-1 = aucune).
  final int animIndex;

  @override
  void paint(Canvas canvas, Size size) {
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

    var acc = 0.0;
    for (var i = 0; i < n; i++) {
      final type = types[i];
      final wgt = weight(type);
      final sh = baseStep * wgt;
      final centerY = groundY - acc - sh / 2;
      acc += sh * overlap;

      final t = n <= 1 ? 0.0 : i / (n - 1);
      final taper = 1 - 0.52 * _easeOut(t);
      final wobble = 1 + 0.05 * math.sin(i * 1.9 + 0.7);
      var w = maxW * taper * wobble;
      if (type == _kBoss) w = math.max(w, maxW * 0.62);

      final dx = maxW * 0.06 * math.sin(i * 1.7 + 0.3);
      final angle = 0.06 * math.sin(i * 2.7 + 1.1);
      final path = _pebble(w, sh, i);

      // Entrée de l'unité : une pierre **tombe d'en haut**, un rocher de Boss
      // est **hissé depuis le bas** (l'effort qu'on fournit pour le monter).
      final landing = i == animIndex && entranceT < 1;
      double drop = 0;
      if (landing) {
        final over = 1 - _easeOutBack(entranceT); // ~1 → 0 (avec léger dépassement)
        drop = type == _kBoss ? over * sh * 3.0 : -over * sh * 2.2;
      }
      final fade = landing ? _easeOut(entranceT).clamp(0.0, 1.0) : 1.0;

      canvas.save();
      canvas.translate(cx + dx, centerY + drop);
      canvas.rotate(angle);

      final needsLayer = landing && fade < 1;
      if (needsLayer) {
        canvas.saveLayer(
          Rect.fromCenter(center: Offset.zero, width: w * 1.6, height: sh * 3),
          Paint()..color = Colors.white.withValues(alpha: fade),
        );
      }

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
        _drawStone(
          canvas,
          path,
          Rect.fromCenter(center: Offset.zero, width: w, height: sh),
          base,
          boss: type == _kBoss,
        );
      }

      if (needsLayer) canvas.restore();
      canvas.restore();

      // Poussière à l'impact : seulement pour une pierre qui tombe (pas le
      // rocher hissé), dans la 2ᵉ moitié de la chute, à la base au repos.
      if (type == _kStone && i == animIndex && entranceT > 0.5 && entranceT < 1) {
        final dustT = ((entranceT - 0.5) / 0.5).clamp(0.0, 1.0);
        _drawDust(canvas, Offset(cx + dx, centerY + sh / 2), w, sh, dustT, i);
      }
    }
  }

  /// Petit nuage de poussière qui s'écarte et retombe au calage d'une pierre.
  void _drawDust(
      Canvas canvas, Offset base, double w, double sh, double t, int seed) {
    final spread = w * (0.30 + 0.65 * t);
    final rise = sh * 0.6 * t;
    final baseAlpha = (1 - t) * (dark ? 0.34 : 0.42);
    final dust = dark ? const Color(0xFF8E887E) : const Color(0xFFBFA271);
    const nP = 8;
    for (var k = 0; k < nP; k++) {
      final f = k / (nP - 1);
      final side = (f - 0.5) * 2; // -1 .. 1
      final jr = _noise(seed * 7.3 + k * 5.1);
      final px = base.dx + side * spread * (0.6 + 0.5 * jr);
      final py = base.dy - rise * (0.3 + 0.7 * _noise(seed * 3.7 + k)) - sh * 0.05;
      final r = (1 - t) * sh * 0.24 * (0.55 + 0.7 * jr);
      if (r <= 0.2) continue;
      canvas.drawCircle(
        Offset(px, py),
        r,
        Paint()
          ..color = dust.withValues(
              alpha: (baseAlpha * (0.6 + 0.6 * jr)).clamp(0.0, 1.0)),
      );
    }
  }

  void _drawStone(Canvas canvas, Path path, Rect rect, Color base,
      {required bool boss}) {
    canvas.save();
    canvas.translate(0, boss ? 3 : 2.5);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: dark ? 0.34 : 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
    );
    canvas.restore();

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

  /// easeOutBack : léger dépassement à l'atterrissage (petit rebond).
  double _easeOutBack(double t) {
    const c1 = 1.70158;
    const c3 = c1 + 1;
    final x = t - 1;
    return 1 + c3 * x * x * x + c1 * x * x;
  }

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
      old.dark != dark ||
      old.entranceT != entranceT ||
      old.animIndex != animIndex;
}
