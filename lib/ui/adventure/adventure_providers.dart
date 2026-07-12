import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/adventure.dart';
import '../providers.dart';

enum LevelState { beaten, current, locked }

class LevelInfo {
  final int level;
  final LevelState state;
  final int? best;
  final int target;
  final int adds;
  final int hints;
  final bool hasSavedRun;
  const LevelInfo({
    required this.level,
    required this.state,
    required this.best,
    required this.target,
    required this.adds,
    required this.hints,
    required this.hasSavedRun,
  });
}

/// The level list: beaten flags latch from run_results; the first un-beaten
/// level is `current`; everything after is locked (§6.3).
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
  for (final r in results) {
    final level = int.tryParse(r.slot.substring('level:'.length));
    if (level == null) continue;
    beaten[level] = (beaten[level] ?? false) || r.targetBeaten;
    best[level] =
        best[level] == null || r.score > best[level]! ? r.score : best[level]!;
  }

  final levels = <LevelInfo>[];
  var unlocked = true; // level 1 is always open
  for (var i = 1; i <= kAdventureLevels; i++) {
    final config = adventureConfig(i);
    final isBeaten = beaten[i] ?? false;
    final LevelState state;
    if (isBeaten) {
      state = LevelState.beaten;
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
    ));
    unlocked = isBeaten; // the next level opens only behind a beaten one
  }
  return levels;
});
