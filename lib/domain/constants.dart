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

/// At most this many unused adds are rewarded (family decision 2026-07-12):
/// keeps the ceiling hard even in Free Form with a 20-add budget.
const int kMaxRewardedUnusedAdds = 4;

/// The hard per-board ceiling (originals-only): 35×10 + 250 + 4×50 = 800.
/// The Free-Form target field validates against this — no board can pay more.
const int kMaxScore = kOpeningCells * kPointsPerPair +
    kPointsBoardCleared +
    kMaxRewardedUnusedAdds * kPointsPerUnusedAdd;

// Targets (§4.1): target = round10(botScore × factor).
const double kDailyTargetFactor = 0.9;
// Adventure ramps 0.9 → 1.0 across levels; curve curated in playtesting.

/// The daily archive begins here (§6.2) — named constant, gray the calendar
/// back-arrow at this month.
final DateTime kDailyEpoch = DateTime(2026, 7, 1);

/// Default budgets (§6).
const int kDefaultAdds = 5;
const int kDefaultHints = 5;

/// The parameter sheet's budget ceiling (§6.1: steppers run 0…20, then ∞).
/// Challenge payloads outside this range are rejected (§7).
const int kMaxBudget = 20;

/// Hard board ceiling (§3.4): an add that would push the board past this is
/// refused. Keeps ∞-add runs finite and stops a hostile saved-run log from
/// doubling the board into the billions on replay (each add copies every
/// survivor).
const int kMaxBoardCells = 540; // 60 full rows of 9
