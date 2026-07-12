/// Bakes the 50 adventure target scores: everything they depend on (seed,
/// budgets, factor, scoring) is fixed, so the bot runs ONCE here instead of
/// 50× on every level-list build on-device. A drift-guard test recomputes
/// them, so a target can never silently change.
///
/// Usage: dart run tool/bake_targets.dart → paste into adventure.dart.
library;

// ignore_for_file: avoid_print

import 'package:knobelfuchs/domain/adventure.dart';
import 'package:knobelfuchs/domain/bot.dart';
import 'package:knobelfuchs/domain/difficulty.dart';
import 'package:knobelfuchs/domain/game.dart';

void main() {
  final targets = <int>[];
  final p75 = <int>[];
  for (var level = 1; level <= kAdventureLevels; level++) {
    final base = GameConfig(
      seed: adventureSeedKey(level),
      adds: adventureAdds(level),
      hints: adventureHints(level),
    );
    targets.add(targetScore(base, adventureFactor(level)));
    p75.add(quantileTarget(base));
  }

  void table(String name, List<int> values) {
    print('const List<int> $name = [');
    for (var c = 0; c < kAdventureLevels ~/ kChapterLength; c++) {
      final row = values
          .sublist(c * kChapterLength, (c + 1) * kChapterLength)
          .join(', ');
      print('  $row, // chapter ${c + 1}');
    }
    print('];');
  }

  table('kAdventureTargets', targets);
  print('');
  table('kAdventureP75', p75);
}
