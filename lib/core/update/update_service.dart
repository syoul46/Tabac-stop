import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../domain/update/version.dart';

/// Dépôt GitHub interrogé pour les releases.
const _kRepo = 'syoul46/Tabac-stop';

/// Une mise à jour disponible : version distante + APK à installer.
class UpdateInfo {
  const UpdateInfo({
    required this.version,
    required this.notes,
    required this.apkUrl,
    required this.apkSize,
    required this.pageUrl,
  });

  final String version; // ex. "1.1.0" (sans le "v")
  final String notes;
  final String apkUrl; // URL de téléchargement direct de l'APK adapté à l'appareil
  final int apkSize; // octets (0 si inconnu)
  final String pageUrl; // page de la release (repli navigateur)
}

/// Vérifie l'API publique GitHub et, si une version plus récente existe avec un
/// APK adapté à l'ABI de l'appareil, renvoie l'[UpdateInfo]. Sinon `null`.
///
/// **Échoue en silence** (renvoie `null`) sur toute erreur réseau/parse : la
/// règle du produit est de ne jamais déranger l'utilisateur pour rien.
Future<UpdateInfo?> checkForUpdate() async {
  if (!Platform.isAndroid) return null;
  try {
    final res = await http
        .get(
          Uri.parse('https://api.github.com/repos/$_kRepo/releases/latest'),
          headers: const {'Accept': 'application/vnd.github+json'},
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return null;

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final tag = (json['tag_name'] as String?) ?? '';
    final current = (await PackageInfo.fromPlatform()).version;
    if (tag.isEmpty || !isNewer(tag, current)) return null;

    final assets = (json['assets'] as List?)?.cast<Map<String, dynamic>>() ??
        const <Map<String, dynamic>>[];
    final asset = _pickApkAsset(assets, await _deviceAbis());
    if (asset == null) return null;

    return UpdateInfo(
      version: _stripV(tag),
      notes: (json['body'] as String?)?.trim() ?? '',
      apkUrl: asset['browser_download_url'] as String,
      apkSize: (asset['size'] as num?)?.toInt() ?? 0,
      pageUrl: (json['html_url'] as String?) ??
          'https://github.com/$_kRepo/releases/latest',
    );
  } catch (_) {
    return null; // silence : pas de réseau, JSON inattendu, timeout…
  }
}

String _stripV(String s) =>
    (s.startsWith('v') || s.startsWith('V')) ? s.substring(1) : s;

Future<List<String>> _deviceAbis() async {
  try {
    final info = await DeviceInfoPlugin().androidInfo;
    return info.supportedAbis;
  } catch (_) {
    return const [];
  }
}

/// Choisit l'asset `.apk` correspondant à l'ABI de l'appareil (téléchargement le
/// plus léger). Repli : un asset arm64, puis le premier `.apk` trouvé.
Map<String, dynamic>? _pickApkAsset(
  List<Map<String, dynamic>> assets,
  List<String> abis,
) {
  final apks = assets
      .where((a) => (a['name'] as String?)?.toLowerCase().endsWith('.apk') ?? false)
      .toList();
  if (apks.isEmpty) return null;

  bool nameHas(Map<String, dynamic> a, String needle) =>
      (a['name'] as String).toLowerCase().contains(needle);

  for (final abi in abis) {
    final match = apks.where((a) => nameHas(a, abi.toLowerCase()));
    if (match.isNotEmpty) return match.first;
  }
  final arm64 = apks.where((a) => nameHas(a, 'arm64'));
  if (arm64.isNotEmpty) return arm64.first;
  return apks.first;
}

/// Télécharge l'APK (avec progression 0..1) puis lance l'installeur système.
///
/// Nécessite la permission « installer des applis inconnues ». Lève une
/// [UpdateException] avec un message lisible en cas d'échec.
Future<void> downloadAndInstall(
  UpdateInfo info, {
  void Function(double progress)? onProgress,
}) async {
  // 0. Android uniquement : iOS n'autorise aucune installation hors App Store
  //    (sur iPhone, Cairn se met à jour en re-sideloadant l'.ipa — cf. PLAN §17).
  //    checkForUpdate() renvoie déjà null ailleurs ; cette garde est la ceinture.
  if (!Platform.isAndroid) {
    throw const UpdateException('Mise à jour automatique indisponible ici.');
  }

  // 1. Permission d'installer des paquets (Android 8+).
  final status = await Permission.requestInstallPackages.request();
  if (!status.isGranted) {
    throw const UpdateException(
        'Autorise « Installer des applis inconnues » pour Cairn, puis réessaie.');
  }

  // 2. Téléchargement en flux vers le dossier temporaire.
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/cairn-${info.version}.apk');
  final client = http.Client();
  try {
    final req = http.Request('GET', Uri.parse(info.apkUrl));
    final resp = await client.send(req);
    if (resp.statusCode != 200) {
      throw UpdateException('Téléchargement impossible (HTTP ${resp.statusCode}).');
    }
    final total = resp.contentLength ?? info.apkSize;
    final sink = file.openWrite();
    var received = 0;
    await for (final chunk in resp.stream) {
      sink.add(chunk);
      received += chunk.length;
      if (total > 0) onProgress?.call(received / total);
    }
    await sink.close();
  } on UpdateException {
    rethrow;
  } catch (_) {
    throw const UpdateException('Téléchargement interrompu. Vérifie ta connexion.');
  } finally {
    client.close();
  }

  // 3. Ouvre l'APK → installeur système, via le canal natif (MainActivity.kt).
  //    Un plugin faisait ça avant, mais il déclarait une implémentation iOS et
  //    s'invitait donc dans tous les builds iOS — où installer un APK n'a aucun
  //    sens — en bloquant au passage la migration vers Swift Package Manager.
  try {
    await _installer.invokeMethod<void>('openApk', {'path': file.path});
  } on PlatformException catch (e) {
    throw UpdateException(
        "Ouverture de l'installeur impossible : ${e.message ?? e.code}");
  } on MissingPluginException {
    throw const UpdateException(
        "Ouverture de l'installeur impossible sur cet appareil.");
  }
}

/// Canal vers `MainActivity.kt`. Android uniquement — appelé après la garde
/// `Platform.isAndroid` de [downloadAndInstall].
const _installer = MethodChannel('cairn/installer');

class UpdateException implements Exception {
  const UpdateException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Vérifie une seule fois au lancement. `null` = pas de mise à jour / hors ligne.
final updateCheckProvider = FutureProvider<UpdateInfo?>((ref) => checkForUpdate());
