import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Filigrane discret « vX.Y.Z » en bas d'écran — permet de vérifier d'un coup
/// d'œil quelle version tourne (utile après une mise à jour). N'intercepte
/// aucun tap.
class VersionTag extends StatelessWidget {
  const VersionTag({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 6,
      child: SafeArea(
        top: false,
        child: IgnorePointer(
          child: Center(
            child: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snap) {
                final v = snap.data?.version;
                if (v == null) return const SizedBox.shrink();
                return Text(
                  'v$v · dédicacé à mon Arc-en-ciel ♥',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.3),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
