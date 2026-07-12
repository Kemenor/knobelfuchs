/// Board difficulty by math (family request, 2026-07-12): run an ensemble of
/// seeded *random-policy* playouts and measure how forgiving the board is.
/// Random players (not the greedy bot) probe the board's intrinsic texture —
/// a board they clear often is easy for humans too. Fully deterministic:
/// playout k of a seed uses PRNG state hash(engineSeed, kPlayoutSalt + k),
/// so measurements reproduce on every machine.
library;

import 'game.dart';
import 'rng.dart';
import 'seed.dart';

const int _kPlayoutSalt = 0x5EED;

class SeedDifficulty {
  final String seed;

  /// Fraction of random playouts that cleared the board (higher = easier).
  final double clearRate;

  /// Mean surviving digits at run end (lower = easier).
  final double avgSurvivors;

  /// Available pairs on the opening board.
  final int openingPairs;

  const SeedDifficulty({
    required this.seed,
    required this.clearRate,
    required this.avgSurvivors,
    required this.openingPairs,
  });

  /// Single sortable score: clearing dominates, survivors break ties.
  double get score => clearRate * 1000 - avgSurvivors;

  @override
  String toString() =>
      '$seed  clear=${(clearRate * 100).toStringAsFixed(0)}% '
      'survivors=${avgSurvivors.toStringAsFixed(1)} pairs=$openingPairs';
}

/// Measure a seed with random-policy playouts under the given add budget.
SeedDifficulty measureSeed(
  String seed, {
  int adds = 5,
  int playouts = 24,
}) {
  final config = GameConfig(seed: seed, adds: adds, hints: 0);
  var cleared = 0;
  var survivorsSum = 0;
  int? openingPairs;

  for (var k = 0; k < playouts; k++) {
    final state = GameState.fresh(config);
    openingPairs ??= state.board.countAvailablePairs();
    final rng = SplitMix64(mixSeedAttempt(config.engineSeed, _kPlayoutSalt + k));
    while (true) {
      if (state.board.isEmpty) break;
      final pairs = state.board.availablePairs();
      if (pairs.isNotEmpty) {
        final pick = pairs[(rng.next() >>> 32) % pairs.length];
        state.match(
            state.board.cells[pick.$1].id, state.board.cells[pick.$2].id);
      } else if ((state.addsRemaining ?? 0) > 0) {
        state.addRows();
      } else {
        break;
      }
    }
    if (state.board.isEmpty) cleared++;
    survivorsSum += state.board.cells.where((c) => !c.cleared).length;
  }

  return SeedDifficulty(
    seed: seed,
    clearRate: cleared / playouts,
    avgSurvivors: survivorsSum / playouts,
    openingPairs: openingPairs ?? 0,
  );
}
