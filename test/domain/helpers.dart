import 'package:knobelfuchs/domain/board.dart';

/// Builds a board from whitespace-separated tokens: `5` = digit five,
/// `5c` = cleared ghost five. Ids are sequential from 0. Rows are implied
/// by the fixed width of 9 — give 9 tokens per row.
Board b(String spec) {
  final tokens =
      spec.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  var id = 0;
  return Board([
    for (final t in tokens)
      Cell(id: id++, digit: int.parse(t[0]), cleared: t.endsWith('c')),
  ]);
}

List<int> digitsOf(Board board) => [for (final c in board.cells) c.digit];
