import 'package:flutter_test/flutter_test.dart';
import 'package:knobelfuchs/domain/challenge.dart';
import 'package:knobelfuchs/domain/game.dart';

void main() {
  group('encode/decode roundtrip', () {
    test('finite budgets with target', () {
      const config =
          GameConfig(seed: 'herbst-fuchs', adds: 5, hints: 3, target: 1840);
      final decoded = decodeChallenge(encodeChallenge(config))!;
      expect(decoded.seed, 'herbst-fuchs');
      expect(decoded.adds, 5);
      expect(decoded.hints, 3);
      expect(decoded.target, 1840);
    });

    test('limitless budgets and no target survive', () {
      const config = GameConfig(seed: '738291', adds: null, hints: null);
      final uri = encodeChallenge(config);
      expect(uri.toString(), contains('a=inf'));
      final decoded = decodeChallenge(uri)!;
      expect(decoded.adds, isNull);
      expect(decoded.hints, isNull);
      expect(decoded.target, isNull);
    });

    test('payload shape is the documented deep link', () {
      const config = GameConfig(seed: 'fuchs', adds: 5, hints: 5, target: 100);
      final uri = encodeChallenge(config);
      expect(uri.scheme, 'knobelfuchs');
      expect(uri.host, 'c');
      expect(uri.queryParameters['v'], '1');
    });
  });

  group('rejection', () {
    test('wrong version, scheme, or host', () {
      expect(
        decodeChallenge(Uri.parse('knobelfuchs://c?v=2&s=x&a=5&h=5')),
        isNull, // politely decline codes from the future
      );
      expect(
        decodeChallenge(Uri.parse('otherapp://c?v=1&s=x&a=5&h=5')),
        isNull,
      );
      expect(
        decodeChallenge(Uri.parse('knobelfuchs://other?v=1&s=x&a=5&h=5')),
        isNull,
      );
    });

    test('missing or malformed fields', () {
      expect(decodeChallenge(Uri.parse('knobelfuchs://c?v=1&a=5&h=5')), isNull);
      expect(
        decodeChallenge(Uri.parse('knobelfuchs://c?v=1&s=x&h=5')),
        isNull, // missing adds
      );
      expect(
        decodeChallenge(Uri.parse('knobelfuchs://c?v=1&s=x&a=lots&h=5')),
        isNull,
      );
    });
  });
}
