/// Daily Knobel (§6.2): seed = the calendar date in its own internal
/// namespace, budgets fixed at 5/5, target = bot × 0.9. No server — the date
/// is the seed, the archive starts at [kDailyEpoch].
library;

import 'bot.dart';
import 'constants.dart';
import 'game.dart';

/// Internal seed key — never typed, never colliding with player seeds
/// (player seeds can't contain ':', normalization strips it).
String dailySeedKey(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return 'daily:$y$m$d';
}

/// The full config for a date, target included (computed, deterministic —
/// the bot plays under the same scoring variant).
GameConfig dailyConfig(DateTime date,
    {ScoringVariant scoring = ScoringVariant.classic}) {
  final base = GameConfig(
    seed: dailySeedKey(date),
    adds: kDefaultAdds,
    hints: kDefaultHints,
    scoring: scoring,
  );
  return base.withTarget(targetScore(base, kDailyTargetFactor));
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Playable = between the epoch and the device's today, inclusive (§6.2).
/// The future-lock is a design statement, not security.
bool isDailyPlayable(DateTime date, DateTime now) {
  final d = _dateOnly(date);
  return !d.isBefore(_dateOnly(kDailyEpoch)) && !d.isAfter(_dateOnly(now));
}
