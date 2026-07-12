import 'package:audioplayers/audioplayers.dart';
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

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService(ref);
  ref.onDispose(service.dispose);
  return service;
});

class AudioService {
  final Ref ref;
  final List<AudioPlayer> _fxPool = [];
  int _fxIndex = 0;
  AudioPlayer? _music;

  AudioService(this.ref) {
    for (var i = 0; i < 4; i++) {
      _fxPool.add(AudioPlayer()..setPlayerMode(PlayerMode.lowLatency));
    }
    // Live music volume: follow the settings slider.
    ref.listen<Settings>(settingsProvider, (prev, next) {
      final music = _music;
      if (music == null) return;
      music.setVolume(next.musicVolume);
      if (prev?.musicOn == true && !next.musicOn) music.pause();
      if (prev?.musicOn == false && next.musicOn) music.resume();
    });
  }

  void play(SoundEvent event) {
    final settings = ref.read(settingsProvider);
    if (settings.effectsVolume <= 0) return;
    final player = _fxPool[_fxIndex];
    _fxIndex = (_fxIndex + 1) % _fxPool.length;
    player.play(AssetSource(_soundFiles[event]!),
        volume: settings.effectsVolume);
  }

  /// Adventure: fixed track per level; Free Form & Daily: the pool rotates
  /// deterministically by seed (§10.1). Music only during a foregrounded game.
  Future<void> startMusicFor({required String slot, required String seed}) async {
    final settings = ref.read(settingsProvider);
    final track = _trackFor(slot, seed);
    final music = _music ??= AudioPlayer()..setReleaseMode(ReleaseMode.loop);
    await music.stop();
    if (!settings.musicOn) return;
    await music.play(AssetSource(track), volume: settings.musicVolume);
  }

  String _trackFor(String slot, String seed) {
    if (slot.startsWith('level:')) {
      final level = int.tryParse(slot.substring('level:'.length)) ?? 1;
      return _musicTracks[(level - 1) % _musicTracks.length];
    }
    return _musicTracks[seedHash(seed).abs() % _musicTracks.length];
  }

  Future<void> stopMusic() async => _music?.stop();
  Future<void> pauseMusic() async => _music?.pause();

  Future<void> resumeMusic() async {
    if (ref.read(settingsProvider).musicOn) await _music?.resume();
  }

  void dispose() {
    for (final p in _fxPool) {
      p.dispose();
    }
    _music?.dispose();
  }
}
