/// Local backup/restore (§9.1): the whole game state is one SQLite file plus
/// a handful of SharedPreferences — zipped into a single shareable file the
/// player owns. No server, no account: moving devices = share the file,
/// import it (fuchsbau family pattern, same as knabberfuchs's planned ZIP
/// backup). This module is pure bytes-in/bytes-out — I/O lives in
/// ui/settings/backup_actions.dart.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Bump when the zip layout changes; older apps refuse newer formats.
const int kBackupFormat = 1;

/// Hard ceiling for a backup file and its decompressed entries. The real
/// database is a few hundred KB; anything near this is not one of ours.
/// Checked before decompression so a zip bomb can't OOM the import
/// (§9.1: hostile files are rejected, never obeyed).
const int kMaxBackupBytes = 64 * 1024 * 1024;
const String kBackupDbEntry = 'knobelfuchs.sqlite';
const String _kMetaEntry = 'meta.json';
const String _kSettingsEntry = 'settings.json';

/// The first 16 bytes of every SQLite database file.
const List<int> _sqliteMagic = [
  0x53, 0x51, 0x4C, 0x69, 0x74, 0x65, 0x20, 0x66, // "SQLite f"
  0x6F, 0x72, 0x6D, 0x61, 0x74, 0x20, 0x33, 0x00, // "ormat 3\0"
];

enum BackupError {
  /// Not a zip, or missing/foreign meta — not one of ours.
  invalid,

  /// Format or database schema newer than this app understands.
  tooNew,
}

class BackupException implements Exception {
  final BackupError error;
  const BackupException(this.error);
  @override
  String toString() => 'BackupException(${error.name})';
}

class BackupContents {
  final Uint8List dbBytes;
  final Map<String, Object?> settings;
  final int schemaVersion;
  const BackupContents({
    required this.dbBytes,
    required this.settings,
    required this.schemaVersion,
  });
}

/// Settings are typed explicitly so import restores exactly what
/// SharedPreferences held (bool/int/double/String/List&lt;String&gt;).
Map<String, dynamic> _encodeSettings(Map<String, Object?> raw) {
  final out = <String, dynamic>{};
  raw.forEach((k, v) {
    switch (v) {
      case bool b:
        out[k] = {'t': 'bool', 'v': b};
      case int i:
        out[k] = {'t': 'int', 'v': i};
      case double d:
        out[k] = {'t': 'double', 'v': d};
      case String s:
        out[k] = {'t': 'string', 'v': s};
      case List<Object?> l:
        out[k] = {'t': 'stringList', 'v': l.whereType<String>().toList()};
      default:
        break; // unknown type — skip rather than corrupt
    }
  });
  return out;
}

Map<String, Object?> _decodeSettings(Map<String, dynamic> encoded) {
  final out = <String, Object?>{};
  encoded.forEach((k, e) {
    if (e is! Map) return;
    final v = e['v'];
    out[k] = switch (e['t']) {
      'bool' => v is bool ? v : null,
      'int' => v is num ? v.toInt() : null,
      'double' => v is num ? v.toDouble() : null,
      'string' => v is String ? v : null,
      'stringList' =>
        v is List ? v.whereType<String>().toList() : null,
      _ => null,
    };
    if (out[k] == null) out.remove(k);
  });
  return out;
}

Uint8List buildBackup({
  required Uint8List dbBytes,
  required Map<String, Object?> settings,
  required int schemaVersion,
  required String appVersion,
}) {
  final archive = Archive();
  archive.add(ArchiveFile.string(
      _kMetaEntry,
      jsonEncode({
        'app': 'knobelfuchs',
        'format': kBackupFormat,
        'schema': schemaVersion,
        'appVersion': appVersion,
      })));
  archive.add(
      ArchiveFile.string(_kSettingsEntry, jsonEncode(_encodeSettings(settings))));
  archive.add(ArchiveFile.bytes(kBackupDbEntry, dbBytes));
  return ZipEncoder().encodeBytes(archive);
}

/// Parses and validates a backup. Throws [BackupException]; the caller still
/// has to compare [BackupContents.schemaVersion] against the running app's
/// database schema (a newer schema must be rejected as [BackupError.tooNew]).
BackupContents parseBackup(Uint8List zipBytes) {
  if (zipBytes.length > kMaxBackupBytes) {
    throw const BackupException(BackupError.invalid);
  }

  // Deliberately NO verify=true: that pass decompresses every entry
  // (including junk ones a hostile zip may carry) just to compare CRCs,
  // which is exactly what a zip bomb wants. Instead: gate on the declared
  // header sizes, then lazily inflate only the three entries we actually
  // read — corruption is caught by the guarded reads here plus the
  // downstream validators (JSON parse, SQLite magic, user_version
  // cross-check, and applyBackup's probe-query-with-rollback).
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(zipBytes);
  } catch (_) {
    throw const BackupException(BackupError.invalid);
  }
  var declared = 0;
  for (final f in archive.files) {
    if (f.size < 0) throw const BackupException(BackupError.invalid);
    declared += f.size;
    if (declared > kMaxBackupBytes) {
      throw const BackupException(BackupError.invalid);
    }
  }

  Uint8List? entry(String name) {
    for (final f in archive.files) {
      if (f.name == name) {
        try {
          return f.readBytes();
        } catch (_) {
          // Corrupt deflate stream — not a readable backup.
          throw const BackupException(BackupError.invalid);
        }
      }
    }
    return null;
  }

  final metaBytes = entry(_kMetaEntry);
  final dbBytes = entry(kBackupDbEntry);
  if (metaBytes == null || dbBytes == null) {
    throw const BackupException(BackupError.invalid);
  }

  final Map<String, dynamic> meta;
  try {
    meta = jsonDecode(utf8.decode(metaBytes)) as Map<String, dynamic>;
  } catch (_) {
    throw const BackupException(BackupError.invalid);
  }
  if (meta['app'] != 'knobelfuchs' || meta['format'] is! int) {
    throw const BackupException(BackupError.invalid);
  }
  if ((meta['format'] as int) > kBackupFormat) {
    throw const BackupException(BackupError.tooNew);
  }
  final schema = meta['schema'];
  if (schema is! int) throw const BackupException(BackupError.invalid);

  // A real SQLite file starts with a 100-byte header.
  if (dbBytes.length < 100) {
    throw const BackupException(BackupError.invalid);
  }
  for (var i = 0; i < _sqliteMagic.length; i++) {
    if (dbBytes[i] != _sqliteMagic[i]) {
      throw const BackupException(BackupError.invalid);
    }
  }

  // meta.json must agree with the database's own PRAGMA user_version
  // (big-endian at header offset 60). A lying meta would either bypass the
  // tooNew gate or re-run migrations onto a database that already has the
  // columns — a crash loop on every launch after the swap.
  final fileSchema = (dbBytes[60] << 24) |
      (dbBytes[61] << 16) |
      (dbBytes[62] << 8) |
      dbBytes[63];
  if (fileSchema != schema) {
    throw const BackupException(BackupError.invalid);
  }

  var settings = const <String, Object?>{};
  final settingsBytes = entry(_kSettingsEntry);
  if (settingsBytes != null) {
    try {
      settings = _decodeSettings(
          jsonDecode(utf8.decode(settingsBytes)) as Map<String, dynamic>);
    } catch (_) {
      settings = const {}; // a broken settings blob must not block the runs
    }
  }

  return BackupContents(
      dbBytes: dbBytes, settings: settings, schemaVersion: schema);
}
