import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/backup.dart';
import '../game/game_controller.dart';
import '../providers.dart';
import 'settings.dart';

final backupActionsProvider =
    Provider<BackupActions>((ref) => BackupActions(ref));

/// The I/O half of §9.1 backup/restore; the pure zip logic lives in
/// data/backup.dart. Export snapshots the live database with `VACUUM INTO`
/// (consistent even mid-game, WAL included); import closes the database,
/// swaps the file, and rebuilds the provider world.
class BackupActions {
  final Ref ref;
  BackupActions(this.ref);

  Future<String> _dbPath() async {
    // drift_flutter's default location for driftDatabase(name: 'knobelfuchs').
    final dir = await getApplicationSupportDirectory();
    return p.join(dir.path, 'knobelfuchs.sqlite');
  }

  /// Build the backup zip and open the system SAVE dialog (SAF) — the
  /// player picks the destination: device storage or any cloud provider.
  /// (The share sheet has no reliable "save to file" target on every ROM —
  /// phone playtest 2026-07-14.) Returns false when the dialog is cancelled.
  Future<bool> exportBackup() async {
    final db = ref.read(databaseProvider);
    final tmp = await getTemporaryDirectory();
    final snapPath = p.join(tmp.path, 'knobelfuchs-export.sqlite');
    final snap = File(snapPath);
    if (snap.existsSync()) snap.deleteSync();
    await db.customStatement('VACUUM INTO ?', [snapPath]);

    final prefs = ref.read(sharedPrefsProvider);
    final settings = {for (final k in prefs.getKeys()) k: prefs.get(k)};
    final zip = buildBackup(
      dbBytes: await snap.readAsBytes(),
      settings: settings,
      schemaVersion: db.schemaVersion,
      appVersion: kAppVersion,
    );
    snap.deleteSync();

    final now = DateTime.now();
    final stamp = '${now.year}'
        '-${now.month.toString().padLeft(2, '0')}'
        '-${now.day.toString().padLeft(2, '0')}';
    final saved = await FlutterFileDialog.saveFile(
      params: SaveFileDialogParams(
        data: Uint8List.fromList(zip),
        fileName: 'knobelfuchs-$stamp.zip',
        mimeTypesFilter: const ['application/zip'],
      ),
    );
    return saved != null;
  }

  /// Let the player pick a backup file; returns null when they cancel.
  /// Throws [BackupException] on an invalid or too-new file.
  Future<BackupContents?> pickBackup() async {
    final file = await openFile(acceptedTypeGroups: [
      const XTypeGroup(
        label: 'Knobelfuchs',
        extensions: ['zip'],
        mimeTypes: ['application/zip'],
        uniformTypeIdentifiers: ['public.zip-archive'],
      ),
    ]);
    if (file == null) return null;
    final contents = parseBackup(await file.readAsBytes());
    if (contents.schemaVersion > ref.read(databaseProvider).schemaVersion) {
      // The backup came from a newer app — importing would lose columns.
      throw const BackupException(BackupError.tooNew);
    }
    return contents;
  }

  /// Replace this device's state with [contents]. Destructive — the caller
  /// confirms with the player first.
  Future<void> applyBackup(BackupContents contents) async {
    // Drop the live run first so nothing persists into the dying database.
    ref.invalidate(gameControllerProvider);

    final db = ref.read(databaseProvider);
    await db.close();
    final dbPath = await _dbPath();
    for (final suffix in ['', '-wal', '-shm', '-journal']) {
      final f = File('$dbPath$suffix');
      if (f.existsSync()) f.deleteSync();
    }
    await File(dbPath).writeAsBytes(contents.dbBytes, flush: true);

    final prefs = ref.read(sharedPrefsProvider);
    await prefs.clear();
    for (final e in contents.settings.entries) {
      final v = e.value;
      switch (v) {
        case bool b:
          await prefs.setBool(e.key, b);
        case int i:
          await prefs.setInt(e.key, i);
        case double d:
          await prefs.setDouble(e.key, d);
        case String s:
          await prefs.setString(e.key, s);
        case List<String> l:
          await prefs.setStringList(e.key, l);
        default:
          break;
      }
    }

    // Rebuild the provider world on the imported state. The old database
    // provider's guarded dispose tolerates the manual close above.
    ref.invalidate(databaseProvider);
    ref.invalidate(settingsProvider);
    ref.invalidate(savedFreeRunProvider);
    ref.read(dailyVersionProvider.notifier).bump();
    ref.read(adventureVersionProvider.notifier).bump();
  }
}
