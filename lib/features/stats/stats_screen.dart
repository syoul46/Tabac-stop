import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/time/format.dart';
import '../../data/cigarette_repository.dart';
import '../../data/database.dart';
import '../../data/journey_repository.dart';
import '../../domain/boss/boss.dart';
import '../../domain/boss/victory.dart';
import '../../domain/health/milestones.dart';
import '../../domain/journey/delay.dart';
import '../../domain/journey/reveal_gate.dart';
import '../../domain/metrics/hourly.dart';
import '../../domain/metrics/metrics.dart';
import '../observation/hourly_curve.dart';
import '../reveal/reveal_screen.dart';

/// Écran de statistiques — ouvert par l'utilisateur (donc l'app peut détailler,
/// sans violer « elle se tait » qui ne vaut que pour la parole non sollicitée).
/// Tout est **dérivé** du journal, rien de stocké.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final now = DateTime.now();

    final cigs =
        ref.watch(allCigarettesProvider).asData?.value ?? const <Cigarette>[];
    final events =
        ref.watch(journeyEventsProvider).asData?.value ?? const <JourneyEvent>[];
    final m = ref.watch(metricsProvider);
    final report = ref.watch(bossReportProvider);

    final record = recordGap(cigs, now);
    final cleanDays = cumulativeCleanDays(cigs, now);
    final abstinence = currentAbstinence(cigs, now);
    final current = milestoneAt(abstinence);
    final next = nextMilestoneAfter(abstinence);
    final stones = stonesPlaced(events);
    final defeated = defeatedBossKeys(report, events);
    final currentMode = ref.watch(currentModeProvider).asData?.value;
    // Le retour à la révélation n'a de sens qu'une fois le portrait « mûr »
    // (assez de données) ou un mode déjà choisi (pour changer d'avis).
    final canRevisitReveal = shouldReveal(cigs, now) || currentMode != null;

    final gap = m.medianGap;
    final win = m.busiestWindow;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tes chiffres'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: cigs.isEmpty
          ? Center(
              child: Text('Pas encore de données.',
                  style: TextStyle(color: c.onSurface.withValues(alpha: 0.6))),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                _Section(label: 'Ton rythme'),
                _Tiles(children: [
                  _Tile(value: '${m.total}', label: 'cigarettes'),
                  _Tile(value: '${m.days}', label: 'jours suivis'),
                  _Tile(
                      value: m.perDay.toStringAsFixed(m.perDay < 10 ? 1 : 0),
                      unit: '/j',
                      label: 'moyenne'),
                  _Tile(
                      value: gap == null ? '—' : formatSinceLast(gap),
                      label: 'écart médian'),
                  _Tile(
                      value: win == null ? '—' : '${win.$1}–${win.$2}',
                      unit: win == null ? '' : 'h',
                      label: 'créneau chargé'),
                ]),
                const SizedBox(height: 24),
                _Section(label: 'Ce que rien n’efface'),
                _Tiles(children: [
                  _Tile(
                      value: '$cleanDays',
                      label: cleanDays <= 1 ? 'jour propre' : 'jours propres'),
                  _Tile(value: formatStreak(record), label: 'plus haut cairn'),
                  _Tile(value: '$stones', label: 'pierres posées'),
                  if (defeated.isNotEmpty)
                    _Tile(
                        value: '${defeated.length}',
                        label: defeated.length <= 1
                            ? 'Boss vaincu'
                            : 'Boss vaincus'),
                ]),
                if (current != null || next != null) ...[
                  const SizedBox(height: 24),
                  _Section(label: 'Altitude'),
                  _AltitudeCard(current: current, next: next),
                ],
                const SizedBox(height: 24),
                _Section(label: 'Tes heures'),
                const SizedBox(height: 8),
                HourlyCurve(counts: hourlyCounts(cigs)),
                if (report.bosses.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _Section(label: 'Tes Boss'),
                  for (final b in report.bosses)
                    _BossRow(boss: b, defeated: defeated.contains(bossKey(b))),
                ],
                if (canRevisitReveal) ...[
                  const SizedBox(height: 30),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) =>
                                const RevealScreen(revisit: true)),
                      ),
                      icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                      label: const Text('Revoir ma révélation'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: c.primary,
                        side: BorderSide(
                            color: c.primary.withValues(alpha: 0.5)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w700,
          color: c.primary,
        ),
      ),
    );
  }
}

class _Tiles extends StatelessWidget {
  const _Tiles({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) =>
      Wrap(spacing: 26, runSpacing: 18, children: children);
}

class _Tile extends StatelessWidget {
  const _Tile({required this.value, this.unit = '', required this.label});
  final String value;
  final String unit;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return SizedBox(
      width: 96,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: c.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (unit.isNotEmpty)
                Text(' $unit',
                    style: TextStyle(
                        fontSize: 12,
                        color: c.onSurface.withValues(alpha: 0.6))),
            ],
          ),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 11.5, color: c.onSurface.withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}

class _AltitudeCard extends StatelessWidget {
  const _AltitudeCard({required this.current, required this.next});
  final HealthMilestone? current;
  final HealthMilestone? next;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.primary.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (current != null) ...[
            Text('▲ ${current!.altitudeMeters} m',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: c.primary)),
            const SizedBox(height: 2),
            Text(current!.fact,
                style: TextStyle(
                    fontSize: 13, color: c.onSurface.withValues(alpha: 0.8))),
          ] else
            Text('Le cairn commence à monter.',
                style: TextStyle(
                    fontSize: 13, color: c.onSurface.withValues(alpha: 0.8))),
          if (next != null) ...[
            const SizedBox(height: 8),
            Text(
                'prochain palier : ${next!.title} sans fumer → '
                '${next!.altitudeMeters} m',
                style: TextStyle(
                    fontSize: 12, color: c.onSurface.withValues(alpha: 0.5))),
          ],
        ],
      ),
    );
  }
}

class _BossRow extends StatelessWidget {
  const _BossRow({required this.boss, required this.defeated});
  final Boss boss;
  final bool defeated;

  String get _difficulty => switch (boss.difficulty) {
        BossDifficulty.easy => 'fragile',
        BossDifficulty.medium => 'tenace',
        BossDifficulty.hard => 'coriace',
      };

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final hibiscus = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFE07050)
        : const Color(0xFFCB5A38);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(defeated ? Icons.check_circle : Icons.circle_outlined,
              size: 18,
              color: defeated ? hibiscus : c.onSurface.withValues(alpha: 0.35)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(boss.name,
                style: TextStyle(
                    fontSize: 14,
                    color: c.onSurface.withValues(alpha: defeated ? 0.6 : 0.9),
                    decoration:
                        defeated ? TextDecoration.lineThrough : null)),
          ),
          Text(defeated ? 'vaincu' : _difficulty,
              style: TextStyle(
                  fontSize: 12,
                  color: defeated
                      ? hibiscus
                      : c.onSurface.withValues(alpha: 0.5))),
        ],
      ),
    );
  }
}
