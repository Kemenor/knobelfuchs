import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/board.dart';
import '../../domain/game.dart';

/// Immutable snapshot of the running game for the UI. The mutable [GameState]
/// lives inside the controller; every mutation publishes a fresh view.
class GameView {
  final GameConfig config;
  final Board board;
  final int score;
  final GameStatus status;
  final int? addsRemaining; // null = ∞
  final int? hintsRemaining; // null = ∞
  final int addsUsed;
  final int hintsUsed;
  final int pairsMatched;
  final int rowsCleared;
  final int? selectedId;
  final Set<int> hintCellIds; // unreleased hinted cells (sticky orange)
  final bool targetBeaten;

  const GameView({
    required this.config,
    required this.board,
    required this.score,
    required this.status,
    required this.addsRemaining,
    required this.hintsRemaining,
    required this.addsUsed,
    required this.hintsUsed,
    required this.pairsMatched,
    required this.rowsCleared,
    required this.selectedId,
    required this.hintCellIds,
    required this.targetBeaten,
  });
}

final gameControllerProvider =
    NotifierProvider<GameController, GameView?>(GameController.new);

class GameController extends Notifier<GameView?> {
  GameState? _game;
  int? _selectedId;

  @override
  GameView? build() => null;

  bool get hasGame => _game != null;

  void start(GameConfig config) {
    _game = GameState.fresh(config);
    _selectedId = null;
    _publish();
  }

  void quit() {
    _game = null;
    _selectedId = null;
    _publish();
  }

  /// Tap-tap interaction (§3.2): select → match-or-move-selection → deselect.
  /// Taps on ghosts do nothing; every tap on a hinted cell releases its orange.
  void tapCell(int id) {
    final game = _game;
    if (game == null) return;
    final idx = game.board.indexOfId(id);
    if (idx == null || game.board.cells[idx].cleared) return;

    game.releaseHintCell(id);

    final selected = _selectedId;
    if (selected == null) {
      _selectedId = id;
    } else if (selected == id) {
      _selectedId = null;
    } else {
      final selectedIdx = game.board.indexOfId(selected);
      if (selectedIdx != null && game.board.canMatch(selectedIdx, idx)) {
        game.match(selected, id);
        _selectedId = null;
      } else {
        // Never an error — the selection simply moves (§3.2).
        _selectedId = id;
      }
    }
    _publish();
  }

  bool addRows() {
    final ok = _game?.addRows() ?? false;
    _publish();
    return ok;
  }

  HintOutcome requestHint() {
    final outcome = _game?.requestHint() ?? HintOutcome.nonePossible;
    _publish();
    return outcome;
  }

  bool undo() {
    final ok = _game?.undo() ?? false;
    if (ok) _selectedId = null;
    _publish();
    return ok;
  }

  void _publish() {
    final game = _game;
    if (game == null) {
      state = null;
      return;
    }
    // Selection can be orphaned by collapse/undo — drop it silently.
    final sel = _selectedId;
    if (sel != null) {
      final idx = game.board.indexOfId(sel);
      if (idx == null || game.board.cells[idx].cleared) _selectedId = null;
    }
    final hint = game.activeHint;
    state = GameView(
      config: game.config,
      board: game.board,
      score: game.score,
      status: game.status,
      addsRemaining: game.addsRemaining,
      hintsRemaining: game.hintsRemaining,
      addsUsed: game.addsUsed,
      hintsUsed: game.hintsUsed,
      pairsMatched: game.pairsMatched,
      rowsCleared: game.rowsCleared,
      selectedId: _selectedId,
      hintCellIds: {
        if (hint != null && !hint.aReleased) hint.aId,
        if (hint != null && !hint.bReleased) hint.bId,
      },
      targetBeaten: game.targetBeaten,
    );
  }
}
