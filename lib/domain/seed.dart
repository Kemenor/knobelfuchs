/// Seed normalization and hashing (§2.1).
///
/// Seeds are strings — words or digits. The same normalized string must map to
/// the same board on every device forever, so the hash is a hand-rolled
/// FNV-1a: platform `hashCode` is NOT stable and must never leak in here.
library;

import 'dart:convert';

import 'package:unorm_dart/unorm_dart.dart' as unorm;

import 'constants.dart';

/// trim → Unicode NFC → lowercase → whitespace runs → single dash →
/// drop everything but letters/digits/dashes → collapse/trim dashes →
/// cap at [kMaxSeedLength] runes.
///
/// The app always displays (and QR-encodes) this normalized form.
String normalizeSeed(String raw) {
  var s = unorm.nfc(raw.trim()).toLowerCase();
  s = s.replaceAll(RegExp(r'\s+'), '-');
  s = s.replaceAll(RegExp(r'[^\p{L}\p{N}\-]', unicode: true), '');
  s = s.replaceAll(RegExp(r'--+'), '-');
  s = s.replaceAll(RegExp(r'^-+|-+$'), '');
  final runes = s.runes.toList();
  if (runes.length > kMaxSeedLength) {
    s = String.fromCharCodes(runes.take(kMaxSeedLength));
  }
  return s;
}

const int _fnvOffset = 0xcbf29ce484222325;
const int _fnvPrime = 0x100000001b3;

/// 64-bit FNV-1a. Relies on Dart VM ints being 64-bit two's complement with
/// wrapping multiplication (true on Android/iOS; this engine does not target
/// the web).
int fnv1a64(List<int> bytes) {
  var h = _fnvOffset;
  for (final b in bytes) {
    h ^= b & 0xff;
    h *= _fnvPrime;
  }
  return h;
}

/// Engine seed of a (normalized) seed string.
int seedHash(String normalizedSeed) => fnv1a64(utf8.encode(normalizedSeed));

List<int> _leBytes(int v) => [for (var i = 0; i < 8; i++) (v >> (8 * i)) & 0xff];

/// hash(seed, attempt) — the fairness-gate reroll salt (§2.2). Seed and
/// attempt are separate hash inputs, so a reroll can never collide with
/// another seed's (or another day's) board.
int mixSeedAttempt(int engineSeed, int attempt) =>
    fnv1a64([..._leBytes(engineSeed), ..._leBytes(attempt)]);
