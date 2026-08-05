import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/update/update_service.dart';

/// Résumé condensé des notes de release (markdown) : la « tête » de chaque puce
/// (jusqu'au 1ᵉʳ point), sans les `#`, `**`, ni liens. 4 items max.
String _condensedNotes(String notes) {
  final items = <String>[];
  for (final raw in notes.split('\n')) {
    final line = raw.trim();
    if (!(line.startsWith('- ') || line.startsWith('* '))) continue;
    var l = line.substring(2).trim().replaceAll('**', '');
    l = l.replaceAllMapped(
        RegExp(r'\[([^\]]+)\]\([^)]*\)'), (m) => m[1] ?? ''); // liens → texte
    if (l.isEmpty) continue;
    final dot = l.indexOf('.');
    var head = (dot > 0 && dot <= 60) ? l.substring(0, dot) : l;
    if (head.length > 58) head = '${head.substring(0, 57)}…';
    items.add('• $head');
    if (items.length >= 4) break;
  }
  return items.join('\n');
}

/// Bandeau discret, en haut, quand une nouvelle version existe. Un tap télécharge
/// et lance l'installeur. Rejetable. Conforme à la règle « l'app parle peu » :
/// n'apparaît que sur un fait concret (mise à jour dispo) et jamais en cas
/// d'erreur réseau (le service échoue en silence).
class UpdateBanner extends ConsumerStatefulWidget {
  const UpdateBanner({super.key});

  @override
  ConsumerState<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends ConsumerState<UpdateBanner> {
  // Version ignorée par l'utilisateur : une version encore plus récente, détectée
  // plus tard (au retour au premier plan), réapparaîtra donc.
  String? _dismissedVersion;
  bool _busy = false;
  double _progress = 0;

  Future<void> _update(UpdateInfo info) async {
    setState(() {
      _busy = true;
      _progress = 0;
    });
    try {
      await downloadAndInstall(
        info,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      // L'installeur système prend le relais ; on efface le bandeau.
      if (mounted) setState(() => _dismissedVersion = info.version);
    } on UpdateException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mise à jour impossible pour le moment.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = ref.watch(updateCheckProvider).asData?.value;
    if (info == null) return const SizedBox.shrink();
    if (info.version == _dismissedVersion) return const SizedBox.shrink();

    final c = Theme.of(context).colorScheme;
    final summary = _condensedNotes(info.notes);
    return Positioned(
      // Pleine largeur (recouvre brièvement les icônes du haut le temps de la
      // proposition) : le texte a toute la place → jamais de rendu vertical.
      top: 0,
      left: 8,
      right: 8,
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 12, 8),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.primary.withValues(alpha: 0.45)),
            ),
            child: _busy
                ? Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: _progress > 0 ? _progress : null,
                          color: c.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          _progress > 0
                              ? 'Téléchargement… ${(_progress * 100).round()} %'
                              : 'Téléchargement…',
                          style: TextStyle(fontSize: 13.5, color: c.onSurface),
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Cairn ${info.version} est disponible.',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: c.onSurface.withValues(alpha: 0.85),
                        ),
                      ),
                      if (summary.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          summary,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: c.onSurface.withValues(alpha: 0.65),
                          ),
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => setState(
                                () => _dismissedVersion = info.version),
                            style: TextButton.styleFrom(
                                foregroundColor:
                                    c.onSurface.withValues(alpha: 0.6)),
                            child: const Text('Plus tard'),
                          ),
                          const SizedBox(width: 4),
                          TextButton(
                            onPressed: () => _update(info),
                            style: TextButton.styleFrom(
                                foregroundColor: c.primary),
                            child: const Text('Mettre à jour'),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
