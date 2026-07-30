import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/crypto/vault.dart';
import 'database.dart';
import 'database_provider.dart';

/// Export/import chiffré du journal complet. Remplace le « compte » : rien ne
/// quitte l'appareil sauf un fichier `.enc` opaque, à la main de l'utilisateur.
class BackupService {
  BackupService(this._db, [Vault? vault]) : _vault = vault ?? Vault();

  final CairnDatabase _db;
  final Vault _vault;

  static const _version = 1;

  /// Sérialise tout le journal puis le chiffre avec [passphrase].
  Future<String> exportEncrypted(
    String passphrase, {
    Argon2Params params = const Argon2Params(),
  }) async {
    final cigs = await _db.select(_db.cigarettes).get();
    final events = await _db.select(_db.journeyEvents).get();
    final payload = jsonEncode({
      'app': 'cairn',
      'v': _version,
      'cigarettes': cigs.map(_cigToJson).toList(),
      'journeyEvents': events.map(_eventToJson).toList(),
    });
    return _vault.encrypt(payload, passphrase, params: params);
  }

  /// Déchiffre puis **remplace** le contenu local par la sauvegarde.
  Future<void> importEncrypted(String envelope, String passphrase) async {
    final data =
        jsonDecode(await _vault.decrypt(envelope, passphrase)) as Map<String, dynamic>;
    if (data['app'] != 'cairn') {
      throw const VaultException('Sauvegarde non reconnue.');
    }
    final cigs = (data['cigarettes'] as List).cast<Map<String, dynamic>>();
    final events = (data['journeyEvents'] as List).cast<Map<String, dynamic>>();

    await _db.transaction(() async {
      await _db.delete(_db.cigarettes).go();
      await _db.delete(_db.journeyEvents).go();
      await _db.batch((b) {
        b.insertAll(_db.cigarettes, cigs.map(_cigFromJson));
        b.insertAll(_db.journeyEvents, events.map(_eventFromJson));
      });
    });
  }

  static Map<String, dynamic> _cigToJson(Cigarette c) => {
        'id': c.id,
        'at': c.occurredAtUtc.toUtc().millisecondsSinceEpoch,
        'tz': c.tzOffsetMin,
        'a': c.contextA,
        'b': c.contextB,
        'c': c.contextC,
        'boss': c.wasBoss,
        'delay': c.duringDelay,
      };

  static CigarettesCompanion _cigFromJson(Map<String, dynamic> j) =>
      CigarettesCompanion.insert(
        id: j['id'] as String,
        occurredAtUtc:
            DateTime.fromMillisecondsSinceEpoch(j['at'] as int, isUtc: true),
        tzOffsetMin: j['tz'] as int,
        contextA: Value(j['a'] as int?),
        contextB: Value(j['b'] as int?),
        contextC: Value(j['c'] as int?),
        wasBoss: Value(j['boss'] as bool),
        duringDelay: Value(j['delay'] as bool),
      );

  static Map<String, dynamic> _eventToJson(JourneyEvent e) => {
        'id': e.id,
        'at': e.occurredAtUtc.toUtc().millisecondsSinceEpoch,
        'kind': e.kind,
        'payload': e.payload,
      };

  static JourneyEventsCompanion _eventFromJson(Map<String, dynamic> j) =>
      JourneyEventsCompanion.insert(
        id: j['id'] as String,
        occurredAtUtc:
            DateTime.fromMillisecondsSinceEpoch(j['at'] as int, isUtc: true),
        kind: j['kind'] as String,
        payload: Value(j['payload'] as String?),
      );
}

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.watch(databaseProvider));
});
