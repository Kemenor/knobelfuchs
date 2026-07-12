/// Game state: budgets, score, the move log (undo = replay), hints (§3).
/// Pure Dart — no I/O, no clock, no Flutter.
library;

import 'board.dart';
import 'constants.dart';
import 'seed.dart';

/// Playtest scoring variants (family session 2026-07-12): the classic
/// formula rewards add-spam — every add doubles the material and pairs score
/// flat +10, so volume swamps every fixed bonus. Four candidate fixes ship
/// behind a settings switch until the family picks one.
enum ScoringVariant {
  /// The grilled formula: pair +10, row +50, clear +250, unused add +50.
  classic,

  /// Only cleared cells from the opening score (+10 each; copies are
  /// helpers, not loot). Rows chime but score 0. Fixed ceiling per board.
  originalsOnly,

  /// Classic, but each Nachlegen costs the pair-value it deals
  /// (−10 per appended pair) — volume becomes point-neutral.
  addCosts,

  /// Classic, but each add used makes every later pair 2 points cheaper
  /// (10 → 8 → 6 → …, floor 0).
  decayingPairs,
}

/// One struct for all three modes and the QR payload (§6, §7).
class GameConfig {
  /// Normalized user seed (§2.1), or an internal key like `daily:20260712`.
  final String seed;

  /// Add budget; null = limitless.
  final int? adds;

  /// Hint budget; null = limitless.
  final int? hints;

  /// Score to beat; null = off.
  final int? target;

  /// Locked in at game start; replay/undo depend on it. **originalsOnly is
  /// the fixed formula** (family decision 2026-07-12) — the other variants
  /// remain implemented for future playtests.
  final ScoringVariant scoring;

  const GameConfig({
    required this.seed,
    this.adds = kDefaultAdds,
    this.hints = kDefaultHints,
    this.target,
    this.scoring = ScoringVariant.originalsOnly,
  });

  int get engineSeed => seedHash(seed);

  /// Adventure levels keep the raw uniform deal (skew = curation material);
  /// everything else deals from the balanced bag (§2.2). Derived from the
  /// seed namespace so replay/QR need no extra field.
  bool get balancedDeal => !seed.startsWith('level:');

  GameConfig withTarget(int? target) => GameConfig(
      seed: seed, adds: adds, hints: hints, target: target, scoring: scoring);
}

sealed class GameAction {}

class MatchAction extends GameAction {
  final int aId, bId;
  MatchAction(this.aId, this.bId);
}

class AddAction extends GameAction {}

enum GameStatus {
  playing,

  /// Board empty — the crowning finish. Final (§3.7).
  cleared,

  /// No valid pair and adds exhausted — auto-detected; undo-back-in allowed.
  stuck,
}

enum HintOutcome {
  /// A new pair was highlighted; one hint consumed.
  shown,

  /// The active highlight was re-pulsed; free (§3.5).
  repulsed,

  /// No valid pair exists on the board; free — points at Nachlegen.
  nonePossible,

  /// Budget exhausted.
  exhausted,
}

/// The sticky orange pair (§3.5): each cell releases its own highlight when
/// tapped; the highlight re-validates after every board change.
class ActiveHint {
  final int aId, bId;
  bool aReleased = false, bReleased = false;
  ActiveHint(this.aId, this.bId);

  bool get fullyReleased => aReleased && bReleased;
  bool involves(int id) => id == aId || id == bId;
  bool isReleased(int id) => id == aId ? aReleased : bReleased;

  void release(int id) {
    if (id == aId) aReleased = true;
    if (id == bId) bReleased = true;
  }
}

class GameState {
  final GameConfig config;
  Board board;
  int score = 0;
  int pairsMatched = 0;
  int rowsCleared = 0;
  int hintsUsed = 0; // outside the move log — never undone (§3.6)
  ActiveHint? activeHint;

  final List<GameAction> _log = [];
  int _nextId;

  GameState.fresh(this.config)
      : board = generateOpening(config.engineSeed,
            balanced: config.balancedDeal),
        _nextId = 0 {
    _nextId = board.cells.length;
  }

  /// Start from a crafted board — for tests. Undo replays from the *seeded*
  /// opening, so states built this way must not undo past their own moves.
  GameState.forBoard(this.config, this.board) : _nextId = 0 {
    for (final c in board.cells) {
      if (c.id >= _nextId) _nextId = c.id + 1;
    }
  }

  /// Restore a saved run: the move log deterministically rebuilds the exact
  /// board from the seeded opening (same maths on every device). Invalid
  /// actions in a corrupt log are skipped silently — the game stays playable.
  factory GameState.replay(
    GameConfig config,
    List<GameAction> actions, {
    int hintsUsed = 0,
    ActiveHint? activeHint,
  }) {
    final state = GameState.fresh(config);
    state._rebuild(actions);
    state.hintsUsed = hintsUsed;
    state.activeHint = activeHint;
    state._revalidateHint();
    return state;
  }

  List<GameAction> get log => List.unmodifiable(_log);
  int get addsUsed => _log.whereType<AddAction>().length;
  int? get addsRemaining => config.adds == null ? null : config.adds! - addsUsed;
  int? get hintsRemaining =>
      config.hints == null ? null : config.hints! - hintsUsed;

