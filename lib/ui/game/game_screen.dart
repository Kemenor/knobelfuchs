import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/constants.dart';
import '../../domain/game.dart';
import '../../l10n/app_localizations.dart';
import 'board_view.dart';
import 'game_controller.dart';
import 'run_end_dialog.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  final _scroll = ScrollController();
  double _rowExtent = 56; // updated by BoardView's layout callback
  bool _endShown = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Scroll policy (§10.2): the view only follows the player's own action.
  void _onViewChange(GameView? prev, GameView? next) {
    if (prev == null || next == null) return;
    if (next.addsUsed > prev.addsUsed) {
      // Nachlegen: bring the first appended row into view.
      final row = prev.board.cells.length ~/ kColumns;
      _animateToRow(row);
    } else if (next.addsUsed < prev.addsUsed) {
      // Undo of an add: scroll back to the previous end.
      final row =
          (next.board.cells.length ~/ kColumns) - 1;
      _animateToRow(row < 0 ? 0 : row);
    }
    if (next.status != GameStatus.playing &&
        prev.status == GameStatus.playing &&
        !_endShown) {
      _endShown = true;
      showRunEndDialog(context, ref).then((_) => _endShown = false);
    }
  }

  void _animateToRow(int row) {
    if (!_scroll.hasClients) return;
    final target = (row * _rowExtent)
        .clamp(0.0, _scroll.position.maxScrollExtent);
    final reduced = MediaQuery.of(context).disableAnimations;
    if (reduced) {
      _scroll.jumpTo(target);
    } else {
      _scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<GameView?>(gameControllerProvider, _onViewChange);
    final view = ref.watch(gameControllerProvider);
    if (view == null) {
      // Game ended and was quit — leave the screen.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final landscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final board = BoardView(
      view: view,
      controller: _scroll,
      onRowExtent: (extent) => _rowExtent = extent,
      onTap: (id) => ref.read(gameControllerProvider.notifier).tapCell(id),
    );

    return Scaffold(
      body: SafeArea(
        child: landscape
            ? Row(
                children: [
                  Expanded(child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
                    child: board,
                  )),
                  SizedBox(width: 224, child: _Rail(view: view)),
                ],
              )
            : Column(
                children: [
                  _TopBar(view: view),
                  Expanded(child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: board,
                  )),
                  _ActionBar(view: view),
                ],
              ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final GameView view;
  const _TopBar({required this.view});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(
        children: [
          const BackButton(),
          _ModeChip(view: view),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l.seedShort(view.config.seed),
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 12,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _Score(view: view),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final GameView view;
  const _ModeChip({required this.view});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        l.modeFree.toUpperCase(),
        style: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: .5,
        ),
      ),
    );
  }
}

class _Score extends StatelessWidget {
  final GameView view;
  const _Score({required this.view});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    const tabular = [FontFeature.tabularFigures()];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(l.score.toUpperCase(),
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .5,
                    color: scheme.onSurfaceVariant)),
            Text('${view.score}',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    fontFeatures: tabular)),
          ],
        ),
        if (view.config.target != null) ...[
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(l.target.toUpperCase(),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .5,
                      color: scheme.onSurfaceVariant)),
              Text('${view.config.target}',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                      fontFeatures: tabular)),
            ],
          ),
        ],
      ],
    );
  }
}

/// Landscape: stats + actions under the right thumb (DESIGN_SYSTEM §3).
class _Rail extends StatelessWidget {
  final GameView view;
  const _Rail({required this.view});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [const BackButton(), _ModeChip(view: view)]),
          const SizedBox(height: 12),
          _Score(view: view),
          const Spacer(),
          _ActionBar(view: view, vertical: true),
        ],
      ),
    );
  }
}

class _ActionBar extends ConsumerWidget {
  final GameView view;
  final bool vertical;
  const _ActionBar({required this.view, this.vertical = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final controller = ref.read(gameControllerProvider.notifier);

    String budget(int? n) => n == null ? '∞' : '$n';

    final buttons = [
      _ActionButton(
        icon: Icons.add_circle_outline,
        label: l.actionAdd,
        count: budget(view.addsRemaining),
        enabled: view.addsRemaining == null || view.addsRemaining! > 0,
        onPressed: controller.addRows,
      ),
      _ActionButton(
        icon: Icons.lightbulb_outline,
        label: l.actionHint,
        count: budget(view.hintsRemaining),
        enabled: view.hintsRemaining == null || view.hintsRemaining! > 0,
        onPressed: () {
          final outcome = controller.requestHint();
          if (outcome == HintOutcome.nonePossible && context.mounted) {
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(SnackBar(
                content: Text(l.hintNonePossible),
                behavior: SnackBarBehavior.floating,
              ));
          }
        },
      ),
      _ActionButton(
        icon: Icons.undo,
        label: l.actionUndo,
        count: null,
        enabled: view.addsUsed > 0 || view.pairsMatched > 0,
        onPressed: controller.undo,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(12),
      child: vertical
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final b in buttons)
                  Padding(padding: const EdgeInsets.only(top: 10), child: b),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final b in buttons)
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: b),
              ],
            ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? count;
  final bool enabled;
  final VoidCallback onPressed;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.count,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Gray = quietly unavailable — never red, never disabled-dead (§3.4).
    final color = enabled ? scheme.secondary : scheme.outline;
    final fill = enabled
        ? scheme.secondaryContainer
        : scheme.outlineVariant.withValues(alpha: .4);
    return Semantics(
      button: true,
      label: count == null ? label : '$label ($count)',
      child: Material(
        color: fill,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: enabled ? onPressed : null,
          child: Container(
            constraints: const BoxConstraints(minWidth: 88, minHeight: 60),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 26),
                const SizedBox(width: 8),
                Text(label,
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.w700)),
                if (count != null) ...[
                  const SizedBox(width: 6),
                  Text(count!,
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [
                            FontFeature.tabularFigures()
                          ])),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
