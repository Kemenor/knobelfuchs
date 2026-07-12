/// Curates the 50 adventure seeds: measure candidate seeds with random-
/// policy playouts, sort by difficulty, pick 10 per chapter from the five
/// quantile bands (very easy → very hard). Prints the Dart const list for
/// lib/domain/adventure.dart.
///
/// Usage: dart run tool/curate_levels.dart [candidates] [playouts]
library;

// ignore_for_file: avoid_print

import 'package:knobelfuchs/domain/difficulty.dart';

void main(List<String> args) {
  final candidates = args.isNotEmpty ? int.parse(args[0]) : 300;
  final playouts = args.length > 1 ? int.parse(args[1]) : 24;

  print('Measuring $candidates candidates × $playouts playouts …');
  final sw = Stopwatch()..start();
  final measured = <SeedDifficulty>[
    for (var i = 0; i < candidates; i++)
      measureSeed('level:s$i', playouts: playouts),
  ];
  print('done in ${sw.elapsed.inSeconds}s\n');

  // Easiest first.
  measured.sort((a, b) => b.score.compareTo(a.score));

  const tiers = ['very easy', 'easy', 'medium', 'hard', 'very hard'];
  final picks = <SeedDifficulty>[];
  final band = measured.length / 5;
  for (var chapter = 0; chapter < 5; chapter++) {
    // 10 seeds spread evenly across this chapter's difficulty band.
    print('— Chapter ${chapter + 1} (${tiers[chapter]}) —');
    for (var j = 0; j < 10; j++) {
      final idx = (chapter * band + (j + .5) * band / 10).floor();
      final pick = measured[idx.clamp(0, measured.length - 1)];
      picks.add(pick);
      print('  L${chapter * 10 + j + 1}: $pick');
    }
  }

  print('\n// Paste into lib/domain/adventure.dart:');
  print('const List<String> kAdventureSeeds = [');
  for (var c = 0; c < 5; c++) {
    print('  // Chapter ${c + 1}: ${tiers[c]}');
    final row = picks
        .sublist(c * 10, c * 10 + 10)
        .map((p) => "'${p.seed}'")
        .join(', ');
    print('  $row,');
  }
  print('];');
}
