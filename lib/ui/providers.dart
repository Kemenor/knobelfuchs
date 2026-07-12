import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/game_repository.dart';

/// Free Form's single run slot (§6.1); daily runs use 'daily:yyyymmdd',
/// adventure levels 'level:N'.
const String kFreeSlot = 'free';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final gameRepositoryProvider = Provider<GameRepository>(
    (ref) => GameRepository(ref.watch(databaseProvider)));

/// The autosaved Free Form run, for the home card. Re-fetched after every
/// controller persist.
final savedFreeRunProvider = FutureProvider<SavedRunSummary?>(
  (ref) => ref.watch(gameRepositoryProvider).loadSummary(kFreeSlot),
);

/// Bumped after every daily-slot persist so the calendar re-queries.
final dailyVersionProvider =
    NotifierProvider<VersionNotifier, int>(VersionNotifier.new);

/// Bumped after every adventure-slot persist so the level list re-queries.
final adventureVersionProvider =
    NotifierProvider<VersionNotifier, int>(VersionNotifier.new);

class VersionNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

/// Injectable clock for date-dependent providers (fixed in tests).
final nowProvider = Provider<DateTime Function()>((ref) => DateTime.now);
