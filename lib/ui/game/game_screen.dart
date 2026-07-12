import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/constants.dart';
import '../../domain/game.dart';
import '../../l10n/app_localizations.dart';
import '../audio/audio_service.dart';
import '../freeform/new_game_sheet.dart';
import '../settings/settings.dart';
import 'board_view.dart';
import 'game_controller.dart';
import 'run_end_dialog.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with WidgetsBindingObserver {
  final _scroll = ScrollController();
  double _rowExtent = 56; // updated by BoardView's layout callback
  bool _endShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Music only during a foregrounded game (§10.1).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final view = ref.read(gameControllerProvider);
      if (view != null) {
        ref
            .read(audioServiceProvider)
            .startMusicFor(slot: view.slot, seed: view.config.seed);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ref.read(audioServiceProvider).stopMusic();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final audio = ref.read(audioServiceProvider);
    if (state == AppLifecycleState.resumed) {
      audio.resumeMusic();
    } else {
      audio.pauseMusic(); // never from the background, never a lure
    }
  }

  /// Sounds answer the player's action (§10) — priority: the loud moment,
  /// then row chime, then match, then add, then plain selection.
  void _playFor(GameView prev, GameView next) {
    final audio = ref.read(audioServiceProvider);
    if (next.status == GameStatus.cleared &&
        prev.status != GameStatus.cleared) {
      audio.play(SoundEvent.boardCleared);
    } else if (next.status == GameStatus.stuck &&
        prev.status == GameStatus.playing &&
        next.isAdventure &&
        next.targetBeaten) {
      audio.play(SoundEvent.levelUnlocked);
    } else if (next.rowsCleared > prev.rowsCleared) {
      audio.play(SoundEvent.rowCleared);
    } else if (next.pairsMatched > prev.pairsMatched) {
      audio.play(SoundEvent.match);
    } else if (next.addsUsed > prev.addsUsed) {
      audio.play(SoundEvent.addRows);
    } else if (next.selectedId != null &&
        next.selectedId != prev.selectedId) {
      audio.play(SoundEvent.select);
    }
  }

  /// Scroll policy (§10.2): the view only follows the player's own action.
  void _onViewChange(GameView? prev, GameView? next) {
    if (prev == null || next == null) return;
    if (prev.slot != next.slot || prev.config.seed != next.config.seed) {
      // New game started in place ("Nochmal" / new-game sheet) — fresh track.
      ref
          .read(audioServiceProvider)
          .startMusicFor(slot: next.slot, seed: next.config.seed);
    }
    _playFor(prev, next);
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
    // §10.2: instant jump under Reduziert/Aus.
    final motion = ref.read(settingsProvider).effectiveMotion(context);
    if (motion == MotionMode.full) {
      _scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      _scroll.jumpTo(target);
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
    final motion =
        ref.watch(settingsProvider).effectiveMotion(context);
    final board = BoardView(
      view: view,
      controller: _scroll,
      cellAnimation: switch (motion) {
        MotionMode.full => const Duration(milliseconds: 150),
        MotionMode.reduced => const Duration(milliseconds: 60),
        MotionMode.off => Duration.zero,
      },
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

/// Daily runs show their date, adventure runs their level — never the
/// internal seed keys (§2.1).
String _subtitle(BuildContext context, GameView view) {
  final l = AppLocalizations.of(context)!;
  if (view.isDaily) {
    final raw = view.config.seed.substring('daily:'.length); // yyyymmdd
    final date = DateTime(
      int.parse(raw.substring(0, 4)),
      int.parse(raw.substring(4, 6)),
      int.parse(raw.substring(6, 8)),
    );
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMMd(locale).format(date);
  }
  if (view.isAdventure) return l.levelN(view.adventureLevel ?? 0);
  return l.seedShort(view.config.seed);
}

class _TopBar extends StatelessWidget {
  final GameView view;
  const _TopBar({required this.view});

  @override
  Widget build(BuildContext context) {
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
              _subtitle(context, view),
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 12,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _Score(view: view),
          const SizedBox(width: 4),
          _NewGameButton(view: view),
        ],
      ),
    );
  }
}

/// §12: "new game despite live run" lives here, behind a calm confirmation.
class _NewGameButton extends ConsumerWidget {
  final GameView view;
  const _NewGameButton({required this.view});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    return IconButton(
      tooltip: l.newGameTitle,
      icon: const Icon(Icons.restart_alt),
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l.discardTitle),
            content: Text(l.discardBody(view.score)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l.discard),
              ),
            ],
          ),
        );
        if (confirmed == true && context.mounted) {
          showNewGameSheet(context, pushGameScreen: false);
        }
      },
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
    // Mode hue lives in passive chrome only (DESIGN_SYSTEM §0):
    // Free Form orange, Daily indigo, Adventure emerald.
    final (hue, fill, label) = view.isDaily
        ? (scheme.secondary, scheme.secondaryContainer, l.modeDaily)
        : view.isAdventure
            ? (scheme.tertiary, scheme.tertiaryContainer, l.modeStory)
            : (scheme.primary, scheme.primaryContainer, l.modeFree);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: hue,
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
          Row(children: [
            const BackButton(),
            _ModeChip(view: view),
            const Spacer(),
            _NewGameButton(view: view),
          ]),
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
          final audio = ref.read(audioServiceProvider);
          final outcome = controller.requestHint();
          switch (outcome) {
            case HintOutcome.shown || HintOutcome.repulsed:
              audio.play(SoundEvent.hint);
            case HintOutcome.nonePossible || HintOutcome.exhausted:
              audio.play(SoundEvent.unavailable);
          }
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
