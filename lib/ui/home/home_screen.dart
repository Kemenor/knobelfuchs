import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../freeform/new_game_sheet.dart';
import '../game/game_controller.dart';
import '../game/game_screen.dart';

/// Home (§12): each mode card does the most-wanted thing. The three modes
/// wear the three triad colours; the home screen *is* the palette.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final game = ref.watch(gameControllerProvider);
    final saved = ref.watch(savedFreeRunProvider).value;
    final resumeScore = game?.score ?? saved?.score;

    void comingSoon() {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(l.comingSoon),
          behavior: SnackBarBehavior.floating,
        ));
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Text('🦊', style: TextStyle(fontSize: 34)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.appTitle,
                                style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -.5)),
                            Text(l.tagline,
                                style: TextStyle(
                                    color: scheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: comingSoon,
                        icon: const Icon(Icons.help_outline),
                      ),
                      IconButton(
                        onPressed: comingSoon,
                        icon: const Icon(Icons.settings_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _ModeCard(
                    hue: scheme.primary, // orange
                    icon: Icons.edit_outlined,
                    title: l.modeFree,
                    subtitle: l.modeFreeDesc,
                    trailing: resumeScore != null
                        ? '${l.resume}\n$resumeScore ${l.score}'
                        : null,
                    onTap: () async {
                      final nav = Navigator.of(context);
                      if (game != null) {
                        nav.push(MaterialPageRoute(
                            builder: (_) => const GameScreen()));
                        return;
                      }
                      if (saved != null) {
                        // One tap back into the autosaved run (§12).
                        final ok = await ref
                            .read(gameControllerProvider.notifier)
                            .resumeSaved();
                        if (ok) {
                          nav.push(MaterialPageRoute(
                              builder: (_) => const GameScreen()));
                          return;
                        }
                      }
                      if (context.mounted) showNewGameSheet(context);
                    },
                  ),
                  const SizedBox(height: 14),
                  _ModeCard(
                    hue: scheme.secondary, // indigo
                    icon: Icons.calendar_today_outlined,
                    title: l.modeDaily,
                    subtitle: l.modeDailyDesc,
                    enabled: false,
                    onTap: comingSoon,
                  ),
                  const SizedBox(height: 14),
                  _ModeCard(
                    hue: scheme.tertiary, // emerald
                    icon: Icons.map_outlined,
                    title: l.modeStory,
                    subtitle: l.modeStoryDesc,
                    enabled: false,
                    onTap: comingSoon,
                  ),
                  const Spacer(),
                  Text(
                    l.footerOffline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: scheme.onSurfaceVariant, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final Color hue;
  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailing;
  final bool enabled;
  final VoidCallback onTap;

  const _ModeCard({
    required this.hue,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final content = Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: hue.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: hue, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                      color: scheme.onSurfaceVariant, fontSize: 13),
                ),
              ],
            ),
          ),
          if (trailing != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                trailing!,
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: hue,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          Icon(Icons.chevron_right, color: scheme.outline),
        ],
      ),
    );

    return Opacity(
      opacity: enabled ? 1 : .55,
      child: Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: scheme.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // The mode's accent stripe (mockup's left border).
                  Container(width: 6, color: hue),
                  Expanded(child: content),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
