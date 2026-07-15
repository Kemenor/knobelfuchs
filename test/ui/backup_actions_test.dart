import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knobelfuchs/data/backup.dart';
import 'package:knobelfuchs/data/database.dart';
import 'package:knobelfuchs/ui/providers.dart';
import 'package:knobelfuchs/ui/settings/backup_actions.dart';
import 'package:knobelfuchs/ui/settings/settings.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/backup_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late File dbFile;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('knobelfuchs-backup');
    dbFile = File(p.join(dir.path, 'knobelfuchs.sqlite'));
  });

  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  Future<ProviderContainer> containerOn(File file,
      {Map<String, Object> prefs = const {}}) async {
    SharedPreferences.setMockInitialValues(prefs);
    final sp = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(sp),
      databaseProvider.overrideWith((ref) {
        final db = AppDatabase.forTesting(NativeDatabase(file));
        ref.onDispose(() async {
          try {
            await db.close();
          } catch (_) {}
        });
        return db;
      }),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  Future<void> insertRun(AppDatabase db, String seed) =>
      db.into(db.savedRuns).insert(SavedRunsCompanion.insert(
            slot: 'free',
            seed: seed,
            actions: '',
            hintsUsed: 0,
            scoreCache: 0,
            scoring: const Value('originalsOnly'),
            startedAt: DateTime(2026, 7, 1),
            updatedAt: DateTime(2026, 7, 1),
          ));

  Future<String?> freeSeed(ProviderContainer c) async {
    final rows = await c.read(databaseProvider).select(c.read(databaseProvider).savedRuns).get();
    return rows.isEmpty ? null : rows.single.seed;
  }

  group('applyBackup swap (§9.1)', () {
    test('a valid import replaces runs and settings, leaving no debris',
        () async {
      final c = await containerOn(dbFile, prefs: {'locale': 'de'});
      await insertRun(c.read(databaseProvider), 'old-run');

      // "Device B": a second real database whose bytes become the backup.
      final fileB = File(p.join(dir.path, 'device-b.sqlite'));
      final dbB = AppDatabase.forTesting(NativeDatabase(fileB));
      await insertRun(dbB, 'imported-run');
      await dbB.close();

      await c.read(backupActionsProvider).applyBackup(BackupContents(
            dbBytes: await fileB.readAsBytes(),
            settings: const {'locale': 'fr'},
            schemaVersion: 2,
          ));

      expect(await freeSeed(c), 'imported-run');
      expect(c.read(sharedPrefsProvider).getString('locale'), 'fr');
      expect(File('${dbFile.path}.bak').existsSync(), isFalse);
      expect(File('${dbFile.path}.import').existsSync(), isFalse);
    });

    test('an unreadable database rolls back — old runs survive the failure',
        () async {
      final c = await containerOn(dbFile, prefs: {'locale': 'de'});
      await insertRun(c.read(databaseProvider), 'precious');

      // Passes the magic/user_version parse checks but is not a database —
      // the post-swap probe must catch it and restore the original file.
      await expectLater(
        c.read(backupActionsProvider).applyBackup(BackupContents(
              dbBytes: fakeDb(),
              settings: const {'locale': 'it'},
              schemaVersion: 2,
            )),
        throwsA(isA<BackupException>()
            .having((e) => e.error, 'error', BackupError.invalid)),
      );

      expect(await freeSeed(c), 'precious');
      // Settings were never touched: the import failed before the prefs step.
      expect(c.read(sharedPrefsProvider).getString('locale'), 'de');
      expect(File('${dbFile.path}.bak').existsSync(), isFalse);
      expect(File('${dbFile.path}.import').existsSync(), isFalse);
    });
  });
}
