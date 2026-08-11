import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/notification_service.dart';
import '../../core/time/format.dart';
import '../../data/cigarette_repository.dart';
import '../../data/journey_repository.dart';
import '../../domain/boss/boss.dart';
import '../../domain/boss/victory.dart';
import '../../domain/journey/delay.dart';
import '../boss/boss_face.dart';
import '../cairn/cairn_view.dart';
import '../tap/tap_stone.dart';
import '../tap/corrections_row.dart';

/// Mode réduction — **combat de Boss (spec §15)**. On attaque le plus fragile ;
/// chaque **délai de 10 min tenu** lui enlève 1 PV (+ une pierre), chaque
/// **cigarette lui en redonne 1** (silencieux). Délais **relançables** (plus de
/// « 1/jour »). Le Boss tombe quand ses PV atteignent 0. Le cairn ne recule jamais.
class ReductionHome extends ConsumerStatefulWidget {
  const ReductionHome({super.key});

  @override
  ConsumerState<ReductionHome> createState() => _ReductionHomeState();
}

class _ReductionHomeState extends ConsumerState<ReductionHome> {
  Timer? _ticker;
  bool _finalizing = false;
  bool _bonusInFlight = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _maybeFinalize();
      _maybeBonus();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// Quand le délai s'est écoulé sans rupture, on l'enregistre comme tenu (une
  /// pierre). Les dégâts au Boss (v2) sont dérivés de l'horodatage (jour + heure).
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

  /// Tenir au-delà des 10 min sans fumer → pierres bonus (20 min, 30 min).
  void _maybeBonus() {
    if (_bonusInFlight) return;
    final events = ref.read(journeyEventsProvider).asData?.value ?? const [];
    final cigs = ref.read(allCigarettesProvider).asData?.value ?? const [];
    final n = pendingBonusStones(events, cigs, DateTime.now());
    if (n <= 0) return;
    _bonusInFlight = true;
    unawaited(HapticFeedback.selectionClick());
    ref
        .read(journeyRepositoryProvider)
        .markBonusStones(n)
        .whenComplete(() => _bonusInFlight = false);
  }

  /// « Je fume » : on enregistre. Le Boss se resoigne (dérivé de l'horodatage,
  /// v2), en silence. Si un délai tournait, on l'annule. Aucune consolation.
  Future<void> _onTapStone(DelayStatus status) async {
    unawaited(HapticFeedback.mediumImpact());
    final running = status == DelayStatus.running;
    await ref
        .read(cigaretteRepositoryProvider)
        .logSmoke(wasBoss: true, duringDelay: running);
    if (running) {
      await ref.read(notificationServiceProvider).cancelDelayEnd();
    }
    await ref.read(journeyRepositoryProvider).markDelayBroken();
  }

  /// Lance le délai du jour et planifie le rappel de fin à T+10.
  Future<void> _startDelay() async {
    unawaited(HapticFeedback.selectionClick());
    await ref.read(journeyRepositoryProvider).startDelay();
    final report = ref.read(bossReportProvider);
    final events = ref.read(journeyEventsProvider).asData?.value ?? const [];
    final cigs = ref.read(allCigarettesProvider).asData?.value ?? const [];
    final target = nextTarget(report, defeatedBossKeys(report, cigs, events));
    final bossName = target?.name ?? 'le Boss';
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

    final todays = ref.watch(todaysCigarettesProvider).asData?.value ?? const [];
    final last = ref.watch(lastCigaretteProvider).asData?.value;
    final events = ref.watch(journeyEventsProvider).asData?.value ?? const [];
    final cigs = ref.watch(allCigarettesProvider).asData?.value ?? const [];

    final report = ref.watch(bossReportProvider);
    final defeated = defeatedBossKeys(report, cigs, events);
    // La cible = le Boss le plus fragile pas encore vaincu.
    final target = nextTarget(report, defeated);
    final delay = resolveDelay(events, now);
    final stones = stonesPlaced(events);
    final since = last == null
        ? Duration.zero
        : now.difference(last.occurredAtUtc.toLocal());

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Laisse passer la rangée d'icônes flottantes (stats / règle /
            // sauvegarde) en haut, pour que le bandeau du Boss ne soit pas recouvert.
            const SizedBox(height: 52),
            if (target != null)
              _TargetBanner(
                boss: target,
                hp: bossHp(target, cigs, events),
                maxHp: bossMaxHp(target),
                engagedToday: engagedToday(target, events, now),
                inWindow: bossWindowContains(target, now),
              ),
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
                    // Un mis-tap coûte cher ici : la cigarette resoigne le Boss
                    // (+1 PV). Il manquait la même sortie qu'en observation.
                    const SizedBox(height: 2),
                    const CorrectionsRow(),
                  ],
                ),
              ),
            ),
            _StonesFooter(count: stones, bossRocks: defeated.length),
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

    // Quand un délai tourne, le compte à rebours passe devant (c'est le moment
    // actif) — mais le chrono « depuis la dernière » reste toujours affiché.
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
          const SizedBox(height: 8),
          Text(
            '${formatSinceLast(since)} · depuis la dernière',
            style: TextStyle(
                fontSize: 12,
                color: c.onSurface.withValues(alpha: 0.5),
                fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      );
    }

    // Tous les autres états : le chrono « depuis la dernière » est le timer
    // persistant (toujours là après un tap). Un liseré « pierre posée » si tenu.
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
        if (delay.status == DelayStatus.held) ...[
          const SizedBox(height: 6),
          Text('délai tenu · pierre posée',
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: c.primary)),
        ],
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

