/// The board: an immutable row-major grid of digits, 9 wide, with cleared
/// cells kept in place as ghosts until their whole row collapses (§2, §3).
library;

import 'constants.dart';
import 'rng.dart';
import 'seed.dart';

/// A cell keeps a stable [id] across collapses — undo replay, hint highlights
/// and UI animations all address cells by id, never by shifting index.
class Cell {
  final int id;
  final int digit; // 1..9
  final bool cleared;
  const Cell({required this.id, required this.digit, this.cleared = false});
  Cell clear() => Cell(id: id, digit: digit, cleared: true);
}

class Board {
  /// Row-major, [kColumns] wide; the last row may be partial.
  final List<Cell> cells;
  const Board(this.cells);

  bool get isEmpty => cells.isEmpty;
  int get rowCount => (cells.length + kColumns - 1) ~/ kColumns;
  int rowOf(int i) => i ~/ kColumns;
  int colOf(int i) => i % kColumns;

  int? indexOfId(int id) {
    for (var i = 0; i < cells.length; i++) {
      if (cells[i].id == id) return i;
    }
    return null;
  }

  /// Value rule (§3.1): equal or sum to 10.
  bool valuesMatch(int i, int j) {
    final a = cells[i].digit, b = cells[j].digit;
    return a == b || a + b == 10;
  }

  /// Line of sight (§3.1): reading order (which covers same-row), same
  /// column, or either diagonal — with every intervening cell cleared.
  bool canSee(int i, int j) {
    if (i == j) return false;
    if (i > j) (i, j) = (j, i);

    // Reading order: all cells strictly between i and j cleared.
    var clear = true;
    for (var k = i + 1; k < j; k++) {
      if (!cells[k].cleared) {
        clear = false;
        break;
      }
    }
    if (clear) return true;

    final ri = rowOf(i), ci = colOf(i), rj = rowOf(j), cj = colOf(j);
    if (ci == cj) {
      // Column.
      clear = true;
      for (var r = ri + 1; r < rj; r++) {
        if (!cells[r * kColumns + ci].cleared) {
          clear = false;
          break;
        }
      }
      if (clear) return true;
    }

    final dr = rj - ri, dc = cj - ci;
    if (dr > 0 && dr == dc.abs()) {
      // Diagonal, either direction.
      final step = dc > 0 ? 1 : -1;
      clear = true;
      var r = ri + 1, c = ci + step;
      while (r < rj) {
        if (!cells[r * kColumns + c].cleared) {
          clear = false;
          break;
        }
        r++;
        c += step;
      }
      if (clear) return true;
    }
    return false;
  }

  bool canMatch(int i, int j) =>
      i >= 0 &&
      j >= 0 &&
      i < cells.length &&
      j < cells.length &&
      i != j &&
      !cells[i].cleared &&
      !cells[j].cleared &&
      valuesMatch(i, j) &&
      canSee(i, j);

  /// The forward visible-partner candidates of an uncleared cell i: the
  /// nearest uncleared cell in reading order, straight down, and down both
  /// diagonals. Every valid pair (i, j), i < j, has j in i's candidate set —
  /// visibility means "nearest uncleared along that line".
  Set<int> _forwardCandidates(int i) {
    final out = <int>{};
    for (var k = i + 1; k < cells.length; k++) {
      if (!cells[k].cleared) {
        out.add(k);
        break;
      }
    }
    final r0 = rowOf(i), c0 = colOf(i);
    void walk(int dr, int dc) {
      var r = r0 + dr, c = c0 + dc;
      while (r < rowCount && c >= 0 && c < kColumns) {
        final k = r * kColumns + c;
        if (k >= cells.length) break;
        if (!cells[k].cleared) {
          out.add(k);
          break;
        }
        r += dr;
        c += dc;
      }
    }

    walk(1, 0); // column down
    walk(1, 1); // diagonal ↘
    walk(1, -1); // diagonal ↙
    return out;
  }

  /// First valid pair in reading order (§3.5): smallest i, then smallest j.
  /// This is both the hint and the baseline bot's move.
  (int, int)? firstPair() {
    for (var i = 0; i < cells.length; i++) {
      if (cells[i].cleared) continue;
      int? best;
      for (final j in _forwardCandidates(i)) {
        if (valuesMatch(i, j) && (best == null || j < best)) best = j;
      }
      if (best != null) return (i, best);
    }
    return null;
  }

  int countAvailablePairs() {
    var n = 0;
    for (var i = 0; i < cells.length; i++) {
      if (cells[i].cleared) continue;
      for (final j in _forwardCandidates(i)) {
        if (valuesMatch(i, j)) n++;
      }
    }
    return n;
  }

  /// Clears two cells, then removes every fully-cleared row (§3.3).
  /// Returns the new board and the number of rows removed.
  (Board, int) matchAndCollapse(int i, int j) {
    final next = List<Cell>.of(cells);
    next[i] = next[i].clear();
    next[j] = next[j].clear();
    final kept = <Cell>[];
    var removed = 0;
    final rows = rowCount;
    for (var r = 0; r < rows; r++) {
      final start = r * kColumns;
      final end =
          (start + kColumns) < next.length ? (start + kColumns) : next.length;
      var allCleared = true;
      for (var k = start; k < end; k++) {
        if (!next[k].cleared) {
          allCleared = false;
          break;
        }
      }
      if (allCleared) {
        removed++;
      } else {
        kept.addAll(next.sublist(start, end));
      }
    }
    return (Board(kept), removed);
  }

  /// Nachlegen (§3.4): append a copy of all survivors in reading order.
  /// Fresh ids start at [nextId]; returns the new board and next free id.
  (Board, int) addSurvivors(int nextId) {
    final appended = List<Cell>.of(cells);
    var id = nextId;
    for (final c in cells) {
      if (!c.cleared) appended.add(Cell(id: id++, digit: c.digit));
    }
    return (Board(appended), id);
  }
}

/// Opening deal with the fairness gate (§2.2): PRNG state is
/// hash(seed, attempt); reroll deterministically until ≥ [kFairnessFloor]
/// pairs are available. Ids are 0..26 in reading order.
Board generateOpening(int engineSeed) {
  for (var attempt = 0;; attempt++) {
    final rng = SplitMix64(mixSeedAttempt(engineSeed, attempt));
    final cells = [
      for (var i = 0; i < kOpeningCells; i++) Cell(id: i, digit: rng.nextDigit()),
    ];
    final board = Board(cells);
    if (board.countAvailablePairs() >= kFairnessFloor) return board;
  }
}
