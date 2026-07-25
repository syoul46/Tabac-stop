import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/time/format.dart';
import '../../data/cigarette_repository.dart';
import '../../data/journey_repository.dart';
import '../../domain/metrics/metrics.dart';
import '../../domain/models/enums.dart';

/// L'écran charnière. Après 72 h d'observation silencieuse, l'app parle pour la
/// première fois — et le lagon (accent primaire) fait ici ses débuts.
class RevealScreen extends ConsumerWidget {
  const RevealScreen({super.key});

  void _choose(WidgetRef ref, JourneyMode mode) =>
      ref.read(journeyRepositoryProvider).setMode(mode);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final m = ref.watch(metricsProvider);
    final boss = ref.watch(bossReportProvider).mostAnchored;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VOILÀ TES 3 JOURS',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                  color: c.primary, // lagon
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'On a appris deux ou trois choses sur toi.',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(height: 1.15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              _StatsRow(metrics: m),
              const SizedBox(height: 24),
              if (boss != null) _BossCard(name: boss.name),
              const SizedBox(height: 28),
              Text(
                'Comment tu veux t’y prendre ?',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 14),
              _ModeButton(
                icon: Icons.block_outlined,
                label: 'Arrêt net',
                subtitle: 'j’arrête, on tient le compteur',
                onTap: () => _choose(ref, JourneyMode.coldTurkey),
              ),
              const SizedBox(height: 10),
              _ModeButton(
                icon: Icons.trending_down,
                label: 'Réduction progressive',
                subtitle: 'on attaque les Boss un par un',
                onTap: () => _choose(ref, JourneyMode.reduction),
              ),
              const SizedBox(height: 10),
              _ModeButton(
                icon: Icons.schedule,
                label: 'Je ne sais pas encore',
                subtitle: 'continue à observer, sans pression',
                ghost: true,
                onTap: () => _choose(ref, JourneyMode.undecided),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.metrics});
  final MetricsSummary metrics;

  @override
  Widget build(BuildContext context) {
    final gap = metrics.medianGap;
    final w = metrics.busiestWindow;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _StatTile(
            value: metrics.perDay.round().toString(),
            unit: '/j',
            label: 'en moyenne',
          ),
        ),
        Expanded(
          child: _StatTile(
            value: gap == null ? '—' : formatSinceLast(gap),
            unit: '',
            label: 'écart médian',
          ),
        ),
        Expanded(
          child: _StatTile(
            value: w == null ? '—' : '${w.$1}–${w.$2}',
            unit: 'h',
            label: 'créneau chargé',
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.unit, required this.label});
  final String value;
  final String unit;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: c.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (unit.isNotEmpty)
              Text(
                ' $unit',
                style: TextStyle(
                  fontSize: 13,
                  color: c.onSurface.withValues(alpha: 0.6),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 0.3,
            color: c.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _BossCard extends StatelessWidget {
  const _BossCard({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    // Le Boss = un gros rocher. Ocre minéral, jamais de rouge.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.secondary.withValues(alpha: 0.40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TON PREMIER ADVERSAIRE',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w700,
              color: c.secondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'C’est la plus ancrée — alors on lui donne un nom. On s’y attaquera ensemble.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.35,
              color: c.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.ghost = false,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool ghost;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final accent = c.primary; // lagon
    final borderColor =
        ghost ? c.onSurface.withValues(alpha: 0.20) : accent.withValues(alpha: 0.55);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: borderColor,
              width: ghost ? 1 : 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 22,
                  color: ghost
                      ? c.onSurface.withValues(alpha: 0.5)
                      : accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: c.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
