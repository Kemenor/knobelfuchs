import 'package:flutter_test/flutter_test.dart';
import 'package:knobelfuchs/domain/constants.dart';
import 'package:knobelfuchs/domain/game.dart';

import 'helpers.dart';

void main() {
  GameState fresh({int? adds = 5, int? hints = 5, int? target}) =>
      GameState.fresh(GameConfig(
          seed: 'game-test', adds: adds, hints: hints, target: target));

  (int, int) firstIds(GameState s) {
    final p = s.board.firstPair()!;
    return (s.board.cells[p.$1].id, s.board.cells[p.$2].id);
  }

  group('fresh state', () {
    test('opens with 35 cells, full budgets, playing', () {
      final s = fresh();
      expect(s.board.cells.length, kOpeningCells);
      expect(s.addsRemaining, 5);
      expect(s.hintsRemaining, 5);
      expect(s.score, 0);
      expect(s.status, GameStatus.playing);
    });
  });

  group('match', () {
    test('valid match scores and logs', () {
      final s = fresh();
      final (a, bId) = firstIds(s);
      expect(s.match(a, bId), isTrue);
      expect(s.score, greaterThanOrEqualTo(kPointsPerPair));
      expect(s.pairsMatched, 1);
      expect(s.log.length, 1);
    });

    test('invalid match changes nothing', () {
      final s = fresh();
      expect(s.match(999, 1000), isFalse);
      expect(s.match(0, 0), isFalse);
      expect(s.score, 0);
      expect(s.log, isEmpty);
    });
  });

  group('adds', () {
    test('budget counts down and blocks at zero', () {
      final s = fresh(adds: 2);
      expect(s.addRows(), isTrue);
      expect(s.addRows(), isTrue);
      expect(s.addsRemaining, 0);
      expect(s.addRows(), isFalse);
    });

    test('limitless adds never block', () {
      final s = fresh(adds: null);
      for (var i = 0; i < 6; i++) {
        expect(s.addRows(), isTrue);
      }
      expect(s.addsRemaining, isNull);
    });

    test('add appends a full copy of survivors', () {
      final s = fresh();
      final before = s.board.cells.length;
      s.addRows();
      expect(s.board.cells.length, before * 2);
    });
  });

  group('undo', () {
    test('is a true rewind: board, score, and add budget', () {
      final s = fresh();
      final openingDigits = digitsOf(s.board);
      final (a, bId) = firstIds(s);
      s.match(a, bId);
      final afterMatchScore = s.score;
      final afterMatchDigits = digitsOf(s.board);

      s.addRows();
      expect(s.addsRemaining, 4);

      expect(s.undo(), isTrue); // undoes the add
      expect(s.addsRemaining, 5); // refunded
      expect(digitsOf(s.board), afterMatchDigits);
      expect(s.score, afterMatchScore);

      expect(s.undo(), isTrue); // undoes the match
      expect(s.score, 0);
      expect(digitsOf(s.board), openingDigits);
      expect(s.log, isEmpty);

      expect(s.undo(), isFalse); // opening position
    });

    test('hints are outside the log: not undone, not refunded', () {
      final s = fresh();
      s.requestHint();
      expect(s.hintsUsed, 1);
      final (a, bId) = firstIds(s);
      s.match(a, bId);
      s.undo();
      expect(s.hintsUsed, 1); // survives the rewind
    });
  });

  group('hints', () {
    test('consumes only on new information; re-pulse is free', () {
      final s = fresh(hints: 2);
      expect(s.requestHint(), HintOutcome.shown);
      expect(s.hintsUsed, 1);
      expect(s.requestHint(), HintOutcome.repulsed);
      expect(s.hintsUsed, 1);

      final hint = s.activeHint!;
      s.releaseHintCell(hint.aId);
      expect(s.activeHint, isNotNull); // partner still orange
      s.releaseHintCell(hint.bId);
      expect(s.activeHint, isNull); // both tapped

      expect(s.requestHint(), HintOutcome.shown);
      expect(s.hintsUsed, 2);
      s.releaseHintCell(s.activeHint!.aId);
      s.releaseHintCell(s.activeHint!.bId);
      expect(s.requestHint(), HintOutcome.exhausted);
      expect(s.hintsUsed, 2);
    });

    test('no pair on the board: free honesty', () {
      final s = GameState.forBoard(
        const GameConfig(seed: 'x', adds: 5, hints: 5),
        b('1 2 3 4 5 6 7 8 9'),
      );
      expect(s.requestHint(), HintOutcome.nonePossible);
      expect(s.hintsUsed, 0);
    });

    test('matching the hinted pair drops the highlight', () {
      final s = GameState.forBoard(
        const GameConfig(seed: 'x', adds: 5, hints: 5),
        b('5 5 1 1 6 4 9 3 8'),
      );
      s.requestHint();
      final hint = s.activeHint!;
      s.match(hint.aId, hint.bId);
      expect(s.activeHint, isNull);
    });

    test('unrelated match keeps a still-valid highlight', () {
      final s = GameState.forBoard(
        const GameConfig(seed: 'x', adds: 5, hints: 5),
        b('5 5 1 1 6 4 9 3 8'),
      );
      s.requestHint(); // hints (5,5) — ids 0,1
      expect(s.activeHint!.aId, 0);
      s.match(2, 3); // the 1-1 pair
      expect(s.activeHint, isNotNull);
    });
  });

  group('run end (§3.7)', () {
    test('stuck = no pair and no adds; adds left = still playing', () {
      final stuck = GameState.forBoard(
        const GameConfig(seed: 'x', adds: 0, hints: 5),
        b('1 2 3 4 5 6 7 8 9'),
      );
      expect(stuck.status, GameStatus.stuck);

      final playing = GameState.forBoard(
        const GameConfig(seed: 'x', adds: 1, hints: 5),
        b('1 2 3 4 5 6 7 8 9'),
      );
      expect(playing.status, GameStatus.playing);
    });

    test('clearing the board pays clear + unused-add bonuses', () {
      final s = GameState.forBoard(
        const GameConfig(seed: 'x', adds: 5, hints: 5, target: 500),
        b('5 5c 5c 5c 5c 5c 5c 5c 5'),
      );
      expect(s.match(0, 8), isTrue);
      expect(s.status, GameStatus.cleared);
      // originalsOnly default: 2 opening cells × 10 (rows pay nothing)
      // + clear 250 + 5 unused adds × 50
      expect(s.score, 20 + 250 + 250);
      expect(s.targetBeaten, isTrue);
    });

    test('limitless adds earn no unused-add bonus', () {
      final s = GameState.forBoard(
        const GameConfig(seed: 'x', adds: null, hints: 5),
        b('5 5c 5c 5c 5c 5c 5c 5c 5'),
      );
      s.match(0, 8);
      expect(s.score, 20 + 250);
    });
  });
}
