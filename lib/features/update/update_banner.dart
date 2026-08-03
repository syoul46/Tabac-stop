import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/update/update_service.dart';

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
    return Positioned(
      top: 0,
      // laisse la place aux icônes (stats à gauche, bouclier à droite)
      left: 52,
      right: 52,
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
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
                      Text(
                        _progress > 0
                            ? 'Téléchargement… ${(_progress * 100).round()} %'
                            : 'Téléchargement…',
                        style: TextStyle(fontSize: 13.5, color: c.onSurface),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Cairn ${info.version} est disponible.',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: c.onSurface.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _update(info),
                        style: TextButton.styleFrom(foregroundColor: c.primary),
                        child: const Text('Mettre à jour'),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Ignorer',
                        icon: Icon(Icons.close,
                            size: 18,
                            color: c.onSurface.withValues(alpha: 0.5)),
                        onPressed: () =>
                            setState(() => _dismissedVersion = info.version),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
