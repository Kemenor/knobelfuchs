import 'package:flutter_test/flutter_test.dart';
import 'package:knobelfuchs/domain/constants.dart';
import 'package:knobelfuchs/domain/daily.dart';
import 'package:knobelfuchs/domain/game.dart';

void main() {
  group('daily seeds', () {
    test('live in their own namespace, one per date', () {
      expect(dailySeedKey(DateTime(2026, 7, 12)), 'daily:20260712');
      expect(dailySeedKey(DateTime(2026, 7, 12)),
          isNot(dailySeedKey(DateTime(2026, 7, 13))));
      // players can't type a colon — normalization strips it, so no clash
    });

    test('config carries a computed, deterministic target', () {
      final a = dailyConfig(DateTime(2026, 7, 12));
      final c = dailyConfig(DateTime(2026, 7, 12));
      expect(a.target, isNotNull);
      expect(a.target, c.target);
      expect(a.adds, kDefaultAdds);
      expect(a.hints, kDefaultHints);
    });

    test('different days, different boards', () {
      final a = GameState.fresh(dailyConfig(DateTime(2026, 7, 12)));
      final c = GameState.fresh(dailyConfig(DateTime(2026, 7, 13)));
      expect(
        [for (final x in a.board.cells) x.digit],
        isNot([for (final x in c.board.cells) x.digit]),
      );
    });
  });

  group('playability window (§6.2)', () {
    final now = DateTime(2026, 7, 12, 15, 30);

    test('epoch through today, inclusive', () {
      expect(isDailyPlayable(kDailyEpoch, now), isTrue);
      expect(isDailyPlayable(DateTime(2026, 7, 12), now), isTrue);
    });

    test('before the epoch and future dates are locked', () {
      expect(isDailyPlayable(DateTime(2026, 6, 30), now), isFalse);
      expect(isDailyPlayable(DateTime(2026, 7, 13), now), isFalse);
    });

    test('time of day is irrelevant', () {
      expect(
        isDailyPlayable(DateTime(2026, 7, 12, 23, 59), now),
        isTrue,
      );
    });
  });
}
