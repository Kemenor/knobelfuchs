import 'package:flutter/material.dart';

import '../../domain/board.dart';
import '../../domain/constants.dart';
import 'game_controller.dart';

const double _maxCell = 72; // DESIGN_SYSTEM §2 — Pad-5 target size
const double _gap = 6;

/// The 9-wide grid. Cells are addressed by stable id; states are pure colour:
/// selection indigo, sticky hint orange, ghosts faded & struck. Between
/// responses the board is perfectly still (§9).
class BoardView extends StatelessWidget {
  final GameView view;
  final ScrollController controller;
  final Duration cellAnimation; // from the motion setting (§10.2)
  final ValueChanged<double> onRowExtent;
  final ValueChanged<int> onTap;

  const BoardView({
    super.key,
    required this.view,
    required this.controller,
    this.cellAnimation = const Duration(milliseconds: 150),
    required this.onRowExtent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final cell = ((constraints.maxWidth - (kColumns - 1) * _gap) / kColumns)
          .clamp(24.0, _maxCell);
      final rowExtent = cell + _gap;
      onRowExtent(rowExtent);
      final width = cell * kColumns + (kColumns - 1) * _gap;
      final rows = view.board.rowCount;

      return Center(
        child: SizedBox(
          width: width,
          child: ListView.builder(
            controller: controller,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: rows,
            itemExtent: rowExtent,
            itemBuilder: (context, r) => _RowView(
              board: view.board,
              row: r,
              cellSize: cell,
              animation: cellAnimation,
              selectedId: view.selectedId,
              hintCellIds: view.hintCellIds,
              justMatchedIds: view.justMatchedIds,
              onTap: onTap,
            ),
          ),
        ),
      );
    });
  }
}

class _RowView extends StatelessWidget {
  final Board board;
  final int row;
  final double cellSize;
  final Duration animation;
  final int? selectedId;
  final Set<int> hintCellIds;
  final Set<int> justMatchedIds;
  final ValueChanged<int> onTap;

  const _RowView({
    required this.board,
    required this.row,
    required this.cellSize,
    required this.animation,
    required this.selectedId,
    required this.hintCellIds,
    required this.justMatchedIds,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final start = row * kColumns;
    final end = (start + kColumns).clamp(0, board.cells.length);
    return Row(
      children: [
        for (var i = start; i < end; i++) ...[
          if (i > start) const SizedBox(width: _gap),
          _CellView(
            cell: board.cells[i],
            size: cellSize,
            animation: animation,
            selected: board.cells[i].id == selectedId,
            hinted: hintCellIds.contains(board.cells[i].id),
            justMatched: justMatchedIds.contains(board.cells[i].id),
            onTap: onTap,
          ),
        ],
      ],
    );
  }
}

class _CellView extends StatelessWidget {
  final Cell cell;
  final double size;
  final Duration animation;
  final bool selected;
  final bool hinted;
  final bool justMatched;
  final ValueChanged<int> onTap;

  const _CellView({
    required this.cell,
    required this.size,
    required this.animation,
    required this.selected,
    required this.hinted,
    required this.justMatched,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    late final Color bg, border, ink;
    if (cell.cleared && justMatched) {
      // Mockup 07: the pair pops emerald, then fades to ghosts.
      bg = scheme.tertiaryContainer;
      border = scheme.tertiary;
      ink = scheme.tertiary;
    } else if (cell.cleared) {
      bg = Colors.transparent;
      border = scheme.outlineVariant;
      ink = scheme.outline.withValues(alpha: .55);
    } else if (selected) {
      bg = scheme.secondaryContainer; // indigo = selection (Fuchsbau law)
      border = scheme.secondary;
      ink = scheme.secondary;
    } else if (hinted) {
      bg = scheme.primaryContainer; // orange = hint, sticky until tapped
      border = scheme.primary;
      ink = scheme.primary;
    } else {
      bg = scheme.surfaceContainerHighest;
      border = scheme.outlineVariant;
      ink = scheme.onSurface;
    }

    return GestureDetector(
      onTap: cell.cleared ? null : () => onTap(cell.id),
      child: AnimatedContainer(
        duration: animation,
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: border,
            width: (selected || hinted) ? 2 : 1,
          ),
        ),
        child: Text(
          '${cell.digit}',
          style: TextStyle(
            fontSize: size * .5,
            fontWeight: FontWeight.w700,
            color: ink,
            decoration: (cell.cleared && !justMatched)
                ? TextDecoration.lineThrough
                : null,
            decorationColor: ink,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
