import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knobelfuchs/data/database.dart';
import 'package:knobelfuchs/ui/daily/daily_providers.dart';
import 'package:knobelfuchs/ui/providers.dart';

void main() {
  group('dailyMonthProvider', () {
    late AppDatabase db;
    late ProviderContainer container;
    final fixedNow = DateTime(2026, 7, 15, 14, 30);

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        nowProvider.overrideWithValue(() => fixedNow),
      ]);
    });

    tearDown(() {
      container.dispose();
    });

    test('maps day states from saved runs and results', () async {
      final t = DateTime(2026, 7, 1);
      // 1 July: beaten result.
      await db.into(db.runResults).insert(RunResultsCompanion.insert(
            slot: 'daily:20260701',
            seed: 'daily:20260701',
            score: 900,
            cleared: true,
            targetBeaten: true,
            pairs: 30,
            rows: 5,
            addsUsed: 2,
            hintsUsed: 1,
            durationMs: 60000,
            startedAt: t,
            endedAt: t,
          ));
      // 3 July: half-finished autosave.
      await db.into(db.savedRuns).insert(SavedRunsCompanion.insert(
            slot: 'daily:20260703',
            seed: 'daily:20260703',
            actions: 'm:0:1',
            hintsUsed: 0,
            scoreCache: 320,
            startedAt: t,
            updatedAt: t,
          ));
      // 5 July: played, target open.
      await db.into(db.runResults).insert(RunResultsCompanion.insert(
            slot: 'daily:20260705',
            seed: 'daily:20260705',
            score: 700,
            cleared: false,
            targetBeaten: false,
            pairs: 20,
            rows: 3,
            addsUsed: 5,
            hintsUsed: 5,
            durationMs: 60000,
            startedAt: t,
            endedAt: t,
          ));

      final info =
          await container.read(dailyMonthProvider(DateTime(2026, 7, 1)).future);

      expect(info.days.length, 31);
      DayInfo day(int d) => info.days[d - 1];

      expect(day(1).state, DayState.beaten);
      expect(day(1).score, 900);
      expect(day(3).state, DayState.inProgress);
      expect(day(3).score, 320);
      expect(day(5).state, DayState.played);
      expect(day(5).score, 700);
      expect(day(10).state, DayState.waiting); // waits — never a reproach
      expect(day(15).state, DayState.waiting); // today, playable
      expect(day(16).state, DayState.locked); // tomorrow — device-date lock
      expect(day(31).state, DayState.locked);
    });

    test('beaten latches even when a later run scores lower', () async {
      final t = DateTime(2026, 7, 2);
      Future<void> insert(int score, bool beaten) =>
          db.into(db.runResults).insert(RunResultsCompanion.insert(
                slot: 'daily:20260702',
                seed: 'daily:20260702',
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
      await insert(800, true); // beat it once
      await insert(950, false); // later replay: better score, target missed

      final info =
          await container.read(dailyMonthProvider(DateTime(2026, 7, 1)).future);
      final day = info.days[1];
      expect(day.state, DayState.beaten); // the flag latches (§6.3 semantics)
      expect(day.score, 950); // best score still shown
    });
  });
}
