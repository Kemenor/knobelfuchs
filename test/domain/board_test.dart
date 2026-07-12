import 'package:flutter_test/flutter_test.dart';
import 'package:knobelfuchs/domain/board.dart';
import 'package:knobelfuchs/domain/constants.dart';
import 'package:knobelfuchs/domain/seed.dart';

import 'helpers.dart';

void main() {
  group('values', () {
    test('equal or sum to 10; 5-5 counts as both', () {
      final board = b('7 7 3 5 5 1 9 2 6');
      expect(board.valuesMatch(0, 1), isTrue); // 7-7
      expect(board.valuesMatch(2, 0), isTrue); // 3+7
      expect(board.valuesMatch(3, 4), isTrue); // 5-5
      expect(board.valuesMatch(5, 6), isTrue); // 1+9
      expect(board.valuesMatch(0, 7), isFalse); // 7,2
    });
  });

  group('line of sight', () {
    test('same row through cleared cells', () {
      final board = b('1 2c 9 4 5 6 7 8 3');
      expect(board.canMatch(0, 2), isTrue); // 1+9 over a ghost
      expect(board.canMatch(4, 6), isFalse); // 5,7 — no value match
    });

    test('blocked by an uncleared cell between', () {
      final board = b('1 2 9 4 5 6 7 8 3');
      expect(board.canMatch(0, 2), isFalse);
    });

    test('column through a cleared cell', () {
      final board = b('''
        5  1 1 1 1 1 1 1 2
        5c 1 1 1 1 1 1 1 2
        5  1 1 1 1 1 1 1 2
      ''');
      expect(board.canMatch(0, 18), isTrue); // column c0, ghost between
    });

    test('diagonals in both directions', () {
      final board = b('''
        7 1 1 1 1 1 1 1 4
        1 3c 1 1 1 1 1 2c 1
        1 1 3 1 1 1 6 1 1
      ''');
      expect(board.canMatch(0, 20), isTrue); // 7+3 ↘ over ghost at r1c1
      expect(board.canMatch(8, 24), isTrue); // 4+6 ↙ over ghost at r1c7
    });

    test('reading order wraps across the line break', () {
      final board = b('''
        1 1 1 1 1 1 1 2 6
        4 1 1 1 1 1 1 1 1
      ''');
      expect(board.canMatch(8, 9), isTrue); // 6+4 across the wrap

      final gapped = b('''
        1 1 1 1 1 1 1 2 6c
        8c 8 1 1 1 1 1 1 1
      ''');
      expect(gapped.canMatch(7, 10), isTrue); // 2+8 over ghosts across wrap
    });
  });

  group('firstPair & counting', () {
    test('single ascending row has no pairs', () {
      final board = b('1 2 3 4 5 6 7 8 9');
      expect(board.firstPair(), isNull);
      expect(board.countAvailablePairs(), 0);
    });

    test('first pair in reading order wins', () {
      final board = b('''
        1 2 3 4 5 6 7 8 9
        9 8 7 6 5 4 3 2 1
      ''');
      // From cell 0 (digit 1): column-down partner is cell 9 (digit 9) → 10.
      expect(board.firstPair(), (0, 9));
    });

    test('counts distinct visible pairs once', () {
      final board = b('5 5c 5 1 1 1 1 1 1');
      // (0,2) over the ghost + the five adjacent 1-1 pairs.
      expect(board.countAvailablePairs(), 6);
    });
  });

  group('matchAndCollapse', () {
    test('clearing the last survivors of a row removes it', () {
      final board = b('5 5c 5c 5c 5c 5c 5c 5c 5');
      final (next, removed) = board.matchAndCollapse(0, 8);
      expect(removed, 1);
      expect(next.isEmpty, isTrue);
    });

    test('one match can remove two rows at once', () {
      final board = b('''
        3 1c 1c 1c 1c 1c 1c 1c 1c
        7 1c 1c 1c 1c 1c 1c 1c 1c
      ''');
      final (next, removed) = board.matchAndCollapse(0, 9);
      expect(removed, 2);
      expect(next.isEmpty, isTrue);
    });

    test('ids survive a middle-row collapse', () {
      final board = b('''
        1 2 3 4 5 6 7 8 9
        4c 1c 1c 1c 1c 1c 1c 1c 6
        4 8 7 6 5 4 3 2 1
      ''');
      // 6 (id 17, end of row 1) + 4 (id 18, start of row 2), reading order.
      expect(board.canMatch(17, 18), isTrue);
      final (next, removed) = board.matchAndCollapse(17, 18);
      expect(removed, 1); // row 1 collapses
      expect(next.cells.length, 18);
      expect(next.cells[9].id, 18); // row 2 slid up, ids untouched
      expect(next.cells[9].cleared, isTrue); // it was half of the match
      expect(next.cells[0].id, 0);
    });
  });

  group('addSurvivors', () {
    test('appends a copy of survivors in reading order with fresh ids', () {
      final board = b('1 2c 3 4 5 6 7 8 9');
      final (next, nextId) = board.addSurvivors(100);
      expect(next.cells.length, 17);
      expect(nextId, 108);
      expect(
        [for (final c in next.cells.sublist(9)) c.digit],
        [1, 3, 4, 5, 6, 7, 8, 9],
      );
      expect(next.cells[9].id, 100);
      expect(next.cells[9].cleared, isFalse);
    });
  });

  group('generateOpening', () {
    test('is deterministic per seed', () {
      final a = generateOpening(seedHash('test'));
      final c = generateOpening(seedHash('test'));
      expect(digitsOf(a), digitsOf(c));
    });

    test('differs between seeds', () {
      expect(
        digitsOf(generateOpening(seedHash('fuchs'))),
        isNot(digitsOf(generateOpening(seedHash('hase')))),
      );
    });

    test('fairness gate: every opening has at least 3 pairs', () {
      for (var i = 0; i < 200; i++) {
        final board = generateOpening(seedHash('seed$i'));
        expect(board.cells.length, kOpeningCells);
        expect(board.countAvailablePairs(), greaterThanOrEqualTo(3),
            reason: 'seed$i');
      }
    });
  });
}
