import 'package:flutter_test/flutter_test.dart';
import 'package:knobelfuchs/domain/challenge.dart';
import 'package:knobelfuchs/domain/game.dart';

void main() {
  group('encode/decode roundtrip', () {
    test('finite budgets with target', () {
      const config =
          GameConfig(seed: 'herbst-fuchs', adds: 5, hints: 3, target: 640);
      final decoded = decodeChallenge(encodeChallenge(config))!;
      expect(decoded.seed, 'herbst-fuchs');
      expect(decoded.adds, 5);
      expect(decoded.hints, 3);
      expect(decoded.target, 640);
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
      expect(
        decodeChallenge(Uri.parse('knobelfuchs://c?v=1&s=x&a=5&h=5&t=oops')),
        isNull, // a malformed target is a typo'd payload, not "no target"
      );
    });

    test('out-of-range budgets and targets are hostile, not configs (§7)',
        () {
      // A negative add budget would disable stuck detection; negative hints
      // would grant unlimited ones; a negative target is auto-beaten at 0.
      for (final link in [
        'knobelfuchs://c?v=1&s=x&a=-1&h=5',
        'knobelfuchs://c?v=1&s=x&a=5&h=-2',
        'knobelfuchs://c?v=1&s=x&a=999999&h=5',
        'knobelfuchs://c?v=1&s=x&a=5&h=21',
        'knobelfuchs://c?v=1&s=x&a=5&h=5&t=-50',
        'knobelfuchs://c?v=1&s=x&a=5&h=5&t=0',
        'knobelfuchs://c?v=1&s=x&a=5&h=5&t=99999',
      ]) {
        expect(decodeChallenge(Uri.parse(link)), isNull, reason: link);
      }
      // The full valid range still decodes.
      expect(
        decodeChallenge(
            Uri.parse('knobelfuchs://c?v=1&s=x&a=0&h=20&t=800')),
        isNotNull,
      );
    });

    test('the seed is normalized on decode — no namespace smuggling (§7)',
        () {
      final decoded = decodeChallenge(
          Uri.parse('knobelfuchs://c?v=1&s=Daily%3A20260712&a=5&h=5'))!;
      // ':' is not a seed character; the namespace prefix cannot survive.
      expect(decoded.seed, 'daily20260712');
      expect(
        decodeChallenge(Uri.parse('knobelfuchs://c?v=1&s=%3A%3A&a=5&h=5')),
        isNull, // nothing left after normalization
      );
    });
  });
}
