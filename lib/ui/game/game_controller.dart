import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../data/game_repository.dart';
import '../../domain/board.dart';
import '../../domain/game.dart';

/// Free Form's single run slot (§6.1); daily/adventure get their own keys.
const String kFreeSlot = 'free';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final gameRepositoryProvider =
    Provider<GameRepository>((ref) => GameRepository(ref.watch(databaseProvider)));

/// The autosaved Free Form run, for the home card. Bumped after every
/// controller persist.
final savedFreeRunProvider = FutureProvider<SavedRunSummary?>(
  (ref) => ref.watch(gameRepositoryProvider).loadSummary(kFreeSlot),
);

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
  DateTime _startedAt = DateTime.now();

  @override
  GameView? build() => null;

  GameRepository get _repo => ref.read(gameRepositoryProvider);

  void start(GameConfig config) {
    _game = GameState.fresh(config);
    _selectedId = null;
    _startedAt = DateTime.now();
    _publish();
    _persist(GameStatus.playing);
  }

  /// Rebuild the autosaved run from its move log (§3.7: every move durable).
  Future<bool> resumeSaved() async {
    final saved = await _repo.loadRun(kFreeSlot);
    if (saved == null) return false;
    _game = GameState.replay(
      saved.config,
      saved.actions,
      hintsUsed: saved.hintsUsed,
      activeHint: saved.activeHint,
    );
    _selectedId = null;
    _startedAt = saved.startedAt;
    _publish();
    return true;
  }

  /// Leave the game for good (run-end "Zum Menü") — the slot is cleared;
  /// the result was already recorded at run end.
  Future<void> quit() async {
    _game = null;
    _selectedId = null;
    _publish();
    await _repo.clearRun(kFreeSlot);
    ref.invalidate(savedFreeRunProvider);
  }

  /// Tap-tap interaction (§3.2): select → match-or-move-selection → deselect.
  /// Taps on ghosts do nothing; every tap on a hinted cell releases its orange.
  void tapCell(int id) {
    final game = _game;
    if (game == null) return;
    final idx = game.board.indexOfId(id);
    if (idx == null || game.board.cells[idx].cleared) return;
    final before = game.status;

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
    _persist(before);
  }

  bool addRows() {
    final game = _game;
    if (game == null) return false;
    final before = game.status;
    final ok = game.addRows();
    _publish();
    if (ok) _persist(before);
    return ok;
  }

  HintOutcome requestHint() {
    final game = _game;
    if (game == null) return HintOutcome.nonePossible;
    final before = game.status;
    final outcome = game.requestHint();
    _publish();
    if (outcome == HintOutcome.shown) _persist(before);
    return outcome;
  }

  bool undo() {
    final game = _game;
    if (game == null) return false;
    final before = game.status;
    final ok = game.undo();
    if (ok) {
      _selectedId = null;
      _publish();
      _persist(before);
    }
    return ok;
  }

  /// Autosave + commit results on the playing→ended transition (§3.7).
  /// Fire-and-forget, but internally ordered.
  void _persist(GameStatus before) {
    final game = _game;
    if (game == null) return;
    final now = DateTime.now();
    final after = game.status;
    final startedAt = _startedAt;

    Future<void> run() async {
      await _repo.saveRun(kFreeSlot, game, startedAt: startedAt, now: now);
      if (before == GameStatus.playing && after != GameStatus.playing) {
        await _repo.recordResult(kFreeSlot, game,
            startedAt: startedAt, endedAt: now);
        if (after == GameStatus.cleared) {
          // No way back into a cleared board — the slot is done (§3.7).
          await _repo.clearRun(kFreeSlot);
        }
      }
      ref.invalidate(savedFreeRunProvider);
    }

    run();
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
