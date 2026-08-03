import 'package:cairn/domain/update/version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseVersion', () {
    test('retire le préfixe v', () {
      expect(parseVersion('v1.2.3'), [1, 2, 3]);
      expect(parseVersion('1.2.3'), [1, 2, 3]);
    });
    test('ignore le suffixe de build/pré-release', () {
      expect(parseVersion('1.2.3+7'), [1, 2, 3]);
      expect(parseVersion('v2.0.0-beta'), [2, 0, 0]);
    });
    test('parties non numériques → 0', () {
      expect(parseVersion('1.x.3'), [1, 0, 3]);
    });
  });

  group('compareVersions', () {
    test('égalité, y compris longueurs différentes', () {
      expect(compareVersions('1.2.0', '1.2'), 0);
      expect(compareVersions('v1.0.0', '1.0.0+3'), 0);
    });
    test('ordre', () {
      expect(compareVersions('1.0.1', '1.0.0'), 1);
      expect(compareVersions('1.0.0', '1.0.1'), -1);
      expect(compareVersions('2.0.0', '1.9.9'), 1);
      expect(compareVersions('1.2.0', '1.10.0'), -1); // numérique, pas lexical
    });
  });

  group('isNewer', () {
    test('détecte une version plus récente', () {
      expect(isNewer('v1.1.0', '1.0.0'), isTrue);
      expect(isNewer('v1.0.0', '1.0.0'), isFalse); // pas de faux positif à égalité
      expect(isNewer('v0.9.0', '1.0.0'), isFalse);
    });
  });
}
