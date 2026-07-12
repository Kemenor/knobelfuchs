import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/seed.dart';
import '../settings/settings.dart';

/// Concept §10: every sound answers the player's action, never lures.
/// The file mapping is the frozen family canon (2026-07).
enum SoundEvent {
  select,
  match,
  rowCleared,
  addRows,
  hint,
  unavailable,
  boardCleared,
  levelUnlocked,
}

const Map<SoundEvent, String> _soundFiles = {
  SoundEvent.select: 'sounds/select_002.ogg',
  SoundEvent.match: 'sounds/confirmation_001.ogg',
  SoundEvent.rowCleared: 'sounds/glass_002.ogg',
  SoundEvent.addRows: 'sounds/scroll_002.ogg',
  SoundEvent.hint: 'sounds/question_001.ogg',
  SoundEvent.unavailable: 'sounds/minimize_001.ogg',
  SoundEvent.boardCleared: 'sounds/jingles_PIZZI10.ogg',
  SoundEvent.levelUnlocked: 'sounds/jingles_PIZZI01.ogg',
};

/// Background music pool (§10.1) — Kevin MacLeod, CC BY 4.0.
const List<String> _musicTracks = [
  'music/wholesome.mp3',
  'music/deliberate-thought.mp3',
  'music/porch-swing-days.mp3',
];

/// Neither track ever fights the other (or other apps) for audio focus —
/// that was the bug where a match SFX silenced the music.
final AudioContext _mixContext = AudioContext(
  android: const AudioContextAndroid(
    isSpeakerphoneOn: false,
    stayAwake: false,
    contentType: AndroidContentType.music,
    usageType: AndroidUsageType.game,
    audioFocus: AndroidAudioFocus.none,
  ),
  iOS: AudioContextIOS(
    category: AVAudioSessionCategory.ambient, // respects the silent switch
    options: const {AVAudioSessionOptions.mixWithOthers},
  ),
);

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService(ref);
  ref.onDispose(service.dispose);
  return service;
});

enum _MusicContext { none, menu, game }

/// Two tracks (tablet feedback, 2026-07-12):
/// - **Animation track**: one player; a new sound always ends the previous.
/// - **Background track**: menu plays from the jukebox (random pool pick),
///   a game start picks its own track (fixed per level, seed-rotated
///   otherwise). Backgrounding the app always *stops* music.
class AudioService with WidgetsBindingObserver {
  final Ref ref;
  final AudioPlayer _fx = AudioPlayer();
  final AudioPlayer _music = AudioPlayer();
  _MusicContext _context = _MusicContext.none;
  String? _track;

  AudioService(this.ref) {
    _fx.setPlayerMode(PlayerMode.lowLatency);
    _fx.setAudioContext(_mixContext);
    _music.setReleaseMode(ReleaseMode.loop);
    _music.setAudioContext(_mixContext);
    WidgetsBinding.instance.addObserver(this);

    ref.listen<Settings>(settingsProvider, (prev, next) {
      _music.setVolume(next.musicVolume);
      if (prev?.musicOn == true && !next.musicOn) _music.stop();
      if (prev?.musicOn == false && next.musicOn) _restart();
    });
  }

  /// Animation track: end the previous sound, start the new one.
  Future<void> play(SoundEvent event) async {
    final settings = ref.read(settingsProvider);
    if (settings.effectsVolume <= 0) return;
    await _fx.stop();
    await _fx.play(AssetSource(_soundFiles[event]!),
        volume: settings.effectsVolume);
  }

  /// Menu = the jukebox: a random pool track, kept while browsing menus.
  Future<void> playMenuMusic() async {
    if (_context == _MusicContext.menu) return;
    _context = _MusicContext.menu;
    _track = _musicTracks[Random().nextInt(_musicTracks.length)];
    await _restart();
  }

  /// A game picks its own track: fixed per adventure level, seed-rotated
  /// for free/daily (§10.1).
  Future<void> playGameMusic({required String slot, required String seed}) async {
    _context = _MusicContext.game;
    _track = _trackFor(slot, seed);
    await _restart();
  }

  String _trackFor(String slot, String seed) {
    if (slot.startsWith('level:')) {
      final level = int.tryParse(slot.substring('level:'.length)) ?? 1;
      return _musicTracks[(level - 1) % _musicTracks.length];
    }
    return _musicTracks[seedHash(seed).abs() % _musicTracks.length];
  }

  Future<void> _restart() async {
    await _music.stop();
    final settings = ref.read(settingsProvider);
    final track = _track;
    if (!settings.musicOn || track == null || _context == _MusicContext.none) {
      return;
    }
    await _music.play(AssetSource(track), volume: settings.musicVolume);
  }

  Future<void> stopMusic() async {
    _context = _MusicContext.none;
    _track = null;
    await _music.stop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Backgrounding always stops music — never a sound from a closed den.
    // (`inactive` is ignored: dialogs and the shade shouldn't kill the track.)
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _music.stop();
    } else if (state == AppLifecycleState.resumed) {
      _restart();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fx.dispose();
    _music.dispose();
  }
}
