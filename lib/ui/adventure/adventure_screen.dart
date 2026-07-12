import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/adventure.dart';
import '../../l10n/app_localizations.dart';
import '../game/game_controller.dart';
import '../game/game_screen.dart';
import 'adventure_providers.dart';

/// The level list (§6.3, mockup 05): emerald = beaten, indigo = the action
/// forward, locked = calm gray. Beaten levels stay tappable — emerald play =
/// beat your own best; indigo play = the next step.
class AdventureScreen extends ConsumerWidget {
  const AdventureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final levels = ref.watch(adventureProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.modeStory)),
      body: levels.when(
        loading: () => const SizedBox.shrink(),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          final done = list.where((x) => x.state == LevelState.beaten).length;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l.progressOf(done, list.length),
                          textAlign: TextAlign.end,
                          style: TextStyle(
                              fontSize: 12, color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: done / list.length,
                            minHeight: 8,
                            backgroundColor: scheme.outlineVariant,
                            color: scheme.tertiary, // emerald = achieved
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: list.length,
                      separatorBuilder: (_, i) => const SizedBox(height: 10),
                      itemBuilder: (context, i) =>
                          _LevelRow(info: list[i]),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LevelRow extends ConsumerWidget {
  final LevelInfo info;
  const _LevelRow({required this.info});

  Future<void> _play(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(gameControllerProvider.notifier);
    final slot = adventureSlot(info.level);
    final nav = Navigator.of(context);
    final resumed = await controller.resumeSaved(slot: slot);
    if (!resumed) {
      controller.start(adventureConfig(info.level), slot: slot);
    }
    nav.push(MaterialPageRoute(builder: (_) => const GameScreen()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final beaten = info.state == LevelState.beaten;
    final locked = info.state == LevelState.locked;
    final current = info.state == LevelState.current;

    return Opacity(
      opacity: locked ? .55 : 1,
      child: Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: locked ? null : () => _play(context, ref),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: scheme.outlineVariant),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: beaten
                        ? scheme.tertiaryContainer
                        : current
                            ? scheme.secondary // indigo = the action forward
                            : scheme.outlineVariant.withValues(alpha: .5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: beaten
                      ? Icon(Icons.check, color: scheme.tertiary, size: 26)
                      : locked
                          ? Icon(Icons.lock_outline,
                              color: scheme.outline, size: 22)
                          : Text(
                              '${info.level}',
                              style: TextStyle(
                                color: scheme.onSecondary,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.levelN(info.level),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: locked ? scheme.onSurfaceVariant : null,
                        ),
                      ),
                      if (!locked)
                        Text(
                          '${l.target} ${info.target} · P75 ${kAdventureP75[info.level - 1]} · ${l.actionAdd} ${info.adds} · ${l.actionHint} ${info.hints}'
                          '${info.hasSavedRun ? ' · …' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (info.best != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      l.bestScore(info.best!),
                      style: TextStyle(
                        color: scheme.tertiary, // emerald = achieved
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                if (!locked)
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        // emerald play = replay a beaten level; indigo = next
                        backgroundColor:
                            beaten ? scheme.tertiary : scheme.secondary,
                        foregroundColor: beaten
                            ? scheme.onTertiary
                            : scheme.onSecondary,
                      ),
                      onPressed: () => _play(context, ref),
                      child: Text(l.play),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
