import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/notification_service.dart';
import '../../core/time/format.dart';
import '../../data/cigarette_repository.dart';
import '../../data/journey_repository.dart';
import '../../domain/journey/delay.dart';
import '../cairn/cairn_view.dart';
import '../tap/tap_stone.dart';

/// Mode réduction. On annonce la première cible (le Boss le plus fragile) et on
/// propose **un seul délai de 10 min par jour** dessus. Tenu = une pierre posée
/// (1ᵉʳ badge au 1ᵉʳ tenu). Rompu = validation silencieuse. Le reste du temps,
/// l'app se tait.
class ReductionHome extends ConsumerStatefulWidget {
  const ReductionHome({super.key});

  @override
  ConsumerState<ReductionHome> createState() => _ReductionHomeState();
}

class _ReductionHomeState extends ConsumerState<ReductionHome> {
  Timer? _ticker;
  bool _finalizing = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _maybeFinalize();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// Quand le délai s'est écoulé sans rupture, on l'enregistre comme tenu.
  void _maybeFinalize() {
    final events = ref.read(journeyEventsProvider).asData?.value ?? const [];
    final st = resolveDelay(events, DateTime.now());
    if (st.status == DelayStatus.elapsed && !_finalizing) {
      _finalizing = true;
      ref
          .read(journeyRepositoryProvider)
          .markDelayHeld()
          .whenComplete(() => _finalizing = false);
    }
  }

  Future<void> _onTapStone(DelayStatus status) async {
    unawaited(HapticFeedback.mediumImpact());
    final repo = ref.read(cigaretteRepositoryProvider);
    if (status == DelayStatus.running) {
      // « Je fume quand même » : on enregistre, on romp le délai, on annule le
      // rappel. Rien d'autre — aucune consolation.
      await repo.logSmoke(wasBoss: true, duringDelay: true);
      await ref.read(journeyRepositoryProvider).markDelayBroken();
      await ref.read(notificationServiceProvider).cancelDelayEnd();
    } else {
      await repo.logSmoke();
    }
  }

  /// Lance le délai du jour et planifie le rappel de fin à T+10.
  Future<void> _startDelay() async {
    unawaited(HapticFeedback.selectionClick());
    await ref.read(journeyRepositoryProvider).startDelay();
    final bossName = ref.read(bossReportProvider).easiestTarget?.name ?? 'le Boss';
    await ref.read(notificationServiceProvider).scheduleDelayEnd(
          DateTime.now().add(kDelayLength),
          bossName: bossName,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final now = DateTime.now();

    final target = ref.watch(bossReportProvider).easiestTarget;
    final todays = ref.watch(todaysCigarettesProvider).asData?.value ?? const [];
    final last = ref.watch(lastCigaretteProvider).asData?.value;
    final events = ref.watch(journeyEventsProvider).asData?.value ?? const [];

    final delay = resolveDelay(events, now);
    final stones = stonesPlaced(events);
    final since = last == null
        ? Duration.zero
        : now.difference(last.occurredAtUtc.toLocal());

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
                    _Header(delay: delay, since: since, now: now),
                    const SizedBox(height: 24),
                    TapStone(
                      onTap: () => _onTapStone(delay.status),
                      child: Text('✦',
                          style: TextStyle(
                              fontSize: 40,
                              color: c.onSurface.withValues(alpha: 0.5))),
                    ),
                    const SizedBox(height: 18),
                    _Action(
                      delay: delay,
                      todayCount: todays.length,
                      onStart: _startDelay,
                    ),
                  ],
                ),
              ),
            ),
            _StonesFooter(count: stones),
            const SizedBox(height: 22),
          ],
        ),
      ),
    );
  }
}

/// En-tête central : compte à rebours si un délai tourne, sinon chrono / succès.
class _Header extends StatelessWidget {
  const _Header({required this.delay, required this.since, required this.now});
  final DelayState delay;
  final Duration since;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;

    if (delay.status == DelayStatus.running) {
      final left = delay.endsAt!.difference(now);
      final clamped = left.isNegative ? Duration.zero : left;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _mmss(clamped),
            style: theme.textTheme.displaySmall?.copyWith(
                color: c.primary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text('tiens bon — le Boss peut attendre',
              style: TextStyle(
                  fontSize: 12.5, color: c.onSurface.withValues(alpha: 0.6))),
        ],
      );
    }

    if (delay.status == DelayStatus.held) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Pierre posée',
              style: theme.textTheme.displaySmall
                  ?.copyWith(color: c.primary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text('le Boss a tenu bon aujourd’hui',
              style: TextStyle(
                  fontSize: 12.5, color: c.onSurface.withValues(alpha: 0.6))),
        ],
      );
    }

    // available / broken / elapsed : chrono sobre.
    return Column(
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
                fontSize: 12, color: c.onSurface.withValues(alpha: 0.55))),
      ],
    );
  }

  static String _mmss(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}

/// Zone d'action sous le bouton : proposer le délai, ou l'info du jour.
class _Action extends StatelessWidget {
  const _Action({
    required this.delay,
    required this.todayCount,
    required this.onStart,
  });
  final DelayState delay;
  final int todayCount;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    switch (delay.status) {
      case DelayStatus.available:
        return OutlinedButton(
          onPressed: onStart,
          style: OutlinedButton.styleFrom(
            foregroundColor: c.primary,
            side: BorderSide(color: c.primary.withValues(alpha: 0.6)),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13)),
          ),
          child: const Text('Retarde de 10 min'),
        );
      case DelayStatus.running:
        return Text('tape seulement si tu craques',
            style: TextStyle(
                fontSize: 12.5, color: c.onSurface.withValues(alpha: 0.5)));
      case DelayStatus.held:
      case DelayStatus.broken:
      case DelayStatus.elapsed:
        return Text('$todayCount aujourd’hui',
            style: TextStyle(color: c.onSurface.withValues(alpha: 0.6)));
    }
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

/// Le cairn qui monte : une pierre par délai tenu.
class _StonesFooter extends StatelessWidget {
  const _StonesFooter({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (count > 0)
          CairnView(stones: count, width: 150, height: 118)
        else
          Icon(Icons.landscape_outlined,
              size: 22, color: c.onSurface.withValues(alpha: 0.4)),
        const SizedBox(height: 6),
        Text(
          count == 0
              ? 'aucune pierre encore'
              : '$count ${count == 1 ? 'pierre posée' : 'pierres posées'}',
          style: TextStyle(
              fontSize: 13, color: c.onSurface.withValues(alpha: 0.6)),
        ),
      ],
    );
  }
}
