import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/time/format.dart';
import '../../data/cigarette_repository.dart';
import '../tap/tap_stone.dart';

/// Mode arrêt net (Jalon 6 : squelette). Le streak — temps depuis la dernière —
/// est mis en avant en lagon (l'app salue un progrès). Le compteur cumulé, le
/// record et la rechute arrivent au Jalon 8.
class ColdTurkeyHome extends ConsumerStatefulWidget {
  const ColdTurkeyHome({super.key});

  @override
  ConsumerState<ColdTurkeyHome> createState() => _ColdTurkeyHomeState();
}

class _ColdTurkeyHomeState extends ConsumerState<ColdTurkeyHome> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _onTap() async {
    // Silencieux : tap = j'ai fumé. Le streak repart de zéro, sans commentaire.
    unawaited(HapticFeedback.mediumImpact());
    await ref.read(cigaretteRepositoryProvider).logSmoke();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final last = ref.watch(lastCigaretteProvider).asData?.value;
    final streak = last == null
        ? Duration.zero
        : DateTime.now().difference(last.occurredAtUtc.toLocal());

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatStreak(streak),
                style: theme.textTheme.displaySmall?.copyWith(
                  color: c.primary, // lagon — l'app salue le progrès
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'sans fumer',
                style: TextStyle(color: c.onSurface.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 36),
              TapStone(
                onTap: _onTap,
                child: Text('✦',
                    style: TextStyle(
                        fontSize: 40,
                        color: c.onSurface.withValues(alpha: 0.5))),
              ),
              const SizedBox(height: 18),
              Text(
                'tape si tu as fumé',
                style: TextStyle(
                    fontSize: 12.5, color: c.onSurface.withValues(alpha: 0.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
