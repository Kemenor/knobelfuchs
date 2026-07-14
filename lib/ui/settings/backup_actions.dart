import 'dart:io';

import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
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

  /// The authoritative path of the OPEN database — asked of SQLite itself
  /// rather than guessed from drift_flutter's defaults (a wrong guess made
  /// the first import a silent no-op, phone playtest 2026-07-14).
  Future<String> _dbPath() async {
    final db = ref.read(databaseProvider);
    final row = await db
        .customSelect(
            "SELECT file FROM pragma_database_list WHERE name = 'main'")
        .getSingle();
    return row.read<String>('file');
  }

  /// Build the backup zip and open the system SAVE dialog (SAF) — the
  /// player picks the destination: device storage or any cloud provider.
  /// (The share sheet has no reliable "save to file" target on every ROM —
  /// phone playtest 2026-07-14.) Returns the zip size in bytes, or null when
  /// the dialog is cancelled — the size shows in the confirmation so an
  /// empty-file bug is visible immediately (tablet 0-byte hunt).
  Future<int?> exportBackup() async {
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
      appVersion: (await PackageInfo.fromPlatform()).version,
    );
    snap.deleteSync();

    final now = DateTime.now();
    final stamp = '${now.year}'
        '-${now.month.toString().padLeft(2, '0')}'
        '-${now.day.toString().padLeft(2, '0')}';
    // Write to a temp file and hand the PATH to the save dialog — the
    // in-memory `data:` mode produced 0-byte files on MIUI (tablet
    // playtest 2026-07-14).
    final tmpZip = File(p.join(tmp.path, 'knobelfuchs-$stamp.zip'));
    await tmpZip.writeAsBytes(zip, flush: true);
    try {
      final saved = await FlutterFileDialog.saveFile(
        params: SaveFileDialogParams(
          sourceFilePath: tmpZip.path,
          fileName: 'knobelfuchs-$stamp.zip',
          mimeTypesFilter: const ['application/zip'],
        ),
      );
      return saved != null ? zip.length : null;
    } finally {
      if (tmpZip.existsSync()) tmpZip.deleteSync();
    }
  }

  /// Let the player pick a backup file; returns null when they cancel.
  /// Throws [BackupException] on an invalid or too-new file.
  ///
  /// Picked via flutter_file_dialog (not file_selector): MIUI's documents
  /// provider reports stale 0-byte sizes and file_selector trusted them,
  /// yielding empty reads for perfectly good files (tablet playtest
  /// 2026-07-14). This plugin streams the copy to EOF instead. No mime
  /// filter — parseBackup is the validator, and filters hid the file on
  /// some pickers.
  Future<BackupContents?> pickBackup() async {
    final path = await FlutterFileDialog.pickFile(
      params: const OpenFileDialogParams(
        dialogType: OpenFileDialogType.document,
      ),
    );
    if (path == null) return null;
    final contents = parseBackup(await File(path).readAsBytes());
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
    final dbPath = await _dbPath(); // must be read while the db is open
    await db.close();
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
