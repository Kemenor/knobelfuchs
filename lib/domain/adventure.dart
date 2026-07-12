/// Adventure mode (§6.3), v2 (family design, 2026-07-12): **50 levels in
/// five chapters of ten**. Within a chapter the budgets tighten level by
/// level; each new chapter resets them — and raises the *board* difficulty
/// instead. Never timers.
///
/// Board difficulty is measured, not guessed: `tool/curate_levels.dart` runs
/// seeded random-policy playouts (see `difficulty.dart`) over candidate
/// seeds and picks each chapter's ten from the matching quantile band
/// (very easy → easy → medium → hard → very hard). Adventure seeds use the
/// raw uniform deal on purpose — distribution skew is part of the texture.
library;

import 'bot.dart';
import 'game.dart';

const int kAdventureLevels = 50;
const int kChapterLength = 10;

/// Curated 2026-07-12 (300 candidates × 24 playouts; random-policy clear
/// rates 96 % → 42 %). Re-run the tool to re-curate.
const List<String> kAdventureSeeds = [
  // Chapter 1: very easy
  'level:s160', 'level:s253', 'level:s112', 'level:s202', 'level:s137',
  'level:s178', 'level:s268', 'level:s126', 'level:s164', 'level:s144',
  // Chapter 2: easy
  'level:s199', 'level:s262', 'level:s84', 'level:s30', 'level:s19',
  'level:s119', 'level:s243', 'level:s96', 'level:s287', 'level:s252',
  // Chapter 3: medium
  'level:s139', 'level:s109', 'level:s148', 'level:s154', 'level:s224',
  'level:s263', 'level:s283', 'level:s41', 'level:s52', 'level:s114',
  // Chapter 4: hard
  'level:s31', 'level:s250', 'level:s261', 'level:s198', 'level:s193',
  'level:s245', 'level:s183', 'level:s100', 'level:s259', 'level:s274',
  // Chapter 5: very hard
  'level:s118', 'level:s219', 'level:s177', 'level:s209', 'level:s282',
  'level:s80', 'level:s229', 'level:s59', 'level:s297', 'level:s138',
];

/// Within-chapter budget curves (position 0–9): generous start, tight end,
/// reset every chapter.
const List<int> _addsCurve = [5, 5, 4, 4, 3, 3, 3, 2, 2, 2];
const List<int> _hintsCurve = [5, 4, 4, 3, 3, 2, 2, 1, 1, 1];

int adventureChapter(int level) => (level - 1) ~/ kChapterLength; // 0-based
int _position(int level) => (level - 1) % kChapterLength;

/// The curated board seed of a level. The slot (progress key) stays
/// `level:N` — re-curating seeds never invalidates progress.
String adventureSeedKey(int level) => kAdventureSeeds[level - 1];
String adventureSlot(int level) => 'level:$level';

int adventureAdds(int level) => _addsCurve[_position(level)];
int adventureHints(int level) => _hintsCurve[_position(level)];

/// Target factor ramps 0.9 (forgiving) → 1.0 across the whole run — §4.1.
double adventureFactor(int level) =>
    0.9 + (level - 1) * (0.1 / (kAdventureLevels - 1));

/// The full config for a level, target included (computed, deterministic —
/// same on every device, no authoring burden; the bot plays under the same
/// scoring variant).
GameConfig adventureConfig(int level,
    {ScoringVariant scoring = ScoringVariant.originalsOnly}) {
  assert(level >= 1 && level <= kAdventureLevels);
  final base = GameConfig(
    seed: adventureSeedKey(level),
    adds: adventureAdds(level),
    hints: adventureHints(level),
    scoring: scoring,
  );
  return base.withTarget(targetScore(base, adventureFactor(level)));
}
