import 'package:drift/drift.dart';

import '../domain/game.dart';
import 'action_codec.dart';
import 'database.dart';

/// What the home card needs without replaying the whole log.
class SavedRunSummary {
  final String slot;
  final String seed;
  final int score;
  const SavedRunSummary({
    required this.slot,
    required this.seed,
    required this.score,
  });
}

/// A fully loaded run, ready for `GameState.replay`.
class SavedRun {
  final GameConfig config;
  final List<GameAction> actions;
  final int hintsUsed;
  final ActiveHint? activeHint;
  final DateTime startedAt;
  const SavedRun({
    required this.config,
    required this.actions,
    required this.hintsUsed,
    required this.activeHint,
    required this.startedAt,
  });
}

class GameRepository {
  final AppDatabase db;
  GameRepository(this.db);

  /// Autosave — every move is durable (§3.7); process death is invisible.
  Future<void> saveRun(
    String slot,
    GameState state, {
    required DateTime startedAt,
    required DateTime now,
  }) {
    final hint = state.activeHint;
    return db.into(db.savedRuns).insertOnConflictUpdate(
          SavedRunsCompanion.insert(
            slot: slot,
            seed: state.config.seed,
            adds: Value(state.config.adds),
            hints: Value(state.config.hints),
            target: Value(state.config.target),
            actions: encodeActions(state.log),
            hintsUsed: state.hintsUsed,
            hintA: Value(hint?.aId),
            hintB: Value(hint?.bId),
            hintAReleased: Value(hint?.aReleased ?? false),
            hintBReleased: Value(hint?.bReleased ?? false),
            scoreCache: state.score,
            startedAt: startedAt,
            updatedAt: now,
          ),
        );
  }

  Future<SavedRunSummary?> loadSummary(String slot) async {
    final row = await (db.select(db.savedRuns)
          ..where((r) => r.slot.equals(slot)))
        .getSingleOrNull();
    if (row == null) return null;
    return SavedRunSummary(slot: row.slot, seed: row.seed, score: row.scoreCache);
  }

  Future<SavedRun?> loadRun(String slot) async {
    final row = await (db.select(db.savedRuns)
          ..where((r) => r.slot.equals(slot)))
        .getSingleOrNull();
    if (row == null) return null;
    ActiveHint? hint;
    if (row.hintA != null && row.hintB != null) {
      hint = ActiveHint(row.hintA!, row.hintB!)
        ..aReleased = row.hintAReleased
        ..bReleased = row.hintBReleased;
    }
    return SavedRun(
      config: GameConfig(
        seed: row.seed,
        adds: row.adds,
        hints: row.hints,
        target: row.target,
      ),
      actions: decodeActions(row.actions),
      hintsUsed: row.hintsUsed,
      activeHint: hint,
      startedAt: row.startedAt,
    );
  }

  Future<void> clearRun(String slot) =>
      (db.delete(db.savedRuns)..where((r) => r.slot.equals(slot))).go();

  /// Results commit at every run-end occurrence (§3.7); "best" is a query,
  /// not a write decision.
  Future<void> recordResult(
    String slot,
    GameState state, {
    required DateTime startedAt,
    required DateTime endedAt,
  }) {
    return db.into(db.runResults).insert(
          RunResultsCompanion.insert(
            slot: slot,
            seed: state.config.seed,
            adds: Value(state.config.adds),
            hints: Value(state.config.hints),
            target: Value(state.config.target),
            score: state.score,
            cleared: state.status == GameStatus.cleared,
            targetBeaten: state.targetBeaten,
            pairs: state.pairsMatched,
            rows: state.rowsCleared,
            addsUsed: state.addsUsed,
            hintsUsed: state.hintsUsed,
            durationMs: endedAt.difference(startedAt).inMilliseconds,
            startedAt: startedAt,
            endedAt: endedAt,
          ),
        );
  }

  /// Best score ever recorded for a seed+slot (run-end screens, later phases).
  Future<int?> bestScore(String slot, String seed) async {
    final rows = await (db.select(db.runResults)
          ..where((r) => r.slot.equals(slot) & r.seed.equals(seed))
          ..orderBy([(r) => OrderingTerm.desc(r.score)])
          ..limit(1))
        .get();
    return rows.isEmpty ? null : rows.first.score;
  }
}
