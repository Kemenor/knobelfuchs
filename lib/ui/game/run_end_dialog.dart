import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../domain/challenge.dart';
import '../../domain/game.dart';
import '../../l10n/app_localizations.dart';
import 'game_controller.dart';

/// Run end (§3.7): never "GAME OVER", never red. Stuck ends offer the quiet
/// way back onto the board; cleared ends celebrate once and rest.
Future<void> showRunEndDialog(BuildContext context, WidgetRef ref) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => const _RunEndDialog(),
  );
}

class _RunEndDialog extends ConsumerWidget {
  const _RunEndDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final view = ref.watch(gameControllerProvider);
    if (view == null) return const SizedBox.shrink();

    final cleared = view.status == GameStatus.cleared;
    final controller = ref.read(gameControllerProvider.notifier);
    const tabular = [FontFeature.tabularFigures()];

    String budget(int? b) => b == null ? '∞' : '$b';

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('🦊', style: const TextStyle(fontSize: 40),
                  textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(
                cleared ? l.runClearedTitle : l.runStuckTitle,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              if (!cleared)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(l.runStuckBody,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                      textAlign: TextAlign.center),
                ),
              const SizedBox(height: 8),
              Text('${view.score}',
                  style: const TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      fontFeatures: tabular),
                  textAlign: TextAlign.center),
              if (view.config.target != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    view.targetBeaten
                        ? l.targetBeaten(view.config.target!)
                        : l.targetMissed(view.config.target!, view.score),
                    style: TextStyle(
                      color: view.targetBeaten
                          ? scheme.tertiary // emerald = achieved
                          : scheme.onSurfaceVariant, // calm, never red
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 16),
              _StatRow(label: l.statPairs, value: '${view.pairsMatched}'),
              _StatRow(label: l.statRows, value: '${view.rowsCleared}'),
              _StatRow(
                  label: l.statAdds,
                  value: l.ofBudget(
                      view.addsUsed, budget(view.config.adds))),
              _StatRow(
                  label: l.statHints,
                  value: l.ofBudget(
                      view.hintsUsed, budget(view.config.hints))),
              if (view.slot == kFreeSlot && view.score > 0) ...[
                const SizedBox(height: 14),
                _ChallengeCard(view: view),
              ],
              const SizedBox(height: 20),
              if (!cleared)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ref.read(gameControllerProvider.notifier).undo();
                  },
                  child: Text(l.backToBoard),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        controller.quit(); // GameScreen pops itself
                      },
                      child: Text(l.toMenu),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        controller.start(view.config); // same seed, retry
                      },
                      child: Text(l.again),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Beat me on this board" (§7): the QR carries seed + budgets + this run's
/// score as the target. Peer-to-peer, no server — the QR *is* the challenge.
class _ChallengeCard extends StatelessWidget {
  final GameView view;
  const _ChallengeCard({required this.view});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final challenge = encodeChallenge(GameConfig(
      seed: view.config.seed,
      adds: view.config.adds,
      hints: view.config.hints,
      target: view.score,
    ));
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white, // QR needs its own contrast island
              borderRadius: BorderRadius.circular(8),
            ),
            child: QrImageView(
              data: challenge.toString(),
              size: 96,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.shareChallenge,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  l.shareChallengeBody,
                  style: TextStyle(
                      fontSize: 12, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: scheme.onSurfaceVariant)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}
