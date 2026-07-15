import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/game_repository.dart';
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
  final bool canAdd; // budget left AND under the board ceiling (§3.4)

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
    required this.canAdd,
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
    _justMatched = const {}; // no flash may leak across run boundaries
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
    _justMatched = const {}; // resumed ids can collide with the old run's
    _startedAt = saved.startedAt;
    _publish();
    return true;
  }

  /// Leave the game for good (run-end "Zum Menü") — the slot is cleared;
  /// the result was already recorded at run end.
  Future<void> quit() async {
    final slot = _slot;
    final repo = ref.read(gameRepositoryProvider);
    _game = null;
    _selectedId = null;
    _justMatched = const {};
    _publish();
    // Chain behind the write queue: a queued run-end commit re-saves the
    // run inside its transaction — an unordered clear here would let that
    // save resurrect the just-quit run as a ghost resume card.
    _pending = _pending.then((_) => repo.clearRun(slot)).catchError((Object e) {
      debugPrint('knobelfuchs: quit clear failed: $e');
    });
    await _pending;
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

    final hint = game.activeHint;
    final willRelease =
        hint != null && hint.involves(id) && !hint.isReleased(id);
    game.releaseHintCell(id);

    var matched = false;
    final selected = _selectedId;
    if (selected == null) {
      _selectedId = id;
    } else if (selected == id) {
      _selectedId = null;
    } else {
      final selectedIdx = game.board.indexOfId(selected);
      if (selectedIdx != null && game.board.canMatch(selectedIdx, idx)) {
        game.match(selected, id);
        matched = true;
        _selectedId = null;
        _flashMatched({selected, id});
      } else {
        // Never an error — the selection simply moves (§3.2).
        _selectedId = id;
      }
    }
    _publish();
    // Selection isn't persisted state — only a match or a released hint
    // changes anything the autosave stores; don't rewrite identical bytes
    // on every selection tap.
    if (matched || willRelease) _persist(before);
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

  /// Writes queue behind this future so a later persist can never overtake
  /// an earlier one (undo-back-in racing the run-end commit corrupted the
  /// slot ordering before).
  Future<void> _pending = Future.value();

  /// Autosave + commit results on the playing→ended transition (§3.7).
  /// Fire-and-forget, but serialized and snapshotted.
  void _persist(GameStatus before) {
    final game = _game;
    if (game == null) return;
    final repo = ref.read(gameRepositoryProvider);
    final slot = _slot;
    final now = DateTime.now();
    final startedAt = _startedAt;
    // Captured synchronously: the chain runs behind awaits while the player
    // keeps playing (or undoes back in) — the writes must see the state at
    // THIS transition, not a later one. O(log) scalar capture, no replay.
    final snap = RunSnapshot.of(game);
    final after = snap.status;

    _pending = _pending.then((_) async {
      if (before == GameStatus.playing && after != GameStatus.playing) {
        // Atomic run-end: autosave, result row and — on cleared — the slot
        // clear land together; process death can't leave a "cleared" ghost
        // resume or a result-less end (§3.7).
        await repo.commitRunEnd(slot, snap,
            startedAt: startedAt,
            endedAt: now,
            clear: after == GameStatus.cleared);
      } else {
        await repo.saveRun(slot, snap, startedAt: startedAt, now: now);
      }
      _invalidate(slot);
    }).catchError((Object e) {
      // An autosave failure must never throw into the zone; the next action
      // re-persists the full log anyway.
      debugPrint('knobelfuchs: persist failed: $e');
    });
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
      canAdd: game.canAdd,
    );
  }
}
