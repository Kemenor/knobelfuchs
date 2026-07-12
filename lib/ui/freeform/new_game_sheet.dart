import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/game.dart';
import '../../domain/seed.dart';
import '../../l10n/app_localizations.dart';
import '../game/game_controller.dart';
import '../game/game_screen.dart';

/// Free Form parameter sheet (§6.1): one tap for players who don't care —
/// parameters are power, summoned not imposed.
Future<void> showNewGameSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _NewGameSheet(),
  );
}

class _NewGameSheet extends ConsumerStatefulWidget {
  const _NewGameSheet();

  @override
  ConsumerState<_NewGameSheet> createState() => _NewGameSheetState();
}

class _NewGameSheetState extends ConsumerState<_NewGameSheet> {
  final _seed = TextEditingController();
  final _target = TextEditingController();
  int? _adds = 5; // null = ∞
  int? _hints = 5;
  bool _targetOn = false;

  @override
  void dispose() {
    _seed.dispose();
    _target.dispose();
    super.dispose();
  }

  void _start() {
    var seed = normalizeSeed(_seed.text);
    if (seed.isEmpty) {
      // Random seeds are 6-digit strings — easy to read out loud (§2.1).
      seed = '${100000 + Random().nextInt(900000)}';
    }
    final target = _targetOn ? int.tryParse(_target.text.trim()) : null;
    final config = GameConfig(
      seed: seed,
      adds: _adds,
      hints: _hints,
      target: target,
    );
    ref.read(gameControllerProvider.notifier).start(config);
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final insets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + insets),
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
                  width: 120,
                  child: TextField(
                    controller: _target,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(isDense: true),
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
            onPressed: _start,
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56)),
            child: Text(l.startGame,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800)),
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
        onChanged(20);
      } else if (value! > 0) {
        onChanged(value! - 1);
      }
    }

    void plus() {
      if (value == null) return;
      onChanged(value! >= 20 ? null : value! + 1);
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
