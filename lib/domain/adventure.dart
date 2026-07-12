/// Adventure mode (§6.3): a curated, numbered level collection. Each level =
/// fixed seed + budgets + computed target (bot × ramping factor). Ending a
/// run with score ≥ target unlocks the next level; the beaten flag latches.
///
/// The curve below is the v1 *provisional* curation — tightening budgets and
/// a 0.9 → 1.0 factor ramp, never timers. Tuned during family playtesting
/// (concept §13, still-open item 1).
library;

import 'bot.dart';
import 'game.dart';

const int kAdventureLevels = 20;

/// Internal seed namespace — the colon keeps it out of player-seed space,
/// like `daily:` (§2.1).
String adventureSeedKey(int level) => 'level:$level';
String adventureSlot(int level) => adventureSeedKey(level);

/// Adds: 5 → 2 across the run.
int adventureAdds(int level) {
  if (level <= 4) return 5;
  if (level <= 8) return 4;
  if (level <= 16) return 3;
  return 2;
}

/// Hints: 5 → 1 across the run.
int adventureHints(int level) {
  if (level <= 6) return 5;
  if (level <= 12) return 4;
  if (level <= 16) return 3;
  if (level <= 19) return 2;
  return 1;
}

/// Target factor ramps 0.9 (forgiving) → 1.0 (beat the bot outright) — §4.1.
double adventureFactor(int level) =>
    0.9 + (level - 1) * (0.1 / (kAdventureLevels - 1));

/// The full config for a level, target included (computed, deterministic —
/// same on every device, no authoring burden).
GameConfig adventureConfig(int level) {
  assert(level >= 1 && level <= kAdventureLevels);
  final base = GameConfig(
    seed: adventureSeedKey(level),
    adds: adventureAdds(level),
    hints: adventureHints(level),
  );
  return base.withTarget(targetScore(base, adventureFactor(level)));
}
