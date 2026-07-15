import 'dart:typed_data';

/// A minimal fake SQLite payload: the real 100-byte header shape with the
/// 16-byte magic, the big-endian user_version at offset 60, filler
/// elsewhere. Shared by the parse tests and the applyBackup swap tests so
/// the header contract lives in exactly one place.
Uint8List fakeDb({int filler = 0x42, int userVersion = 2}) {
  final bytes = Uint8List(128);
  const magic = 'SQLite format 3';
  for (var i = 0; i < magic.length; i++) {
    bytes[i] = magic.codeUnitAt(i);
  }
  bytes[15] = 0;
  for (var i = 16; i < bytes.length; i++) {
    bytes[i] = filler;
  }
  bytes.buffer.asByteData().setUint32(60, userVersion);
  return bytes;
}
