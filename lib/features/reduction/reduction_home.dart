import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/time/format.dart';
import '../../data/cigarette_repository.dart';
import '../tap/tap_stone.dart';

/// Mode réduction (Jalon 6 : squelette). On annonce la première cible (le Boss
/// le plus fragile) et on garde le bouton. Le délai d'une fois/jour et le badge
/// arrivent au Jalon 7.
class ReductionHome extends ConsumerStatefulWidget {
  const ReductionHome({super.key});

  @override
  ConsumerState<ReductionHome> createState() => _ReductionHomeState();
}

class _ReductionHomeState extends ConsumerState<ReductionHome> {
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
    unawaited(HapticFeedback.mediumImpact());
    await ref.read(cigaretteRepositoryProvider).logSmoke();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final target = ref.watch(bossReportProvider).easiestTarget;
    final todays = ref.watch(todaysCigarettesProvider).asData?.value ?? const [];
    final last = ref.watch(lastCigaretteProvider).asData?.value;
    final since = last == null
        ? Duration.zero
        : DateTime.now().difference(last.occurredAtUtc.toLocal());

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            if (target != null) _TargetBanner(name: target.name),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatSinceLast(since),
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w300,
                        color: c.onSurface,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('depuis la dernière',
                        style: TextStyle(
                            fontSize: 12,
                            color: c.onSurface.withValues(alpha: 0.55))),
                    const SizedBox(height: 24),
                    TapStone(
                      onTap: _onTap,
                      child: Text('✦',
                          style: TextStyle(
                              fontSize: 40,
                              color: c.onSurface.withValues(alpha: 0.5))),
                    ),
                    const SizedBox(height: 18),
                    Text('${todays.length} aujourd’hui',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: c.onSurface.withValues(alpha: 0.6))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 26),
          ],
        ),
      ),
    );
  }
}

class _TargetBanner extends StatelessWidget {
  const _TargetBanner({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: c.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.secondary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PREMIÈRE CIBLE',
              style: TextStyle(
                  fontSize: 10.5,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                  color: c.secondary)),
          const SizedBox(height: 2),
          Text(name,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
