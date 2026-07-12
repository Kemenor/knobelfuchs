import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:knobelfuchs/domain/seed.dart';

void main() {
  group('normalizeSeed', () {
    test('lowercases and dashes whitespace', () {
      expect(normalizeSeed('Herbst Fuchs'), 'herbst-fuchs');
      expect(normalizeSeed('  HERBST   fuchs  '), 'herbst-fuchs');
    });

    test('NFC: composed and decomposed umlauts are the same seed', () {
      const composed = 'f\u00FCchse'; // u-umlaut as one code point
      const decomposed = 'fu\u0308chse'; // u + combining diaeresis
      expect(decomposed == composed, isFalse); // different code points going in
      expect(normalizeSeed(decomposed), normalizeSeed(composed));
      expect(
        seedHash(normalizeSeed(decomposed)),
        seedHash(normalizeSeed(composed)),
      );
    });

    test('drops disallowed characters, keeps letters/digits/dashes', () {
      expect(normalizeSeed('foo!bar?'), 'foobar');
      expect(normalizeSeed('omas geburtstag: 1958'), 'omas-geburtstag-1958');
      expect(normalizeSeed('738291'), '738291');
    });

    test('collapses and trims dashes', () {
      expect(normalizeSeed('a - - b'), 'a-b');
      expect(normalizeSeed('-fuchs-'), 'fuchs');
    });

    test('caps at 32 runes', () {
      final long = 'x' * 50;
      expect(normalizeSeed(long).length, 32);
    });

    test('empty stays empty', () {
      expect(normalizeSeed('   '), '');
    });
  });

  group('fnv1a64', () {
    test('matches known FNV-1a test vectors', () {
      expect(fnv1a64(utf8.encode('')), 0xcbf29ce484222325);
      expect(fnv1a64(utf8.encode('a')), 0xaf63dc4c8601ec8c);
    });

    test('is deterministic and input-sensitive', () {
      expect(seedHash('herbst-fuchs'), seedHash('herbst-fuchs'));
      expect(seedHash('herbst-fuchs'), isNot(seedHash('herbst-fuchs2')));
    });
  });

  group('mixSeedAttempt', () {
    test('separates seed and attempt (no cross-seed collisions by +1)', () {
      final s = seedHash('20260712');
      final t = seedHash('20260713');
      // attempt-rerolls of one day never equal attempt 0 of the next day
      expect(mixSeedAttempt(s, 1), isNot(mixSeedAttempt(t, 0)));
      expect(mixSeedAttempt(s, 0), isNot(mixSeedAttempt(s, 1)));
      expect(mixSeedAttempt(s, 0), mixSeedAttempt(s, 0));
    });
  });
}
