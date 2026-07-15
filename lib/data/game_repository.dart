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

/// Synchronous capture of everything persistence writes, taken at the moment
/// of the transition. The write chain runs behind awaits while the player
/// keeps playing (or undoes back in) — the rows must reflect THIS state, not
/// a later one. Reads no board: persistence only needs scalars and the
/// encoded log, so capturing is O(log), not a replay.
class RunSnapshot {
  final GameConfig config;
  final String actions; // encoded
  final int hintsUsed;
  final int? hintA, hintB;
  final bool hintAReleased, hintBReleased;
  final int score;
  final GameStatus status;
  final bool targetBeaten;
  final int pairsMatched, rowsCleared, addsUsed;

  RunSnapshot.of(GameState state)
      : config = state.config,
        actions = encodeActions(state.log),
        hintsUsed = state.hintsUsed,
        hintA = state.activeHint?.aId,
        hintB = state.activeHint?.bId,
        hintAReleased = state.activeHint?.aReleased ?? false,
        hintBReleased = state.activeHint?.bReleased ?? false,
        score = state.score,
        status = state.status,
        targetBeaten = state.targetBeaten,
        pairsMatched = state.pairsMatched,
        rowsCleared = state.rowsCleared,
        addsUsed = state.addsUsed;
}

class GameRepository {
  final AppDatabase db;
  GameRepository(this.db);

  /// Autosave — every move is durable (§3.7); process death is invisible.
  Future<void> saveRun(
    String slot,
    RunSnapshot snap, {
    required DateTime startedAt,
    required DateTime now,
  }) {
    return db.into(db.savedRuns).insertOnConflictUpdate(
          SavedRunsCompanion.insert(
            slot: slot,
            seed: snap.config.seed,
            adds: Value(snap.config.adds),
            hints: Value(snap.config.hints),
            target: Value(snap.config.target),
            actions: snap.actions,
            hintsUsed: snap.hintsUsed,
            hintA: Value(snap.hintA),
            hintB: Value(snap.hintB),
            hintAReleased: Value(snap.hintAReleased),
            hintBReleased: Value(snap.hintBReleased),
            scoreCache: snap.score,
            scoring: Value(snap.config.scoring.name),
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
        // Unknown name (corrupt row, foreign backup) → the frozen formula,
        // not classic: classic pays rows and copies, and a replay under it
        // could inflate past the hard 800 ceiling (§4).
        scoring: ScoringVariant.values.asNameMap()[row.scoring] ??
            ScoringVariant.originalsOnly,
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
    RunSnapshot snap, {
    required DateTime startedAt,
    required DateTime endedAt,
  }) {
    return db.into(db.runResults).insert(
          RunResultsCompanion.insert(
            slot: slot,
            seed: snap.config.seed,
            adds: Value(snap.config.adds),
            hints: Value(snap.config.hints),
            target: Value(snap.config.target),
            score: snap.score,
            cleared: snap.status == GameStatus.cleared,
            targetBeaten: snap.targetBeaten,
            pairs: snap.pairsMatched,
            rows: snap.rowsCleared,
            addsUsed: snap.addsUsed,
            hintsUsed: snap.hintsUsed,
            durationMs: endedAt.difference(startedAt).inMilliseconds,
            scoring: Value(snap.config.scoring.name),
            startedAt: startedAt,
            endedAt: endedAt,
          ),
        );
  }

  /// The playing→ended commit in one transaction (§3.7): autosave, result
  /// row and — on a cleared board — the slot clear land together, so process
  /// death can't leave a "cleared" ghost to resume or an end without its
  /// result.
  Future<void> commitRunEnd(
    String slot,
    RunSnapshot snap, {
    required DateTime startedAt,
    required DateTime endedAt,
    required bool clear,
  }) {
    return db.transaction(() async {
      await saveRun(slot, snap, startedAt: startedAt, now: endedAt);
      await recordResult(slot, snap, startedAt: startedAt, endedAt: endedAt);
      if (clear) await clearRun(slot);
    });
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
