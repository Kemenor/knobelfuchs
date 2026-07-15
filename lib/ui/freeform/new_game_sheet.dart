import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/constants.dart';
import '../../domain/game.dart';
import '../../domain/seed.dart';
import '../../l10n/app_localizations.dart';
import '../game/game_controller.dart';
import '../game/game_screen.dart';
import '../single_flight.dart';
import 'scan_challenge_screen.dart';

/// Free Form parameter sheet (§6.1): one tap for players who don't care —
/// parameters are power, summoned not imposed. Pass [pushGameScreen] false
/// when the sheet is opened from *within* the game screen (§12's "new game
/// anyway" path) — the controller swap re-renders the screen in place.
/// [prefill] carries a scanned/deep-linked challenge (§7) — still editable,
/// never auto-started. [skipDiscardGuard] is for callers that have ALREADY
/// shown the §6.1 discard confirmation (the in-game restart button); every
/// other path gets it from the sheet itself.
Future<void> showNewGameSheet(BuildContext context,
    {bool pushGameScreen = true,
    GameConfig? prefill,
    bool skipDiscardGuard = false}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _NewGameSheet(
        pushGameScreen: pushGameScreen,
        prefill: prefill,
        skipDiscardGuard: skipDiscardGuard),
  );
}

/// The §6.1 calm discard confirmation — the ONE implementation for every
/// path that would overwrite a live run (sheet start, in-game restart), so
/// the wording and styling can never drift between them.
Future<bool> confirmDiscardRun(BuildContext context, int score) async {
  final l = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l.discardTitle),
      content: Text(l.discardBody(score)),
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
  return confirmed == true;
}

class _NewGameSheet extends ConsumerStatefulWidget {
  final bool pushGameScreen;
  final GameConfig? prefill;
  final bool skipDiscardGuard;
  const _NewGameSheet(
      {required this.pushGameScreen,
      this.prefill,
      this.skipDiscardGuard = false});

  @override
  ConsumerState<_NewGameSheet> createState() => _NewGameSheetState();
}

class _NewGameSheetState extends ConsumerState<_NewGameSheet> {
  final _seed = TextEditingController();
  final _target = TextEditingController();
  int? _adds = 5; // null = ∞
  int? _hints = 5;
  bool _targetOn = false;

  int? get _parsedTarget => int.tryParse(_target.text.trim());

  /// No board can pay more than [kMaxScore] (§4) — a higher target is a typo,
  /// not a challenge. Also guards QR payloads.
  bool get _targetTooHigh => _targetOn && (_parsedTarget ?? 0) > kMaxScore;

  /// The switch is on but the field holds no usable number (empty, garbage,
  /// zero or negative) — starting now would silently launch a run that
  /// contradicts the visible switch state.
  bool get _targetMissing => _targetOn && (_parsedTarget ?? 0) < 1;

  @override
  void initState() {
    super.initState();
    _target.addListener(() => setState(() {})); // live max validation
    final p = widget.prefill;
    if (p != null) {
      _seed.text = p.seed;
      _adds = p.adds;
      _hints = p.hints;
      if (p.target != null) {
        _targetOn = true;
        _target.text = '${p.target}';
      }
    }
  }

  @override
  void dispose() {
    _seed.dispose();
    _target.dispose();
    super.dispose();
  }

  final _flight = SingleFlight(); // double-tap guard across the discard dialog

  Future<void> _start() => _flight.run(() async {
        // §6.1 (frozen): "starting a new game over a live run confirms
        // calmly first". The guard lives HERE, next to the destructive
        // start — not only on the in-game restart button — so the
        // deep-link, scan and home-card paths can't silently overwrite the
        // free autosave.
        if (!widget.skipDiscardGuard) {
          final live = ref.read(gameControllerProvider);
          final liveScore =
              live != null && live.slot == kFreeSlot ? live.score : null;
          // The DB is the source of truth; the provider may still be loading.
          final savedScore = liveScore ??
              (await ref.read(gameRepositoryProvider).loadSummary(kFreeSlot))
                  ?.score;
          if (savedScore != null) {
            if (!mounted) return;
            if (!await confirmDiscardRun(context, savedScore)) return;
          }
        }
        if (!mounted) return;

        var seed = normalizeSeed(_seed.text);
        if (seed.isEmpty) {
          // Random seeds are 6-digit strings — easy to read out loud (§2.1).
          seed = '${100000 + Random().nextInt(900000)}';
        }
        final target = _targetOn ? _parsedTarget : null;
        final config = GameConfig(
          seed: seed,
          adds: _adds,
          hints: _hints,
          target: target,
        );
        ref.read(gameControllerProvider.notifier).start(config);
        Navigator.of(context).pop();
        if (widget.pushGameScreen) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const GameScreen()),
          );
        }
      });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final insets = MediaQuery.viewInsetsOf(context).bottom; // keyboard
    // System navigation bar (3-button nav swallowed the scan button).
    final safe = MediaQuery.viewPaddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 16 + insets + safe),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(l.newGameTitle,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          TextField(
            controller: _seed,
            decoration: InputDecoration(
              labelText: l.seedFieldLabel,
              helperText: l.seedFieldHelper,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          _Stepper(
            label: l.addsLabel,
            value: _adds,
            onChanged: (v) => setState(() => _adds = v),
          ),
          _Stepper(
            label: l.hintsLabel,
            value: _hints,
            onChanged: (v) => setState(() => _hints = v),
          ),
          Row(
            children: [
              Expanded(
                child: Text(l.targetLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              if (_targetOn)
                SizedBox(
                  width: 140,
                  child: TextField(
                    controller: _target,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      isDense: true,
                      // Calm gray, not error red: "a target no board can pay
                      // is a typo, not a challenge" — red is reserved for
                      // destructive actions. The disabled start button
                      // already blocks submission.
                      helperText: _targetTooHigh
                          ? l.targetTooHigh(kMaxScore)
                          : null,
                    ),
                    textAlign: TextAlign.end,
                  ),
                )
              else
                Text(l.targetOff,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700)),
              Switch(
                value: _targetOn,
                onChanged: (v) => setState(() => _targetOn = v),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _targetTooHigh || _targetMissing ? null : _start,
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56)),
            child: Text(l.startGame,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800)),
          ),
          TextButton.icon(
            onPressed: () async {
              final config = await Navigator.of(context).push<GameConfig>(
                MaterialPageRoute(
                    builder: (_) => const ScanChallengeScreen()),
              );
              if (config != null && mounted) {
                setState(() {
                  _seed.text = config.seed;
                  _adds = config.adds;
                  _hints = config.hints;
                  _targetOn = config.target != null;
                  _target.text =
                      config.target != null ? '${config.target}' : '';
                });
              }
            },
            icon: const Icon(Icons.qr_code_scanner),
            label: Text(l.scanChallenge),
          ),
        ],
      ),
    );
  }
}

/// 0 … 20, then ∞ (§6.1).
class _Stepper extends StatelessWidget {
  final String label;
  final int? value; // null = ∞
  final ValueChanged<int?> onChanged;
  const _Stepper({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    void minus() {
      if (value == null) {
        onChanged(kMaxBudget);
      } else if (value! > 0) {
        onChanged(value! - 1);
      }
    }

    void plus() {
      if (value == null) return;
      onChanged(value! >= kMaxBudget ? null : value! + 1);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          IconButton.outlined(
            onPressed: value != null && value! == 0 ? null : minus,
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 48,
            child: Text(
              value == null ? '∞' : '$value',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          IconButton.outlined(
            onPressed: value == null ? null : plus,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
