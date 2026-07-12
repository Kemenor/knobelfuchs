import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fuchsbau/fuchsbau.dart';

import '../../l10n/app_localizations.dart';
import 'settings.dart';

const String kAppVersion = '0.1';

/// Deliberately short (§10.3): volumes, music, motion, appearance, font,
/// language, about. No account, no premium, no notifications — none exist.
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
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              _SectionHeader(l.sectionSound),
              _Card(children: [
                _SliderRow(
                  icon: Icons.volume_up_outlined,
                  label: l.effectsLabel,
                  sub: l.effectsSub,
                  value: s.effectsVolume,
                  onChanged: n.setEffectsVolume,
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.music_note_outlined),
                  title: Text(l.musicLabel),
                  value: s.musicOn,
                  onChanged: n.setMusicOn,
                ),
                if (s.musicOn)
                  _SliderRow(
                    icon: Icons.graphic_eq,
                    label: l.musicVolumeLabel,
                    value: s.musicVolume,
                    onChanged: n.setMusicVolume,
                  ),
                ListTile(
                  leading: const Icon(Icons.queue_music_outlined),
                  title: Text(
                    l.jukeboxLater,
                    style: TextStyle(
                        fontSize: 13, color: scheme.onSurfaceVariant),
                  ),
                  dense: true,
                ),
              ]),
              _SectionHeader(l.motionLabel),
              _Card(children: [
                _ChipsRow<MotionMode?>(
                  icon: Icons.animation,
                  label: l.motionLabel,
                  sub: l.motionSub,
                  value: s.motion,
                  options: [
                    (null, l.motionAuto),
                    (MotionMode.full, l.motionFull),
                    (MotionMode.reduced, l.motionReduced),
                    (MotionMode.off, l.motionOff),
                  ],
                  onChanged: n.setMotion,
                ),
              ]),
              _SectionHeader(l.sectionAppearance),
              _Card(children: [
                _ChipsRow<ThemeMode>(
                  icon: Icons.brightness_6_outlined,
                  label: l.themeLabel,
                  value: s.themeMode,
                  options: [
                    (ThemeMode.system, l.themeSystem),
                    (ThemeMode.light, l.themeLight),
                    (ThemeMode.dark, l.themeDark),
                  ],
                  onChanged: n.setThemeMode,
                ),
                RadioGroup<FuchsbauFont>(
                  groupValue: s.font,
                  onChanged: (v) => n.setFont(v!),
                  child: Column(children: [
                    for (final font in FuchsbauFont.values)
                      RadioListTile<FuchsbauFont>(
                        value: font,
                        title: Text(font.label,
                            style: TextStyle(fontFamily: font.family)),
                        secondary: Text('1 2 3 … 9',
                            style: TextStyle(
                                fontFamily: font.family,
                                color: scheme.onSurfaceVariant)),
                      ),
                  ]),
                ),
                ListTile(
                  leading: const Icon(Icons.format_size),
                  title: Text(
                    l.textSizeNote,
                    style: TextStyle(
                        fontSize: 13, color: scheme.onSurfaceVariant),
                  ),
                  dense: true,
                ),
              ]),
              _SectionHeader(l.sectionLanguage),
              _Card(children: [
                _ChipsRow<String?>(
                  icon: Icons.language,
                  label: l.sectionLanguage,
                  value: s.localeOverride,
                  options: [
                    (null, l.langSystem),
                    ('de', 'Deutsch'),
                    ('fr', 'Français'),
                    ('it', 'Italiano'),
                    ('en', 'English'),
                  ],
                  onChanged: n.setLocaleOverride,
                ),
              ]),
              _SectionHeader(l.sectionAbout),
              _Card(children: [
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

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: .8,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
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
                activeColor: scheme.secondary,
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

class _ChipsRow<T> extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sub;
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;
  const _ChipsRow({
    required this.icon,
    required this.label,
    this.sub,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (sub != null)
                    Text(sub!,
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (v, text) in options)
                ChoiceChip(
                  label: Text(text),
                  selected: v == value,
                  onSelected: (_) => onChanged(v),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
