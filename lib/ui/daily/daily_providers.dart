import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/daily.dart';
import '../providers.dart';

/// Slot key for a date's run — matches the schema convention 'daily:yyyymmdd'.
String dailySlot(DateTime date) => dailySeedKey(date);

/// Everything the calendar needs to paint one day (mockup 06 states).
enum DayState { locked, waiting, inProgress, played, beaten }

class DayInfo {
  final DateTime date;
  final DayState state;
  final int? score; // best result, or autosave score for inProgress
  final int? target;
  const DayInfo(this.date, this.state, {this.score, this.target});
}

class MonthInfo {
  final DateTime month; // first day of month
  final List<DayInfo> days;
  const MonthInfo(this.month, this.days);
}

/// Calendar month data: merges saved runs + best results per date.
/// One query pair per month — cheap, local, recomputed when bumped.
final dailyMonthProvider =
    FutureProvider.family<MonthInfo, DateTime>((ref, month) async {
  // Re-fetch whenever a daily run was saved/ended.
  ref.watch(dailyVersionProvider);
  final db = ref.watch(databaseProvider);
  final now = ref.watch(nowProvider)();

  final first = DateTime(month.year, month.month, 1);
  final nextMonth = DateTime(month.year, month.month + 1, 1);
  final prefix = 'daily:';

  final saved = await (db.select(db.savedRuns)
        ..where((r) => r.slot.like('$prefix%')))
      .get();
  final results = await (db.select(db.runResults)
        ..where((r) => r.slot.like('$prefix%')))
      .get();

  final savedBySlot = {for (final r in saved) r.slot: r};
  // Best score and the beaten-flag fold independently: the flag latches
  // (§6.3 semantics) even when a later replay scores higher without beating.
  final bestBySlot = <String, ({int score, bool beaten})>{};
  for (final r in results) {
    final prev = bestBySlot[r.slot];
    bestBySlot[r.slot] = (
      score: prev == null || r.score > prev.score ? r.score : prev.score,
      beaten: (prev?.beaten ?? false) || r.targetBeaten,
    );
  }

  final days = <DayInfo>[];
  for (var d = first; d.isBefore(nextMonth); d = d.add(const Duration(days: 1))) {
    final date = DateTime(d.year, d.month, d.day);
    if (!isDailyPlayable(date, now)) {
      days.add(DayInfo(date, DayState.locked));
      continue;
    }
    final slot = dailySlot(date);
    final best = bestBySlot[slot];
    final save = savedBySlot[slot];
    if (best != null && best.beaten) {
      days.add(DayInfo(date, DayState.beaten, score: best.score));
    } else if (save != null) {
      days.add(DayInfo(date, DayState.inProgress, score: save.scoreCache));
    } else if (best != null) {
      days.add(DayInfo(date, DayState.played, score: best.score));
    } else {
      days.add(DayInfo(date, DayState.waiting));
    }
  }
  return MonthInfo(first, days);
});
