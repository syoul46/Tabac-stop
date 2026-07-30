import 'dart:convert';

import 'package:cairn/core/crypto/vault.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final vault = Vault();
  const params = Argon2Params.fast;

  test('round-trip : chiffre puis déchiffre', () async {
    final env = await vault.encrypt('journal secret', 'passphrase', params: params);
    expect(env.contains('journal secret'), isFalse); // enveloppe opaque
    expect(await vault.decrypt(env, 'passphrase'), 'journal secret');
  });

  test('mauvaise passphrase → VaultException', () async {
    final env = await vault.encrypt('x', 'bon', params: params);
    await expectLater(
        vault.decrypt(env, 'mauvais'), throwsA(isA<VaultException>()));
  });

  test('contenu altéré → VaultException', () async {
    final env = await vault.encrypt('x', 'bon', params: params);
    final map = jsonDecode(env) as Map<String, dynamic>;
    final ct = base64.decode(map['ct'] as String);
    ct[0] ^= 0xFF; // on corrompt un octet du ciphertext
    map['ct'] = base64.encode(ct);
    await expectLater(
        vault.decrypt(jsonEncode(map), 'bon'), throwsA(isA<VaultException>()));
  });

  test('fichier non-Cairn → VaultException', () async {
    await expectLater(
        vault.decrypt('{"app":"autre"}', 'x'), throwsA(isA<VaultException>()));
  });
}