  GameStatus get status {
    if (board.isEmpty) return GameStatus.cleared;
    if (board.firstPair() == null && addsRemaining == 0) {
      return GameStatus.stuck;
    }
    return GameStatus.playing;
  }

  bool get targetBeaten => config.target != null && score >= config.target!;

  /// Match two cells by id. Returns false (and changes nothing) if invalid.
  bool match(int aId, int bId) {
    if (!_applyMatch(aId, bId)) return false;
    _log.add(MatchAction(aId, bId));
    _revalidateHint();
    return true;
  }

  /// Nachlegen. Returns false if the budget is exhausted or the game is over.
  bool addRows() {
    if (!_applyAdd()) return false;
    _log.add(AddAction());
    _revalidateHint();
    return true;
  }

  /// True rewind of the last match or add (§3.6); hints are untouched.
  bool undo() {
    if (_log.isEmpty) return false;
    _rebuild(_log.sublist(0, _log.length - 1));
    _revalidateHint();
    return true;
  }

  /// Reset to the seeded opening and re-apply [actions] in order.
  void _rebuild(List<GameAction> actions) {
    board = generateOpening(config.engineSeed, balanced: config.balancedDeal);
    _nextId = board.cells.length;
    score = 0;
    pairsMatched = 0;
    rowsCleared = 0;
    _log.clear();
    for (final action in actions) {
      switch (action) {
        case MatchAction(:final aId, :final bId):
          if (_applyMatch(aId, bId)) _log.add(action);
        case AddAction():
          if (_applyAdd()) _log.add(action);
      }
    }
  }

  /// §3.5 — deterministic, consumption only on new information.
  HintOutcome requestHint() {
    if (activeHint != null) return HintOutcome.repulsed;
    final pair = board.firstPair();
    if (pair == null) return HintOutcome.nonePossible;
    if (hintsRemaining == 0) return HintOutcome.exhausted;
    hintsUsed++;
    activeHint =
        ActiveHint(board.cells[pair.$1].id, board.cells[pair.$2].id);
    return HintOutcome.shown;
  }

  /// UI calls this when a highlighted cell is tapped (§3.5).
  void releaseHintCell(int cellId) {
    final hint = activeHint;
    if (hint == null || !hint.involves(cellId)) return;
    hint.release(cellId);
    if (hint.fullyReleased) activeHint = null;
  }

  bool _applyMatch(int aId, int bId) {
    final i = board.indexOfId(aId), j = board.indexOfId(bId);
    if (i == null || j == null || !board.canMatch(i, j)) return false;
    final (next, removedRows) = board.matchAndCollapse(i, j);
    board = next;
    pairsMatched++;
    rowsCleared += removedRows;
    score += switch (config.scoring) {
      ScoringVariant.classic ||
      ScoringVariant.addCosts =>
        kPointsPerPair + removedRows * kPointsPerRow,
      ScoringVariant.decayingPairs =>
        (kPointsPerPair - 2 * addsUsed).clamp(0, kPointsPerPair) +
            removedRows * kPointsPerRow,
      // Copies are helpers, not loot: only opening cells score; rows chime
      // but pay nothing.
      ScoringVariant.originalsOnly =>
        (aId < kOpeningCells ? kPointsPerPair : 0) +
            (bId < kOpeningCells ? kPointsPerPair : 0),
    };
    if (board.isEmpty) {
      score += kPointsBoardCleared;
      // Unused-add bonus only on a cleared board (§4); a limitless budget
      // earns no bonus — there was nothing to conserve.
      final remaining = config.adds == null ? 0 : config.adds! - addsUsed;
      score += remaining * kPointsPerUnusedAdd;
    }
    return true;
  }

  bool _applyAdd() {
    if (board.isEmpty) return false;
    final remaining = addsRemaining;
    if (remaining != null && remaining <= 0) return false;
    final survivors =
        board.cells.where((c) => !c.cleared).length;
    final (next, nextId) = board.addSurvivors(_nextId);
    board = next;
    _nextId = nextId;
    if (config.scoring == ScoringVariant.addCosts) {
      // The add deals survivors/2 potential pairs — charge their value so
      // volume is point-neutral. May go negative; that's honest math.
      score -= (survivors * kPointsPerPair) ~/ 2;
    }
    return true;
  }

  /// Drop the highlight as soon as it stops pointing at a real move (§3.5).
  void _revalidateHint() {
    final hint = activeHint;
    if (hint == null) return;
    final i = board.indexOfId(hint.aId), j = board.indexOfId(hint.bId);
    final aAlive = i != null && !board.cells[i].cleared;
    final bAlive = j != null && !board.cells[j].cleared;
    if (!hint.aReleased && !aAlive) {
      activeHint = null;
      return;
    }
    if (!hint.bReleased && !bAlive) {
      activeHint = null;
      return;
    }
    // Both still unreleased → the pair itself must still be matchable.
    if (!hint.aReleased && !hint.bReleased && !board.canMatch(i!, j!)) {
      activeHint = null;
    }
  }
}
