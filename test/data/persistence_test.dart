import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knobelfuchs/data/action_codec.dart';
import 'package:knobelfuchs/data/database.dart';
import 'package:knobelfuchs/data/game_repository.dart';
import 'package:knobelfuchs/domain/game.dart';

void main() {
  group('action codec', () {
    test('roundtrips matches and adds', () {
      final actions = <GameAction>[
        MatchAction(3, 17),
        AddAction(),
        MatchAction(40, 2),
      ];
      final decoded = decodeActions(encodeActions(actions));
      expect(decoded.length, 3);
      expect((decoded[0] as MatchAction).aId, 3);
      expect((decoded[0] as MatchAction).bId, 17);
      expect(decoded[1], isA<AddAction>());
      expect((decoded[2] as MatchAction).bId, 2);
    });

    test('empty and garbage are safe', () {
      expect(decodeActions(''), isEmpty);
      expect(decodeActions('x;m:1;m:a:b;a').length, 1); // only the add survives
    });
  });

  group('GameState.replay', () {
    test('rebuilds the exact board, score, and budgets from the log', () {
      const config = GameConfig(seed: 'replay-test', adds: 5, hints: 5);
      final original = GameState.fresh(config);
      // Play a few deterministic moves.
      for (var i = 0; i < 3; i++) {
        final p = original.board.firstPair();
        if (p == null) break;
        original.match(
            original.board.cells[p.$1].id, original.board.cells[p.$2].id);
      }
      original.addRows();
      original.requestHint();

      final restored = GameState.replay(
        config,
        decodeActions(encodeActions(original.log)),
        hintsUsed: original.hintsUsed,
        activeHint: original.activeHint,
      );

      expect(restored.score, original.score);
      expect(restored.addsRemaining, original.addsRemaining);
      expect(restored.hintsRemaining, original.hintsRemaining);
      expect(restored.board.cells.length, original.board.cells.length);
      for (var i = 0; i < original.board.cells.length; i++) {
        expect(restored.board.cells[i].id, original.board.cells[i].id);
        expect(restored.board.cells[i].digit, original.board.cells[i].digit);
        expect(
            restored.board.cells[i].cleared, original.board.cells[i].cleared);
      }
      expect(restored.activeHint?.aId, original.activeHint?.aId);
      // Undo still works after restore — the log is the game.
      expect(restored.undo(), isTrue);
    });
  });

  group('repository', () {
    late AppDatabase db;
    late GameRepository repo;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = GameRepository(db);
    });

    tearDown(() => db.close());

    test('save → summary → load → replay roundtrip', () async {
      const config =
          GameConfig(seed: 'repo-test', adds: 5, hints: 5, target: 900);
      final state = GameState.fresh(config);
      final p = state.board.firstPair()!;
      state.match(state.board.cells[p.$1].id, state.board.cells[p.$2].id);
      state.requestHint();

      final started = DateTime(2026, 7, 12, 9);
      await repo.saveRun('free', RunSnapshot.of(state),
          startedAt: started, now: started);

      final summary = await repo.loadSummary('free');
      expect(summary!.score, state.score);
      expect(summary.seed, 'repo-test');

      final saved = await repo.loadRun('free');
      final restored = GameState.replay(
        saved!.config,
        saved.actions,
        hintsUsed: saved.hintsUsed,
        activeHint: saved.activeHint,
      );
      expect(restored.score, state.score);
      expect(restored.config.target, 900);
      expect(restored.hintsUsed, 1);
      expect(restored.activeHint, isNotNull);
      expect(saved.startedAt, started);
    });

    test('overwrite, clear, and absence', () async {
      const config = GameConfig(seed: 'a', adds: 5, hints: 5);
      final state = GameState.fresh(config);
      final t = DateTime(2026, 7, 12);
      await repo.saveRun('free', RunSnapshot.of(state), startedAt: t, now: t);
      await repo.saveRun('free', RunSnapshot.of(state),
          startedAt: t, now: t); // upsert
      expect(await repo.loadSummary('free'), isNotNull);
      await repo.clearRun('free');
      expect(await repo.loadSummary('free'), isNull);
      expect(await repo.loadRun('missing'), isNull);
    });

    test('results accumulate; best is a query', () async {
      const config = GameConfig(seed: 'best', adds: 0, hints: 0);
      final state = GameState.fresh(config);
      final t = DateTime(2026, 7, 12);
      await repo.recordResult('free', RunSnapshot.of(state),
          startedAt: t, endedAt: t);
      final p = state.board.firstPair()!;
      state.match(state.board.cells[p.$1].id, state.board.cells[p.$2].id);
      await repo.recordResult('free', RunSnapshot.of(state),
          startedAt: t, endedAt: t.add(const Duration(minutes: 1)));
      expect(await repo.bestScore('free', 'best'), state.score);
      expect(await repo.bestScore('free', 'other'), isNull);
    });

    test('commitRunEnd is atomic: result + cleared slot land together',
        () async {
      const config = GameConfig(seed: 'end', adds: 5, hints: 5);
      final state = GameState.fresh(config);
      final t = DateTime(2026, 7, 12);
      await repo.saveRun('free', RunSnapshot.of(state), startedAt: t, now: t);
      await repo.commitRunEnd('free', RunSnapshot.of(state),
          startedAt: t,
          endedAt: t.add(const Duration(minutes: 2)),
          clear: true);
      // Result recorded, autosave slot cleared — one transaction (§3.7).
      expect(await repo.bestScore('free', 'end'), state.score);
      expect(await repo.loadSummary('free'), isNull);
    });

    test('a snapshot is immune to later mutations of the live state',
        () async {
      const config = GameConfig(seed: 'snap', adds: 5, hints: 5);
      final state = GameState.fresh(config);
      final p = state.board.firstPair()!;
      state.match(state.board.cells[p.$1].id, state.board.cells[p.$2].id);
      final snap = RunSnapshot.of(state);
      final scoreAtCapture = state.score;
      state.undo(); // player undoes while the write chain is still queued
      final t = DateTime(2026, 7, 12);
      await repo.saveRun('free', snap, startedAt: t, now: t);
      expect((await repo.loadSummary('free'))!.score, scoreAtCapture);
    });
  });
}
