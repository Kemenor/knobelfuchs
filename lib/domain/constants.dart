/// Engine constants — frozen in design-concept.md (§2, §4, §6).
library;

const int kColumns = 9;

/// 3 full rows + 8 — matches the reference game's opening (family playtest,
/// 2026-07-12); the partial last row puts the reading-order wrap in play from
/// the first board.
const int kOpeningCells = 35;
const int kFairnessFloor = 3; // minimum available pairs at open (§2.2)
const int kMaxSeedLength = 32; // runes, after normalization (§2.1)

// Scoring (§4) — frozen.
const int kPointsPerPair = 10;
const int kPointsPerRow = 50; // stacks per collapsed row
const int kPointsBoardCleared = 250;
const int kPointsPerUnusedAdd = 50; // paid only on a cleared board

// Targets (§4.1): target = round10(botScore × factor).
const double kDailyTargetFactor = 0.9;
// Adventure ramps 0.9 → 1.0 across levels; curve curated in playtesting.

/// The daily archive begins here (§6.2) — named constant, gray the calendar
/// back-arrow at this month.
final DateTime kDailyEpoch = DateTime(2026, 7, 1);

/// Default budgets (§6).
const int kDefaultAdds = 5;
const int kDefaultHints = 5;
