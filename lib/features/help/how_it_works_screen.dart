import 'package:flutter/material.dart';

import '../cairn/cairn_view.dart';

/// « La règle du jeu » — écran ouvert par l'utilisateur qui explique tout le
/// fonctionnement. Comme il est sollicité, l'app peut détailler (la règle du
/// silence ne vaut que pour la parole non demandée). Ton calme, pas de morale.
class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final hibiscus = theme.brightness == Brightness.dark
        ? const Color(0xFFE07050)
        : const Color(0xFFCB5A38);

    return Scaffold(
      appBar: AppBar(
        title: const Text('La règle du jeu'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 44),
        children: [
          Center(
            child: CairnView(
                stones: 4, bossRocks: 1, width: 150, height: 150),
          ),
          const SizedBox(height: 8),
          Text(
            'Cairn parle le moins possible — et jamais quand tu es en difficulté. '
            'Il ne dit quelque chose que (1) quand tu as réussi, (2) quand il a '
            'un fait à te révéler. Le reste du temps, c’est juste un bouton.',
            style: TextStyle(
                fontSize: 15,
                height: 1.45,
                color: c.onSurface.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: 28),
          const _Rule(
            icon: Icons.touch_app_outlined,
            title: 'Un bouton, c’est tout',
            body: 'Tu tapes quand tu fumes. Pas de compte, pas de date d’arrêt, '
                'pas de « combien par jour ». Ça démarre tout seul.',
          ),
          const _Rule(
            icon: Icons.visibility_outlined,
            title: 'La première semaine : on observe',
            body: 'Cairn enregistre en silence et ne te propose rien. Fume '
                'normalement — c’est ce qui donne des données vraies, sans '
                'culpabilité ni faux chiffres. Une semaine entière capte aussi '
                'ton rythme du week-end.',
          ),
          _Rule(
            icon: Icons.auto_awesome_outlined,
            iconColor: c.primary,
            title: 'La révélation',
            body: 'Elle se déclenche après **7 jours** ET **au moins 30 '
                'cigarettes** enregistrées. En dessous, Cairn préfère continuer '
                'd’observer en silence plutôt que de sortir une analyse bancale. '
                'Là, il parle pour la première fois : ton rythme, et le nom de '
                'ton Boss — la cigarette la plus ancrée, « le Café de 7 h 10 ». '
                'Puis tu choisis : arrêt net, réduction en douceur, ou « je ne '
                'sais pas encore ». Aucune porte n’est jamais fermée.',
          ),
          _Rule(
            icon: Icons.terrain_outlined,
            title: 'Le cairn monte',
            body: 'Chaque envie résistée, chaque palier franchi pose une pierre. '
                'Le cairn grandit. Fumer ne fait JAMAIS tomber de pierre — le '
                'cairn se met juste en pause. Ton « plus haut cairn » ne '
                'redescend jamais, même après une rechute.',
          ),
          _Rule(
            icon: Icons.landscape_outlined,
            iconColor: hibiscus,
            title: 'Tes Boss',
            body: 'On attaque le Boss le plus fragile en premier, un délai de '
                '10 minutes à la fois. Tiens-le 3 jours et le Boss est vaincu : '
                'un gros rocher est hissé au sommet de ton cairn. Puis on passe '
                'au suivant.',
          ),
          _Rule(
            icon: Icons.trending_up,
            iconColor: c.primary,
            title: 'Les altitudes',
            body: 'Plus tu tiens sans fumer, plus le cairn prend de l’altitude — '
                'et chaque palier te révèle un fait vrai sur ton corps : 12 h le '
                'monoxyde de carbone repart, 48 h le goût revient, 1 an le risque '
                'cardiaque divisé par deux. Après une rechute, la montée les '
                'rejoue — ta récupération repart vraiment de zéro.',
          ),
          _Rule(
            icon: Icons.lock_outline,
            title: 'Tes données restent à toi',
            body: 'Tout reste sur ton téléphone : aucun compte, aucun serveur. '
                'Tu peux exporter une sauvegarde chiffrée quand tu veux. Seule '
                'connexion : vérifier s’il existe une mise à jour.',
          ),
          const SizedBox(height: 8),
          Center(
            child: Text('Un tas de pierres ne tousse pas.',
                style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: c.onSurface.withValues(alpha: 0.5))),
          ),
        ],
      ),
    );
  }
}

/// Rend un texte où les segments entre `**` sont mis en gras.
TextSpan _emphasize(String text, TextStyle base) {
  final spans = <TextSpan>[];
  final parts = text.split('**');
  for (var i = 0; i < parts.length; i++) {
    if (parts[i].isEmpty) continue;
    spans.add(TextSpan(
      text: parts[i],
      style: i.isOdd ? base.copyWith(fontWeight: FontWeight.w700) : base,
    ));
  }
  return TextSpan(style: base, children: spans);
}

class _Rule extends StatelessWidget {
  const _Rule({
    required this.icon,
    required this.title,
    required this.body,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: iconColor ?? c.onSurface.withValues(alpha: 0.55)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text.rich(
                  _emphasize(
                    body,
                    TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: c.onSurface.withValues(alpha: 0.75)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