class _TargetBanner extends StatefulWidget {
  const _TargetBanner(
      {required this.boss,
      required this.hp,
      required this.maxHp,
      this.engagedToday = false,
      this.inWindow = false});
  final Boss boss;
  final int hp;
  final int maxHp;
  final bool engagedToday;

  /// L'heure courante tombe dans la fenêtre du Boss (± 30 min).
  final bool inWindow;

  @override
  State<_TargetBanner> createState() => _TargetBannerState();
}

class _TargetBannerState extends State<_TargetBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..addListener(() => setState(() {}));

  // On ne pulse que si on est en pleine fenêtre ET qu'il reste à faire
  // aujourd'hui (déjà entamé → rien à signaler, on attend demain).
  bool get _shouldPulse => widget.inWindow && !widget.engagedToday;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_TargetBanner old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (_shouldPulse) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else if (_pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final hibiscus = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFE07050)
        : const Color(0xFFCB5A38);
    // t oscille 0→1 quand on pulse, sinon 0 (état de repos).
    final t = _shouldPulse ? Curves.easeInOut.transform(_pulse.value) : 0.0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.fromLTRB(14, 10, 16, 10),
      decoration: BoxDecoration(
        color: hibiscus.withValues(alpha: 0.10 + 0.10 * t),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hibiscus.withValues(alpha: 0.35 + 0.55 * t),
          width: 1 + t,
        ),
        boxShadow: [
          if (t > 0)
            BoxShadow(
              color: hibiscus.withValues(alpha: 0.30 * t),
              blurRadius: 16 * t,
              spreadRadius: 1 * t,
            ),
        ],
      ),
      child: Row(
        children: [
          const BossFace(size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('TON ADVERSAIRE',
                    style: TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w700,
                        color: hibiscus)),
                const SizedBox(height: 2),
                Text(widget.boss.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    BossHpBar(hp: widget.hp, maxHp: widget.maxHp),
                    const SizedBox(width: 8),
                    Text('${widget.hp}/${widget.maxHp} PV',
                        style: TextStyle(
                            fontSize: 11,
                            color: c.onSurface.withValues(alpha: 0.5))),
                  ],
                ),
                if (widget.engagedToday) ...[
                  const SizedBox(height: 4),
                  Text('entamé aujourd’hui ✓ — reviens demain',
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: hibiscus)),
                ] else if (widget.inWindow) ...[
                  const SizedBox(height: 4),
                  Text('c’est le moment — retarde-le',
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: hibiscus)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Le cairn qui monte : une pierre par délai tenu.
class _StonesFooter extends StatelessWidget {
  const _StonesFooter({required this.count, this.bossRocks = 0});
  final int count;
  final int bossRocks;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (count > 0 || bossRocks > 0)
          CairnView(
              stones: count, bossRocks: bossRocks, width: 150, height: 132)
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
