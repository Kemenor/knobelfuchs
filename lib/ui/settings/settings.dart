import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fuchsbau/fuchsbau.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/game.dart' show ScoringVariant;

/// Motion levels (concept §10.2). `null` in [Settings.motion] = follow the
/// OS reduce-motion preference.
enum MotionMode { full, reduced, off }

class Settings {
  final double effectsVolume; // 0..1, default 80 %
  final bool musicOn; // default on (grilling Q13)
  final double musicVolume; // 0..1, default 45 %
  final MotionMode? motion; // null = follow OS
  final ThemeMode themeMode;
  final FuchsbauFont font;
  final String? localeOverride; // 'de' | 'fr' | 'it' | 'en' | null = system
  final bool anleitungSeen; // first-launch offer (§11)

  /// Playtest switch (2026-07-12): applies to newly started games.
  final ScoringVariant scoring;

  const Settings({
    this.effectsVolume = .8,
    this.musicOn = true,
    this.musicVolume = .45,
    this.motion,
    this.themeMode = ThemeMode.system,
    this.font = FuchsbauFont.figtree,
    this.localeOverride,
    this.anleitungSeen = false,
    this.scoring = ScoringVariant.classic,
  });

  Settings copyWith({
    double? effectsVolume,
    bool? musicOn,
    double? musicVolume,
    MotionMode? Function()? motion,
    ThemeMode? themeMode,
    FuchsbauFont? font,
    String? Function()? localeOverride,
    bool? anleitungSeen,
    ScoringVariant? scoring,
  }) =>
      Settings(
        effectsVolume: effectsVolume ?? this.effectsVolume,
        musicOn: musicOn ?? this.musicOn,
        musicVolume: musicVolume ?? this.musicVolume,
        motion: motion != null ? motion() : this.motion,
        themeMode: themeMode ?? this.themeMode,
        font: font ?? this.font,
        localeOverride:
            localeOverride != null ? localeOverride() : this.localeOverride,
        anleitungSeen: anleitungSeen ?? this.anleitungSeen,
        scoring: scoring ?? this.scoring,
      );

  /// Resolve the effective motion mode against the OS preference.
  MotionMode effectiveMotion(BuildContext context) =>
      motion ??
      (MediaQuery.of(context).disableAnimations
          ? MotionMode.reduced
          : MotionMode.full);
}

/// Overridden in main() with the loaded instance (and in tests).
final sharedPrefsProvider = Provider<SharedPreferences>(
    (ref) => throw UnimplementedError('override in main()'));

final settingsProvider =
    NotifierProvider<SettingsNotifier, Settings>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<Settings> {
  SharedPreferences get _prefs => ref.read(sharedPrefsProvider);

  @override
  Settings build() {
    final p = _prefs;
    MotionMode? motion;
    final m = p.getString('motion');
    if (m != null) {
      motion = MotionMode.values.asNameMap()[m];
    }
    return Settings(
      effectsVolume: p.getDouble('fx_vol') ?? .8,
      musicOn: p.getBool('music_on') ?? true,
      musicVolume: p.getDouble('music_vol') ?? .45,
      motion: motion,
      themeMode:
          ThemeMode.values.asNameMap()[p.getString('theme') ?? ''] ??
              ThemeMode.system,
      font: FuchsbauFont.values.asNameMap()[p.getString('font') ?? ''] ??
          FuchsbauFont.figtree,
      localeOverride: p.getString('locale'),
      anleitungSeen: p.getBool('anleitung_seen') ?? false,
      scoring:
          ScoringVariant.values.asNameMap()[p.getString('scoring') ?? ''] ??
              ScoringVariant.classic,
    );
  }

  void setScoring(ScoringVariant v) {
    state = state.copyWith(scoring: v);
    _prefs.setString('scoring', v.name);
  }

  void setEffectsVolume(double v) {
    state = state.copyWith(effectsVolume: v);
    _prefs.setDouble('fx_vol', v);
  }

  void setMusicOn(bool v) {
    state = state.copyWith(musicOn: v);
    _prefs.setBool('music_on', v);
  }

  void setMusicVolume(double v) {
    state = state.copyWith(musicVolume: v);
    _prefs.setDouble('music_vol', v);
  }

  void setMotion(MotionMode? v) {
    state = state.copyWith(motion: () => v);
    if (v == null) {
      _prefs.remove('motion');
    } else {
      _prefs.setString('motion', v.name);
    }
  }

  void setThemeMode(ThemeMode v) {
    state = state.copyWith(themeMode: v);
    _prefs.setString('theme', v.name);
  }

  void setFont(FuchsbauFont v) {
    state = state.copyWith(font: v);
    _prefs.setString('font', v.name);
  }

  void setLocaleOverride(String? code) {
    state = state.copyWith(localeOverride: () => code);
    if (code == null) {
      _prefs.remove('locale');
    } else {
      _prefs.setString('locale', code);
    }
  }

  void markAnleitungSeen() {
    state = state.copyWith(anleitungSeen: true);
    _prefs.setBool('anleitung_seen', true);
  }
}
