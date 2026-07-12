import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knobelfuchs/data/database.dart';
import 'package:knobelfuchs/domain/adventure.dart';
import 'package:knobelfuchs/ui/adventure/adventure_providers.dart';
import 'package:knobelfuchs/ui/providers.dart';

void main() {
  group('adventure curve (domain)', () {
    test('budgets tighten, never below the floor', () {
      for (var i = 1; i <= kAdventureLevels; i++) {
        expect(adventureAdds(i), inInclusiveRange(2, 5), reason: 'adds $i');
        expect(adventureHints(i), inInclusiveRange(1, 5), reason: 'hints $i');
        if (i > 1) {
          expect(adventureAdds(i), lessThanOrEqualTo(adventureAdds(i - 1)));
          expect(adventureHints(i), lessThanOrEqualTo(adventureHints(i - 1)));
        }
      }
    });

    test('factor ramps 0.9 → 1.0 (§4.1)', () {
      expect(adventureFactor(1), closeTo(0.9, 1e-9));
      expect(adventureFactor(kAdventureLevels), closeTo(1.0, 1e-9));
      for (var i = 2; i <= kAdventureLevels; i++) {
        expect(adventureFactor(i), greaterThan(adventureFactor(i - 1)));
      }
    });

    test('configs are deterministic with computed targets', () {
      final a = adventureConfig(6);
      final b = adventureConfig(6);
      expect(a.target, isNotNull);
      expect(a.target, b.target);
      expect(a.seed, 'level:6');
    });
  });

  group('adventureProvider unlock chain', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      container = ProviderContainer(
          overrides: [databaseProvider.overrideWithValue(db)]);
    });

    tearDown(() => container.dispose());

    Future<void> beat(int level, {int score = 500, bool beaten = true}) {
      final t = DateTime(2026, 7, 10);
      return db.into(db.runResults).insert(RunResultsCompanion.insert(
            slot: 'level:$level',
            seed: 'level:$level',
            score: score,
            cleared: false,
            targetBeaten: beaten,
            pairs: 1,
            rows: 0,
            addsUsed: 0,
            hintsUsed: 0,
            durationMs: 1,
            startedAt: t,
            endedAt: t,
          ));
    }

    test('fresh install: level 1 current, rest locked', () async {
      final list = await container.read(adventureProvider.future);
      expect(list.length, kAdventureLevels);
      expect(list[0].state, LevelState.current);
      expect(list.skip(1).every((x) => x.state == LevelState.locked), isTrue);
    });

    test('beating unlocks the next; failed replays never re-lock', () async {
      await beat(1, score: 800);
      await beat(2, score: 900);
      await beat(2, score: 300, beaten: false); // later worse run — latches

      final list = await container.read(adventureProvider.future);
      expect(list[0].state, LevelState.beaten);
      expect(list[0].best, 800);
      expect(list[1].state, LevelState.beaten); // flag latched
      expect(list[1].best, 900); // best kept
      expect(list[2].state, LevelState.current);
      expect(list[3].state, LevelState.locked);
    });
  });
}
