import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// One autosaved run per slot (§6, grilling Q10): 'free' — Free Form's single
/// slot; 'daily:yyyymmdd' — one per date; 'level:N' — one per adventure level.
class SavedRuns extends Table {
  TextColumn get slot => text()();
  TextColumn get seed => text()();
  IntColumn get adds => integer().nullable()(); // null = ∞
  IntColumn get hints => integer().nullable()(); // null = ∞
  IntColumn get target => integer().nullable()();
  TextColumn get actions => text()(); // action_codec.dart
  IntColumn get hintsUsed => integer()();
  IntColumn get hintA => integer().nullable()(); // active sticky hint (§3.5)
  IntColumn get hintB => integer().nullable()();
  BoolColumn get hintAReleased => boolean().withDefault(const Constant(false))();
  BoolColumn get hintBReleased => boolean().withDefault(const Constant(false))();
  IntColumn get scoreCache => integer()(); // home card without replaying
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {slot};
}

/// Full record of every finished run — written at every run-end occurrence
/// (§3.7, §8: record everything from day one, surface modestly).
class RunResults extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get slot => text()();
  TextColumn get seed => text()();
  IntColumn get adds => integer().nullable()();
  IntColumn get hints => integer().nullable()();
  IntColumn get target => integer().nullable()();
  IntColumn get score => integer()();
  BoolColumn get cleared => boolean()();
  BoolColumn get targetBeaten => boolean()();
  IntColumn get pairs => integer()();
  IntColumn get rows => integer()();
  IntColumn get addsUsed => integer()();
  IntColumn get hintsUsed => integer()();
  IntColumn get durationMs => integer()(); // recorded, never shown in play
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime()();
}

@DriftDatabase(tables: [SavedRuns, RunResults])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'knobelfuchs'));

  /// For tests: pass e.g. `NativeDatabase.memory()`.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;
}
