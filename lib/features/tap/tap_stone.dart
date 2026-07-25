import 'package:flutter/material.dart';

import '../../core/theme/cairn_theme.dart';

/// Le bouton central : un galet chauffé par le soleil. Appui franc (léger
/// enfoncement), aucune animation qui « commente ». Sobre par défaut.
class TapStone extends StatefulWidget {
  const TapStone({
    super.key,
    required this.onTap,
    this.child,
    this.diameter = 176,
  });

  final VoidCallback onTap;
  final Widget? child;
  final double diameter;

  @override
  State<TapStone> createState() => _TapStoneState();
}

class _TapStoneState extends State<TapStone> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final top = dark ? const Color(0xFF2C4B44) : const Color(0xFFFDF8EE);
    final bottom = dark ? const Color(0xFF16302B) : const Color(0xFFE7D3B2);
    final rim = (dark ? CairnColors.lagonNight : CairnColors.vert)
        .withValues(alpha: 0.22);

    return Semantics(
      button: true,
      label: 'Tape quand tu fumes',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 90),
          child: Container(
            width: widget.diameter,
            height: widget.diameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.24, -0.4),
                radius: 1.1,
                colors: [top, bottom],
                stops: const [0.0, 0.74],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? 0.45 : 0.28),
                  blurRadius: 26,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(widget.diameter * 0.075),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: rim, width: 1),
                ),
                child: Center(child: widget.child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
