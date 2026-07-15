import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/adventure.dart';
import '../../l10n/app_localizations.dart';
import '../game/game_controller.dart';
import '../game/game_screen.dart';
import '../single_flight.dart';
import 'adventure_providers.dart';

/// The level list (§6.3, mockup 05): emerald = beaten, indigo = the action
/// forward, locked = calm gray. Beaten levels stay tappable — emerald play =
/// beat your own best; indigo play = the next step.
class AdventureScreen extends ConsumerStatefulWidget {
  const AdventureScreen({super.key});

  @override
  ConsumerState<AdventureScreen> createState() => _AdventureScreenState();
}

class _AdventureScreenState extends ConsumerState<AdventureScreen> {
  // Screen-level, not per-row: a second ROW tapped during the first row's
  // replay await must be ignored too, side effects included — a post-push
  // route check would still let it swap the live run.
  final _flight = SingleFlight();

  Future<void> _play(LevelInfo info) => _flight.run(() async {
        final controller = ref.read(gameControllerProvider.notifier);
        final slot = adventureSlot(info.level);
        final nav = Navigator.of(context);
        final resumed = await controller.resumeSaved(slot: slot);
        if (!resumed) {
          controller.start(adventureConfig(info.level), slot: slot);
        }
        if (!mounted) return;
        await nav.push(MaterialPageRoute(builder: (_) => const GameScreen()));
      });

  @override
  Widget build(BuildContext context) {
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
                      // Explicit padding disables the automatic safe-area
                      // inset — add the system nav bar back ourselves.
                      padding: EdgeInsets.fromLTRB(20, 0, 20,
                          24 + MediaQuery.viewPaddingOf(context).bottom),
                      itemCount: list.length,
                      separatorBuilder: (_, i) => const SizedBox(height: 10),
                      itemBuilder: (context, i) =>
                          _LevelRow(info: list[i], onPlay: _play),
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
  final Future<void> Function(LevelInfo) onPlay;
  const _LevelRow({required this.info, required this.onPlay});

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
          onTap: locked ? null : () => onPlay(info),
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
                          // P75 is a playtest instrument for the pending
                          // bot-vs-P75 target verdict — debug builds only;
                          // testers see the canonical row (mockup 05).
                          '${l.target} ${info.target}'
                          '${kDebugMode ? ' · P75 ${kAdventureP75[info.level - 1]}' : ''}'
                          ' · ${l.actionAdd} ${info.adds} · ${l.actionHint} ${info.hints}'
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
                      onPressed: () => onPlay(info),
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
