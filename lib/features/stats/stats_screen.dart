import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/time/format.dart';
import '../../data/cigarette_repository.dart';
import '../../data/database.dart';
import '../../data/journey_repository.dart';
import '../../domain/boss/boss.dart';
import '../../domain/boss/victory.dart';
import '../../domain/health/milestones.dart';
import '../../domain/journey/not_logged.dart';
import '../../domain/metrics/avoided.dart';
import '../../domain/journey/delay.dart';
import '../../domain/journey/reveal_gate.dart';
import '../../domain/metrics/daily.dart';
import '../../domain/metrics/hourly.dart';
import '../../domain/metrics/metrics.dart';
import '../../domain/metrics/triggers.dart';
import '../../domain/models/enums.dart';
import '../observation/hourly_curve.dart';
import '../reveal/reveal_screen.dart';
import 'daily_evolution.dart';

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

    final skipped = notLoggedDays(events);
    final record = recordGap(cigs, now, notLogged: skipped);
    final cleanDays = cumulativeCleanDays(cigs, now, notLogged: skipped);
    final abstinence = currentAbstinence(cigs, now);
    final current = milestoneAt(abstinence);
    final next = nextMilestoneAfter(abstinence);
    final stones = stonesPlaced(events);
    final fightSince = ref.watch(currentModeSinceProvider).asData?.value;
    final defeated = defeatedBossKeys(report, cigs, events, since: fightSince);
    final baseline = baselinePerDay(cigs, fightSince);
    final daily = dailyCounts(cigs, now, notLogged: skipped);
    final trend = rollingDailyAverage(daily);
    final triggers = triggerBreakdown(cigs);
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
                // Évolution jour par jour depuis le début. On l'affiche dès qu'il
                // y a au moins deux jours (un seul n'est pas une « évolution »).
                if (daily.length >= 2) ...[
                  const SizedBox(height: 24),
                  _Section(label: 'Ton évolution'),
                  const SizedBox(height: 8),
                  DailyEvolutionCurve(
                      days: daily, baseline: baseline, trend: trend),
                  const SizedBox(height: 6),
                  Text(
                    baseline != null
                        ? 'Une barre par jour, la courbe = ta tendance sur 7 '
                            'jours. La ligne pointillée = ton rythme d’avant — '
                            'tout ce qui passe dessous, c’est gagné.'
                        : 'Une barre par jour ; la courbe lisse ta tendance sur '
                            '7 jours.',
                    style: TextStyle(
                        fontSize: 11.5,
                        color: c.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
                // « Ce que tu as évité » : seulement si une référence honnête
                // existe (≥ 3 jours observés avant le choix du mode). Sinon on
                // se tait plutôt que d'avancer un chiffre fragile.
                if (baseline != null) ...[
                  const SizedBox(height: 24),
                  _Section(label: 'Ce que tu as évité'),
                  _Tiles(children: [
                    _Tile(
                        value: '~${avoidedOn(cigs, baseline, now)}',
                        label: 'aujourd’hui'),
                    _Tile(
                        value:
                            '~${avoidedSince(cigs, fightSince, now, notLogged: skipped)}',
                        label: 'depuis ton choix'),
                    _Tile(
                        value: baseline.toStringAsFixed(baseline < 10 ? 1 : 0),
                        unit: '/j',
                        label: 'ton rythme d’avant'),
                  ]),
                  const SizedBox(height: 6),
                  Text(
                    'Estimation : ton rythme de la semaine d’observation, '
                    'comparé à ce que tu fumes depuis. Il ne bouge plus.',
                    style: TextStyle(
                        fontSize: 11.5,
                        color: c.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
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
                // « Tes déclencheurs » : exploite les icônes ☕🍽️🍷 notées au tap.
                // On se tait sous le seuil (répartition trop fragile pour être juste).
                if (triggers.tagged >= kTriggersMinTagged) ...[
                  const SizedBox(height: 24),
                  _Section(label: 'Tes déclencheurs'),
                  _TriggersView(breakdown: triggers),
                ],
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

/// Libellés des contextes (emoji + nom court dans une tournure naturelle).
({String emoji, String label}) _ctxLabel(CigContext c) => switch (c) {
      CigContext.cafe => (emoji: '☕', label: 'un café'),
      CigContext.repas => (emoji: '🍽️', label: 'un repas'),
      CigContext.alcool => (emoji: '🍷', label: 'un verre'),
    };

class _TriggersView extends StatelessWidget {
  const _TriggersView({required this.breakdown});
  final TriggerBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final dominant = breakdown.dominant;
    // Contextes triés du plus fréquent au moins fréquent (ceux à zéro exclus).
    final ordered = [...CigContext.values]
      ..sort((a, b) =>
          (breakdown.counts[b] ?? 0).compareTo(breakdown.counts[a] ?? 0));
    final shown = ordered.where((x) => (breakdown.counts[x] ?? 0) > 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (dominant != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Le plus souvent, quand tu fumes, il y a '
              '${_ctxLabel(dominant).label} à côté.',
              style: TextStyle(
                  fontSize: 14,
                  height: 1.3,
                  color: c.onSurface.withValues(alpha: 0.9)),
            ),
          ),
        for (final ctx in shown) _TriggerBar(breakdown: breakdown, ctx: ctx),
        const SizedBox(height: 6),
        Text(
          'Parmi tes ${breakdown.tagged} cigarettes où tu as noté ☕ 🍽️ 🍷.',
          style: TextStyle(fontSize: 11.5, color: c.onSurface.withValues(alpha: 0.5)),
        ),
      ],
    );
  }
}

class _TriggerBar extends StatelessWidget {
  const _TriggerBar({required this.breakdown, required this.ctx});
  final TriggerBreakdown breakdown;
  final CigContext ctx;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final share = breakdown.share(ctx);
    final l = _ctxLabel(ctx);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(width: 26, child: Text(l.emoji, style: const TextStyle(fontSize: 16))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(height: 10, color: c.tertiary.withValues(alpha: 0.12)),
                  FractionallySizedBox(
                    widthFactor: share.clamp(0.0, 1.0),
                    child: Container(
                        height: 10, color: c.tertiary.withValues(alpha: 0.72)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 38,
            child: Text('${(share * 100).round()} %',
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 12,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: c.onSurface.withValues(alpha: 0.7))),
          ),
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
