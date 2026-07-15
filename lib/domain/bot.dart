/// The baseline bot (§4.1): plays first-valid-pair-in-reading-order, adds
/// when stuck, same add budget as the run, no hints. Deterministic — its
/// score defines the target on every device without a server.
library;

import 'game.dart';

/// Final score of the greedy bot on this config. The config must have a
/// finite add budget (Free Form targets are never computed, §4.1).
int botScore(GameConfig config) {
  assert(config.adds != null, 'bot requires a finite add budget');
  // The bot plays under the same scoring variant as the run (daily.dart's
  // contract) — dropping it here would compute targets under the wrong
  // formula the moment a playtest flips the variant.
  final state = GameState.fresh(
    GameConfig(
        seed: config.seed,
        adds: config.adds,
        hints: 0,
        scoring: config.scoring),
  );
  while (true) {
    if (state.board.isEmpty) break;
    final pair = state.board.firstPair();
    if (pair != null) {
      state.match(
        state.board.cells[pair.$1].id,
        state.board.cells[pair.$2].id,
      );
    } else if (!state.addRows()) {
      // Budget spent OR board ceiling reached (§3.4). Never gate on
      // addsRemaining alone: addRows can refuse at the ceiling with budget
      // left, and this loop must terminate on every config.
      break;
    }
  }
  return state.score;
}

int round10(num x) => (x / 10).round() * 10;

/// target = round10(botScore × factor) — §4.1.
int targetScore(GameConfig config, double factor) =>
    round10(botScore(config) * factor);
