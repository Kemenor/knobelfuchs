import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fuchsbau/fuchsbau.dart';

import '../../l10n/app_localizations.dart';
import '../audio/music_tracks.dart';
import 'settings.dart';

const String kAppVersion = '0.1';

/// Deliberately short (§10.3): volumes, music, motion, appearance, font,
/// language, about. No account, no premium, no notifications — none exist.
/// Built from the shared fuchsbau settings anatomy so it reads identically
/// to checkfuchs/knabberfuchs.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            // Explicit padding disables the automatic safe-area inset — add
            // the system nav bar back ourselves.
            padding: EdgeInsets.only(
                bottom: 32 + MediaQuery.viewPaddingOf(context).bottom),
            children: [
              FuchsbauSectionHeader(l.sectionSound),
              FuchsbauSettingsCard(children: [
                _SliderRow(
                  icon: Icons.volume_up_outlined,
                  label: l.effectsLabel,
                  sub: l.effectsSub,
                  value: s.effectsVolume,
                  onChanged: n.setEffectsVolume,
                ),
                SwitchListTile(
                  contentPadding: fuchsbauCardRowPadding,
                  secondary: const Icon(Icons.music_note_outlined),
                  title: Text(l.musicLabel),
                  value: s.musicOn,
                  onChanged: n.setMusicOn,
                ),
                if (s.musicOn) ...[
                  _SliderRow(
                    icon: Icons.graphic_eq,
                    label: l.musicVolumeLabel,
                    value: s.musicVolume,
                    onChanged: n.setMusicVolume,
                  ),
                  // The jukebox (§10.1): pin one track everywhere, or let
                  // the game keep choosing per level/board.
                  FuchsbauChoicePicker<String?>(
                    icon: Icons.queue_music_outlined,
                    title: l.jukeboxLabel,
                    value: s.musicTrack,
                    options: {
                      null: l.jukeboxAuto,
                      for (final t in kMusicTracks) t.asset: t.title,
                    },
                    onChanged: n.setMusicTrack,
                  ),
                ],
              ]),
              FuchsbauSectionHeader(l.sectionAppearance),
              FuchsbauSettingsCard(children: [
                FuchsbauChoicePicker<MotionMode?>(
                  icon: Icons.animation,
                  title: l.motionLabel,
                  value: s.motion,
                  options: {
                    null: l.motionAuto,
                    MotionMode.full: l.motionFull,
                    MotionMode.reduced: l.motionReduced,
                    MotionMode.off: l.motionOff,
                  },
                  onChanged: n.setMotion,
                  footnote: l.motionSub,
                ),
                FuchsbauChoicePicker<ThemeMode>(
                  icon: Icons.brightness_6_outlined,
                  title: l.themeLabel,
                  value: s.themeMode,
                  options: {
                    ThemeMode.system: l.themeSystem,
                    ThemeMode.light: l.themeLight,
                    ThemeMode.dark: l.themeDark,
                  },
                  onChanged: n.setThemeMode,
                ),
                FuchsbauChoicePicker<FuchsbauFont>(
                  icon: Icons.text_fields,
                  title: l.fontLabel,
                  value: s.font,
                  options: {
                    for (final font in FuchsbauFont.values) font: font.label,
                  },
                  onChanged: n.setFont,
                  footnote: l.textSizeNote,
                ),
              ]),
              FuchsbauSectionHeader(l.sectionLanguage),
              FuchsbauSettingsCard(children: [
                FuchsbauChoicePicker<String?>(
                  icon: Icons.language,
                  title: l.sectionLanguage,
                  value: s.localeOverride,
                  options: {
                    null: l.langSystem,
                    'de': 'Deutsch',
                    'fr': 'Français',
                    'it': 'Italiano',
                    'en': 'English',
                  },
                  onChanged: n.setLocaleOverride,
                ),
              ]),
              FuchsbauSectionHeader(l.sectionAbout),
              FuchsbauSettingsCard(children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l.aboutText(kAppVersion),
                    style: TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: scheme.onSurfaceVariant),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sub;
  final double value;
  final ValueChanged<double> onChanged;
  const _SliderRow({
    required this.icon,
    required this.label,
    this.sub,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: fuchsbauCardRowPadding,
      leading: Icon(icon),
      title: Text(label),
      subtitle: sub != null ? Text(sub!) : null,
      trailing: SizedBox(
        width: 220,
        child: Row(
          children: [
            Expanded(
              child: Slider(
                value: value,
                onChanged: onChanged,
              ),
            ),
            SizedBox(
              width: 44,
              child: Text(
                '${(value * 100).round()} %',
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
