import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Paramètres de dérivation Argon2id. Parallélisme fixé à 1 (impl. pure Dart).
class Argon2Params {
  const Argon2Params({this.memory = 19456, this.iterations = 2});

  /// Mémoire en KiB (défaut ~19 Mio, ordre OWASP).
  final int memory;
  final int iterations;

  /// Réglage minuscule pour les tests (rapide).
  static const fast = Argon2Params(memory: 256, iterations: 1);

  Map<String, dynamic> toJson() => {'memory': memory, 'iterations': iterations};

  factory Argon2Params.fromJson(Map<String, dynamic> j) => Argon2Params(
        memory: j['memory'] as int,
        iterations: j['iterations'] as int,
      );
}

/// Coffre local : chiffre/déchiffre du texte avec une passphrase.
///
/// Passphrase → **Argon2id** → clé 256 bits → **XChaCha20-Poly1305** (chiffrement
/// authentifié). Produit une enveloppe JSON auto-descriptive (sel, nonce, params,
/// ciphertext, MAC en base64) — un blob opaque, rien de déchiffrable sans la
/// passphrase. Tout se passe côté client ; aucune donnée en clair ne sort.
class Vault {
  static const _version = 1;
  static const _keyLength = 32;
  static const _saltLength = 16;

  final Random _rng = Random.secure();

  Future<String> encrypt(
    String clearText,
    String passphrase, {
    Argon2Params params = const Argon2Params(),
  }) async {
    final salt = _randomBytes(_saltLength);
    final key = await _deriveKey(passphrase, salt, params);

    final cipher = Xchacha20.poly1305Aead();
    final nonce = cipher.newNonce();
    final box = await cipher.encrypt(
      utf8.encode(clearText),
      secretKey: key,
      nonce: nonce,
    );

    return jsonEncode({
      'app': 'cairn',
      'v': _version,
      'kdf': {'algo': 'argon2id', 'salt': base64.encode(salt), ...params.toJson()},
      'cipher': 'xchacha20-poly1305',
      'nonce': base64.encode(box.nonce),
      'ct': base64.encode(box.cipherText),
      'mac': base64.encode(box.mac.bytes),
    });
  }

  /// Déchiffre une enveloppe. Lève une exception si la passphrase est mauvaise
  /// ou si le contenu a été altéré (MAC invalide).
  Future<String> decrypt(String envelope, String passphrase) async {
    final Map<String, dynamic> env;
    try {
      env = jsonDecode(envelope) as Map<String, dynamic>;
    } on FormatException {
      throw const VaultException('Fichier illisible.');
    }
    if (env['app'] != 'cairn') {
      throw const VaultException('Ce n’est pas une sauvegarde Cairn.');
    }

    final kdf = env['kdf'] as Map<String, dynamic>;
    final salt = base64.decode(kdf['salt'] as String);
    final key = await _deriveKey(passphrase, salt, Argon2Params.fromJson(kdf));

    final cipher = Xchacha20.poly1305Aead();
    final box = SecretBox(
      base64.decode(env['ct'] as String),
      nonce: base64.decode(env['nonce'] as String),
      mac: Mac(base64.decode(env['mac'] as String)),
    );

    try {
      return utf8.decode(await cipher.decrypt(box, secretKey: key));
    } on SecretBoxAuthenticationError {
      throw const VaultException('Passphrase incorrecte ou fichier altéré.');
    }
  }

  Future<SecretKey> _deriveKey(
      String passphrase, List<int> salt, Argon2Params p) async {
    final algo = Argon2id(
      memory: p.memory,
      iterations: p.iterations,
      parallelism: 1,
      hashLength: _keyLength,
    );
    return algo.deriveKey(
      secretKey: SecretKey(utf8.encode(passphrase)),
      nonce: salt,
    );
  }

  Uint8List _randomBytes(int n) =>
      Uint8List.fromList(List<int>.generate(n, (_) => _rng.nextInt(256)));
}

class VaultException implements Exception {
  const VaultException(this.message);
  final String message;
  @override
  String toString() => message;
}
