import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/board.dart';
import '../../domain/game.dart';
import '../providers.dart';

export '../providers.dart'
    show kFreeSlot, databaseProvider, gameRepositoryProvider, savedFreeRunProvider;

/// Immutable snapshot of the running game for the UI. The mutable [GameState]
/// lives inside the controller; every mutation publishes a fresh view.
class GameView {
  final GameConfig config;
  final String slot; // 'free' | 'daily:yyyymmdd' | 'level:N'
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
  final Set<int> justMatchedIds; // emerald flash before ghosting (mockup 07)
  final Set<int> digitsPresent; // legend: which of 1–9 still survive
  final bool targetBeaten;

  const GameView({
    required this.config,
    required this.slot,
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
    required this.justMatchedIds,
    required this.digitsPresent,
    required this.targetBeaten,
  });

  bool get isDaily => slot.startsWith('daily:');
  bool get isAdventure => slot.startsWith('level:');
  int? get adventureLevel =>
      isAdventure ? int.tryParse(slot.substring('level:'.length)) : null;
}

final gameControllerProvider =
    NotifierProvider<GameController, GameView?>(GameController.new);

class GameController extends Notifier<GameView?> {
  GameState? _game;
  String _slot = kFreeSlot;
  int? _selectedId;
  Set<int> _justMatched = const {};
  DateTime _startedAt = DateTime.now();

  @override
  GameView? build() => null;

  void start(GameConfig config, {String slot = kFreeSlot}) {
    _game = GameState.fresh(config);
    _slot = slot;
    _selectedId = null;
    _startedAt = DateTime.now();
    _publish();
    _persist(GameStatus.playing);
  }

  /// Rebuild an autosaved run from its move log (§3.7: every move durable).
  Future<bool> resumeSaved({String slot = kFreeSlot}) async {
    final saved = await ref.read(gameRepositoryProvider).loadRun(slot);
    if (saved == null) return false;
    _game = GameState.replay(
      saved.config,
      saved.actions,
      hintsUsed: saved.hintsUsed,
      activeHint: saved.activeHint,
    );
    _slot = slot;
    _selectedId = null;
    _startedAt = saved.startedAt;
    _publish();
    return true;
  }

  /// Leave the game for good (run-end "Zum Menü") — the slot is cleared;
  /// the result was already recorded at run end.
  Future<void> quit() async {
    final slot = _slot;
    _game = null;
    _selectedId = null;
    _publish();
    await ref.read(gameRepositoryProvider).clearRun(slot);
    _invalidate(slot);
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
        _flashMatched({selected, id});
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
      _justMatched = const {};
      _publish();
      _persist(before);
    }
    return ok;
  }

  /// Mockup 07: matched cells pop emerald, then fade to ghosts.
  void _flashMatched(Set<int> ids) {
    _justMatched = ids;
    Future.delayed(const Duration(milliseconds: 320), () {
      if (_justMatched == ids) {
        _justMatched = const {};
        _publish();
      }
    });
  }

  /// Autosave + commit results on the playing→ended transition (§3.7).
  /// Fire-and-forget, but internally ordered.
  void _persist(GameStatus before) {
    final game = _game;
    if (game == null) return;
    final repo = ref.read(gameRepositoryProvider);
    final slot = _slot;
    final now = DateTime.now();
    final after = game.status;
    final startedAt = _startedAt;

    Future<void> run() async {
      await repo.saveRun(slot, game, startedAt: startedAt, now: now);
      if (before == GameStatus.playing && after != GameStatus.playing) {
        await repo.recordResult(slot, game, startedAt: startedAt, endedAt: now);
        if (after == GameStatus.cleared) {
          // No way back into a cleared board — the slot is done (§3.7).
          await repo.clearRun(slot);
        }
      }
      _invalidate(slot);
    }

    run();
  }

  void _invalidate(String slot) {
    if (slot == kFreeSlot) {
      ref.invalidate(savedFreeRunProvider);
    } else if (slot.startsWith('daily:')) {
      ref.read(dailyVersionProvider.notifier).bump();
    } else if (slot.startsWith('level:')) {
      ref.read(adventureVersionProvider.notifier).bump();
    }
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
      slot: _slot,
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
      justMatchedIds: _justMatched,
      digitsPresent: {
        for (final c in game.board.cells)
          if (!c.cleared) c.digit,
      },
      targetBeaten: game.targetBeaten,
    );
  }
}
