/// Dev tool: print a daily board + computed target.
/// Usage: dart run tool/daily_preview.dart [yyyy-mm-dd]
library;

import 'package:knobelfuchs/domain/bot.dart';
import 'package:knobelfuchs/domain/daily.dart';
import 'package:knobelfuchs/domain/game.dart';

void main(List<String> args) {
  final date = args.isEmpty ? DateTime.now() : DateTime.parse(args.first);
  final config = dailyConfig(date);
  final state = GameState.fresh(config);

  print('Tages-Knobel ${dailySeedKey(date)}');
  final cells = state.board.cells;
  for (var r = 0; r * 9 < cells.length; r++) {
    final row = cells.skip(r * 9).take(9).map((c) => c.digit).join(' ');
    print('  $row');
  }
  print('Paare am Start: ${state.board.countAvailablePairs()}');
  print('Bot-Score: ${botScore(config)} → Ziel (×0.9): ${config.target}');
}
