import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/adventure.dart';
import '../providers.dart';

/// `skipped` = un-beaten, but tried often enough that the next level opened
/// anyway (§6.3 skip rule) — still open, still waiting to be beaten.
enum LevelState { beaten, skipped, current, locked }

class LevelInfo {
  final int level;
  final LevelState state;
  final int? best;
  final int target;
  final int adds;
  final int hints;
  final bool hasSavedRun;
  final int missedRuns; // distinct finished runs below target (§6.3)
  const LevelInfo({
    required this.level,
    required this.state,
    required this.best,
    required this.target,
    required this.adds,
    required this.hints,
    required this.hasSavedRun,
    required this.missedRuns,
  });

  /// The run-end screen's quiet "Weiter zu Level N" offer (§6.3): not
  /// beaten, but the skip rule has opened the next level.
  bool get canSkip =>
      state == LevelState.skipped && level < kAdventureLevels;
}

/// The level list: beaten flags latch from run_results; a level opens behind
/// a beaten one — or behind one missed [kAdventureSkipAfter] times (the skip
/// rule, derived from the records, never stored); everything else is locked
/// (§6.3).
final adventureProvider = FutureProvider<List<LevelInfo>>((ref) async {
  ref.watch(adventureVersionProvider);
  final db = ref.watch(databaseProvider);

  final results = await (db.select(db.runResults)
        ..where((r) => r.slot.like('level:%')))
      .get();
  final saved = await (db.select(db.savedRuns)
        ..where((r) => r.slot.like('level:%')))
      .get();
  final savedSlots = {for (final r in saved) r.slot};

  final beaten = <int, bool>{};
  final best = <int, int>{};
  // One run = one start: undo-back-in keeps startedAt, so repeated run-end
  // rows of the same run collapse into one miss.
  final missedStarts = <int, Set<int>>{};
  for (final r in results) {
    final level = int.tryParse(r.slot.substring('level:'.length));
    if (level == null) continue;
    beaten[level] = (beaten[level] ?? false) || r.targetBeaten;
    if (!r.targetBeaten) {
      (missedStarts[level] ??= {}).add(r.startedAt.millisecondsSinceEpoch);
    }
    best[level] =
        best[level] == null || r.score > best[level]! ? r.score : best[level]!;
  }

  final levels = <LevelInfo>[];
  var unlocked = true; // level 1 is always open
  for (var i = 1; i <= kAdventureLevels; i++) {
    final config = adventureConfig(i);
    final isBeaten = beaten[i] ?? false;
    final missed = missedStarts[i]?.length ?? 0;
    final opensNext =
        adventureOpensNext(beaten: isBeaten, missedRuns: missed);
    final LevelState state;
    if (isBeaten) {
      state = LevelState.beaten;
    } else if (unlocked && opensNext && i < kAdventureLevels) {
      state = LevelState.skipped;
    } else if (unlocked) {
      state = LevelState.current;
    } else {
      state = LevelState.locked;
    }
    levels.add(LevelInfo(
      level: i,
      state: state,
      best: best[i],
      target: config.target!,
      adds: config.adds!,
      hints: config.hints!,
      hasSavedRun: savedSlots.contains(adventureSlot(i)),
      missedRuns: missed,
    ));
    // A beaten level always opens the next (as before); a skippable one
    // only if it was itself reachable — misses can't tunnel past a lock.
    unlocked = isBeaten || (unlocked && opensNext);
  }
  return levels;
});
