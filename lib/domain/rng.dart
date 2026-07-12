/// Deterministic PRNG — SplitMix64. Hand-rolled so every device deals the
/// same board from the same seed, independent of Dart's `Random`.
library;

class SplitMix64 {
  int _state;
  SplitMix64(int seed) : _state = seed;

  int next() {
    _state += 0x9E3779B97F4A7C15; // wraps (64-bit VM ints)
    var z = _state;
    z = (z ^ (z >>> 30)) * 0xBF58476D1CE4E5B9;
    z = (z ^ (z >>> 27)) * 0x94D049BB133111EB;
    return z ^ (z >>> 31);
  }

  /// Uniform-ish digit 1..9 (modulo bias over 32 bits: ~1e-9, irrelevant here).
  int nextDigit() => 1 + ((next() >>> 32) % 9);
}
