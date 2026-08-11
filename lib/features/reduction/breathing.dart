import 'package:flutter/material.dart';

/// Durée d'un cycle : **4 s d'inspiration, 6 s d'expiration**.
///
/// Pas de 4-7-8 : la rétention de 7 s ne se transmet pas sans consigne écrite,
/// et l'app ne parle pas. Une expiration plus longue que l'inspiration suffit à
/// faire redescendre le rythme cardiaque, et se suit d'un simple coup d'œil.
const _inhale = Duration(seconds: 4);
const _exhale = Duration(seconds: 6);

/// Le galet **respire** pendant qu'un délai tourne : il enfle lentement, puis
/// redescend. Aucun texte, aucune consigne, aucun son — on peut le suivre ou
/// l'ignorer complètement.
///
/// Rien n'est proposé : c'est l'utilisateur qui a lancé le délai, l'app se
/// contente de lui donner quelque chose à faire de ces dix minutes au lieu de
/// regarder un compte à rebours.
class Breathing extends StatefulWidget {
  const Breathing({super.key, required this.active, required this.child});

  /// Anime seulement quand un délai est en cours.
  final bool active;
  final Widget child;

  @override
  State<Breathing> createState() => _BreathingState();
}

class _BreathingState extends State<Breathing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: _inhale + _exhale,
  );

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: 1.05)
          .chain(CurveTween(curve: Curves.easeInOutSine)),
      weight: _inhale.inMilliseconds.toDouble(),
    ),
    TweenSequenceItem(
      tween: Tween(begin: 1.05, end: 1.0)
          .chain(CurveTween(curve: Curves.easeInOutSine)),
      weight: _exhale.inMilliseconds.toDouble(),
    ),
  ]).animate(_c);

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(Breathing old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) _sync();
  }

  void _sync() {
    if (widget.active) {
      _c.repeat();
    } else {
      _c
        ..stop()
        ..value = 0; // on revient au repos, sans à-coup visible
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // « Réduire les animations » (réglage système) : on ne bouge plus rien.
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}
