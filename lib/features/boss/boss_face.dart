import 'package:flutter/material.dart';

/// Teinte hibiscus, réservée au Boss.
const _hibiscus = Color(0xFFCB5A38);
const _hibiscusNight = Color(0xFFE07050);

Color _bossColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? _hibiscusNight : _hibiscus;

/// La « sale gueule » du Boss : un rocher grognon (minéral, hibiscus) — sourcils
/// froncés, petits yeux, rictus. Dessiné, pas d'emoji.
class BossFace extends StatelessWidget {
  const BossFace({super.key, this.size = 52});
  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return CustomPaint(
      size: Size.square(size),
      painter: _BossFacePainter(_bossColor(context), dark),
    );
  }
}

class _BossFacePainter extends CustomPainter {
  _BossFacePainter(this.color, this.dark);
  final Color color;
  final bool dark;

  Color _shade(double amount) => amount >= 0
      ? Color.lerp(color, Colors.white, amount)!
      : Color.lerp(color, Colors.black, -amount)!;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    // Corps du rocher : arrondi, un peu aplati en bas.
    final body = Rect.fromLTWH(s * 0.08, s * 0.12, s * 0.84, s * 0.80);
    final rr = RRect.fromRectAndCorners(
      body,
      topLeft: Radius.circular(s * 0.42),
      topRight: Radius.circular(s * 0.38),
      bottomLeft: Radius.circular(s * 0.30),
      bottomRight: Radius.circular(s * 0.34),
    );
    // ombre douce
    canvas.drawRRect(
      rr.shift(const Offset(0, 2)),
      Paint()
        ..color = Colors.black.withValues(alpha: dark ? 0.30 : 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    // corps dégradé
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_shade(0.16), _shade(-0.14)],
        ).createShader(body),
    );

    final ink = Paint()
      ..color = _shade(-0.5)
      ..strokeCap = StrokeCap.round;

    // Sourcils froncés (angle vers le centre-bas).
    final brow = Paint()
      ..color = _shade(-0.45)
      ..strokeWidth = s * 0.07
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(s * 0.26, s * 0.40), Offset(s * 0.45, s * 0.48), brow);
    canvas.drawLine(
        Offset(s * 0.74, s * 0.40), Offset(s * 0.55, s * 0.48), brow);

    // Yeux (petits, sous les sourcils).
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(s * 0.37, s * 0.58), width: s * 0.10, height: s * 0.13),
        ink);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(s * 0.63, s * 0.58), width: s * 0.10, height: s * 0.13),
        ink);

    // Rictus (bouche renfrognée : coins vers le bas).
    final mouth = Paint()
      ..style = PaintingStyle.stroke
      ..color = _shade(-0.45)
      ..strokeWidth = s * 0.055
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(s * 0.36, s * 0.80)
        ..quadraticBezierTo(s * 0.50, s * 0.71, s * 0.64, s * 0.80),
      mouth,
    );
  }

  @override
  bool shouldRepaint(_BossFacePainter old) =>
      old.color != color || old.dark != dark;
}

/// Barre de PV du Boss : une pastille par point de vie, remplies = PV restants.
class BossHpBar extends StatelessWidget {
  const BossHpBar({super.key, required this.hp, required this.maxHp});
  final int hp;
  final int maxHp;

  @override
  Widget build(BuildContext context) {
    final color = _bossColor(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < maxHp; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Container(
              width: 16,
              height: 7,
              decoration: BoxDecoration(
                color: i < hp ? color : color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
      ],
    );
  }
}
