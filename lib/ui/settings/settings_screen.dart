import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fuchsbau/fuchsbau.dart';

import '../../data/backup.dart';
import '../../l10n/app_localizations.dart';
import '../audio/audio_service.dart';
import '../audio/music_tracks.dart';
import 'backup_actions.dart';
import 'settings.dart';

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
                  // The jukebox (§10.1): switch single tracks off to shrink
                  // the rotation pool — the game still picks per level/board,
                  // just from the tracks you like. The play button auditions
                  // a track (it keeps playing as menu music), and the
                  // equalizer marks whichever track is on right now.
                  const _JukeboxTile(),
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
              // §9.1: local-first device moves — the player owns the file.
              FuchsbauSectionHeader(l.sectionBackup),
              FuchsbauSettingsCard(children: [
                ListTile(
                  contentPadding: fuchsbauCardRowPadding,
                  leading: const Icon(Icons.ios_share),
                  title: Text(l.exportTitle),
                  subtitle: Text(l.exportSub),
                  onTap: () => _export(context, ref, l),
                ),
                ListTile(
                  contentPadding: fuchsbauCardRowPadding,
                  leading: const Icon(Icons.file_open_outlined),
                  title: Text(l.importTitle),
                  subtitle: Text(l.importSub),
                  onTap: () => _import(context, ref, l),
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

Future<void> _export(
    BuildContext context, WidgetRef ref, AppLocalizations l) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final saved = await ref.read(backupActionsProvider).exportBackup();
    if (saved) {
      messenger.showSnackBar(SnackBar(content: Text(l.exportDone)));
    } // cancelled save dialog = no ceremony
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(l.backupFailed('$e'))));
  }
}

Future<void> _import(
    BuildContext context, WidgetRef ref, AppLocalizations l) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final contents = await ref.read(backupActionsProvider).pickBackup();
    if (contents == null) return; // picker cancelled — no ceremony
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.importConfirmTitle),
        content: Text(l.importConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.importReplace),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(backupActionsProvider).applyBackup(contents);
    messenger.showSnackBar(SnackBar(content: Text(l.importDone)));
  } on BackupException catch (e) {
    messenger.showSnackBar(SnackBar(
      content: Text(e.error == BackupError.tooNew
          ? l.importTooNew
          : l.importInvalid),
    ));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(l.backupFailed('$e'))));
  }
}

class _JukeboxTile extends ConsumerWidget {
  const _JukeboxTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    final playing = ref.watch(nowPlayingProvider);
    final playingTitle = [
      for (final t in kMusicTracks)
        if (t.asset == playing) t.title,
    ].firstOrNull;

    final count = l.jukeboxOnOf(
        kMusicTracks.length - s.disabledTracks.length, kMusicTracks.length);
    return ExpansionTile(
      leading: const Icon(Icons.queue_music_outlined),
      title: Text(l.jukeboxLabel),
      subtitle: Text(
          playingTitle == null ? count : '$count · ♪ $playingTitle'),
      children: [
        for (final t in kMusicTracks)
          SwitchListTile(
            secondary: t.asset == playing
                // Indigo = the active one; tapping restarts it, harmless.
                ? IconButton(
                    icon: Icon(Icons.graphic_eq, color: scheme.secondary),
                    onPressed: () =>
                        ref.read(audioServiceProvider).playPreview(t.asset),
                  )
                : IconButton(
                    icon: const Icon(Icons.play_arrow_rounded),
                    onPressed: () =>
                        ref.read(audioServiceProvider).playPreview(t.asset),
                  ),
            title: Text(t.title),
            value: !s.disabledTracks.contains(t.asset),
            onChanged: (v) => n.setTrackEnabled(t.asset, v),
          ),
      ],
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
