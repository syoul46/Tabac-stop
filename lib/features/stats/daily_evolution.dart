import 'package:flutter/material.dart';

import '../../domain/metrics/daily.dart';

/// Courbe d'évolution : une barre par jour logique depuis le début, hauteur =
/// cigarettes du jour. Raconte la baisse (ou la stabilité) au fil du temps.
///
/// Si [baseline] (rythme d'avant, par jour) est fourni, une ligne pointillée le
/// matérialise : les barres qui passent dessous, c'est le terrain gagné. Le
/// dernier jour est **partiel** (il grandit encore), c'est normal.
class DailyEvolutionCurve extends StatelessWidget {
  const DailyEvolutionCurve({
    super.key,
    required this.days,
    this.baseline,
    this.trend,
  });

  final List<DailyCount> days;
  final double? baseline;

  /// Moyenne mobile 7 jours (même longueur que [days]), tracée en trait plein
  /// pour lire la tendance sous le bruit jour-à-jour. Null = pas de courbe.
  final List<double>? trend;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final color = c.tertiary;
    final labelColor = c.onSurface.withValues(alpha: 0.4);

    final maxCount = days.fold<int>(0, (m, d) => d.count > m ? d.count : m);
    // La ligne du rythme d'avant doit tenir dans le cadre → elle entre dans le
    // max. On ajoute une marge en haut, sinon quand le rythme d'avant égale le
    // plus haut jour, la ligne colle au bord supérieur et disparaît.
    final dataMax = maxCount.toDouble() > (baseline ?? 0)
        ? maxCount.toDouble()
        : (baseline ?? 0);
    final top = dataMax <= 0 ? 1.0 : dataMax * 1.15;

    const chartH = 66.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: chartH,
          child: Stack(
            children: [
              Positioned.fill(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final d in days)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 0.6),
                          child: FractionallySizedBox(
                            alignment: Alignment.bottomCenter,
                            heightFactor: d.count == 0
                                ? 0.02
                                : (0.06 + 0.94 * d.count / top),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: d.notLogged
                                    ? c.onSurface.withValues(alpha: 0.12)
                                    : color.withValues(
                                        alpha: d.count == 0 ? 0.14 : 0.72),
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(1.5)),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (baseline != null && baseline! > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: chartH * (baseline! / top),
                  child: SizedBox(
                    height: 1.4,
                    child: CustomPaint(
                      painter: _DashedLinePainter(
                          color: c.primary.withValues(alpha: 0.7)),
                    ),
                  ),
                ),
              if (trend != null && trend!.length == days.length && top > 0)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TrendLinePainter(
                      values: trend!,
                      top: top,
                      color: c.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Text(_fmt(days.first.day),
                style: TextStyle(fontSize: 9.5, color: labelColor)),
            const Spacer(),
            if (days.length > 1)
              Text(_fmt(days.last.day),
                  style: TextStyle(fontSize: 9.5, color: labelColor)),
          ],
        ),
      ],
    );
  }

  static String _fmt(DateTime d) => '${d.day}/${d.month}';
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4;
    const dash = 4.0;
    const gap = 3.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color;
}

/// Trace la moyenne mobile en trait plein, sur la même échelle que les barres
/// (ratio `valeur / top`), points aux centres de barre.
class _TrendLinePainter extends CustomPainter {
  const _TrendLinePainter({
    required this.values,
    required this.top,
    required this.color,
  });
  final List<double> values;
  final double top;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = (i + 0.5) / values.length * size.width;
      final y = size.height * (1 - (values[i] / top).clamp(0, 1));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrendLinePainter old) =>
      old.top != top || old.color != color || old.values != values;
}
