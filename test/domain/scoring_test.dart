import 'package:flutter_test/flutter_test.dart';
import 'package:knobelfuchs/domain/board.dart';
import 'package:knobelfuchs/domain/constants.dart';
import 'package:knobelfuchs/domain/game.dart';

import 'helpers.dart';

void main() {
  GameState onBoard(String spec, ScoringVariant scoring, {int? adds = 5}) =>
      GameState.forBoard(
        GameConfig(seed: 'x', adds: adds, hints: 5, scoring: scoring),
        b(spec),
      );

  group('scoring variants (playtest switch)', () {
    test('classic: pair + stacking rows', () {
      final s = onBoard('5 5c 5c 5c 5c 5c 5c 5c 5', ScoringVariant.classic);
      s.match(0, 8);
      // pair 10 + row 50 + clear 250 + 5 unused adds × 50
      expect(s.score, 10 + 50 + 250 + 250);
    });

    test('originalsOnly: opening cells pay, copies and rows do not', () {
      // Two originals (ids < kOpeningCells) + row clear.
      final a = onBoard('5 5c 5c 5c 5c 5c 5c 5c 5', ScoringVariant.originalsOnly);
      a.match(0, 8);
      // 2 original cells × 10, no row bonus, + clear 250 + unused 250
      expect(a.score, 20 + 250 + 250);

      // A pair of copies (ids ≥ kOpeningCells) pays nothing.
      final board = b('5 5 1 2 3 4 6 7 8'); // ids 0..8 — rebuild with big ids
      final copies = GameState.forBoard(
        const GameConfig(
            seed: 'x', adds: 5, hints: 5,
            scoring: ScoringVariant.originalsOnly),
        Board([
          for (final c in board.cells)
            Cell(id: c.id + kOpeningCells, digit: c.digit),
        ]),
      );
      copies.match(kOpeningCells, kOpeningCells + 1); // the 5-5 pair
      expect(copies.score, 0); // helpers, not loot (no clear: row survives)
    });

    test('addCosts: an add charges the pair-value it deals', () {
      final s = onBoard('5 5 1 2 3 4 6 7 8', ScoringVariant.addCosts);
      s.match(0, 1); // +10
      expect(s.score, 10);
      s.addRows(); // 7 survivors → 3 pairs' worth = −35 → wait: (7×10)~/2 = 35
      expect(s.score, 10 - 35);
    });

    test('decayingPairs: each add makes pairs cheaper', () {
      final s = onBoard('5 5 1 1 6 4 9 3 8', ScoringVariant.decayingPairs);
      s.match(0, 1); // no adds yet → +10
      expect(s.score, 10);
      s.addRows();
      s.addRows();
      final p = s.board.firstPair()!;
      final before = s.score;
      s.match(s.board.cells[p.$1].id, s.board.cells[p.$2].id);
      expect(s.score - before, 10 - 2 * 2); // 2 adds used → pairs worth 6
    });

    test('variant survives save/replay determinism', () {
      const config = GameConfig(
          seed: 'variant-replay', adds: 5, hints: 5,
          scoring: ScoringVariant.decayingPairs);
      final s = GameState.fresh(config);
      s.addRows();
      final p = s.board.firstPair()!;
      s.match(s.board.cells[p.$1].id, s.board.cells[p.$2].id);
      final replayed = GameState.replay(config, s.log);
      expect(replayed.score, s.score);
    });
  });
}
