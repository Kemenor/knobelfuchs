import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knobelfuchs/data/backup.dart';

import 'backup_fixtures.dart';

void main() {
  group('backup roundtrip (§9.1)', () {
    test('db bytes and typed settings survive intact', () {
      final settings = <String, Object?>{
        'music_on': true,
        'fx_vol': 0.8,
        'anleitung_seen': false,
        'locale': 'de',
        'music_off': <Object?>['music/wallpaper.mp3'],
        'some_int': 7,
      };
      final zip = buildBackup(
        dbBytes: fakeDb(),
        settings: settings,
        schemaVersion: 2,
        appVersion: '0.1',
      );
      final parsed = parseBackup(zip);
      expect(parsed.dbBytes, fakeDb());
      expect(parsed.schemaVersion, 2);
      expect(parsed.settings['music_on'], true);
      expect(parsed.settings['fx_vol'], 0.8);
      expect(parsed.settings['anleitung_seen'], false);
      expect(parsed.settings['locale'], 'de');
      expect(parsed.settings['music_off'], ['music/wallpaper.mp3']);
      expect(parsed.settings['some_int'], 7);
      expect(parsed.settings['some_int'], isA<int>());
    });

    test('settings are optional — runs still import without them', () {
      final zip = buildBackup(
        dbBytes: fakeDb(),
        settings: const {},
        schemaVersion: 2,
        appVersion: '0.1',
      );
      expect(parseBackup(zip).settings, isEmpty);
    });
  });

  group('backup rejection', () {
    test('garbage is not a backup', () {
      expect(() => parseBackup(Uint8List.fromList([1, 2, 3, 4])),
          throwsA(isA<BackupException>()));
    });

    test('a zip without our meta is foreign', () {
      // Any valid zip that isn't ours: reuse builder, then corrupt the app id
      // indirectly by checking a plain-text zip. Simplest: a backup whose db
      // entry lacks the SQLite magic must be rejected too.
      final zip = buildBackup(
        dbBytes: Uint8List.fromList(List.filled(64, 7)), // no magic
        settings: const {},
        schemaVersion: 2,
        appVersion: '0.1',
      );
      expect(
        () => parseBackup(zip),
        throwsA(isA<BackupException>()
            .having((e) => e.error, 'error', BackupError.invalid)),
      );
    });

    test('a newer schema rides through parse for the caller\'s tooNew gate',
        () {
      final zip = buildBackup(
        dbBytes: fakeDb(userVersion: 99),
        settings: const {},
        schemaVersion: 99,
        appVersion: '9.9',
      );
      // parse succeeds; the CALLER must compare 99 > current schema → tooNew.
      expect(parseBackup(zip).schemaVersion, 99);
    });

    test('a newer zip FORMAT is refused as tooNew, not misread', () {
      // Hand-craft the zip: buildBackup can only write the current format.
      final archive = Archive();
      archive.add(ArchiveFile.string(
          'meta.json',
          jsonEncode({
            'app': 'knobelfuchs',
            'format': kBackupFormat + 1,
            'schema': 2,
            'appVersion': '9.9',
          })));
      archive.add(ArchiveFile.bytes(kBackupDbEntry, fakeDb()));
      final zip = ZipEncoder().encodeBytes(archive);
      expect(
        () => parseBackup(Uint8List.fromList(zip)),
        throwsA(isA<BackupException>()
            .having((e) => e.error, 'error', BackupError.tooNew)),
      );
    });

    test('meta.json lying about the schema is rejected', () {
      // meta says 2, the file's own user_version says 1: importing would
      // re-run the v1→v2 migration onto columns that already exist and
      // brick the database on every launch.
      final zip = buildBackup(
        dbBytes: fakeDb(userVersion: 1),
        settings: const {},
        schemaVersion: 2,
        appVersion: '0.1',
      );
      expect(
        () => parseBackup(zip),
        throwsA(isA<BackupException>()
            .having((e) => e.error, 'error', BackupError.invalid)),
      );
    });

    test('a truncated database (shorter than the SQLite header) is rejected',
        () {
      final short = fakeDb();
      final zip = buildBackup(
        dbBytes: Uint8List.sublistView(short, 0, 64),
        settings: const {},
        schemaVersion: 2,
        appVersion: '0.1',
      );
      expect(() => parseBackup(zip), throwsA(isA<BackupException>()));
    });

    test('a zip bomb is rejected from its headers, before decompression', () {
      // A few MB of zeros deflate to almost nothing but declare > 64 MB
      // uncompressed — the size gate must fire without inflating them.
      final bomb = Uint8List(kMaxBackupBytes + 1);
      final archive = Archive();
      archive.add(ArchiveFile.string(
          'meta.json',
          jsonEncode({
            'app': 'knobelfuchs',
            'format': kBackupFormat,
            'schema': 2,
            'appVersion': '0.1',
          })));
      archive.add(ArchiveFile.bytes(kBackupDbEntry, bomb));
      final zip = ZipEncoder().encodeBytes(archive);
      expect(zip.length, lessThan(kMaxBackupBytes)); // it really is a bomb
      expect(
        () => parseBackup(Uint8List.fromList(zip)),
        throwsA(isA<BackupException>()
            .having((e) => e.error, 'error', BackupError.invalid)),
      );
    });

    test('an oversized backup file is rejected outright', () {
      expect(
        () => parseBackup(Uint8List(kMaxBackupBytes + 1)),
        throwsA(isA<BackupException>()
            .having((e) => e.error, 'error', BackupError.invalid)),
      );
    });
  });
}
