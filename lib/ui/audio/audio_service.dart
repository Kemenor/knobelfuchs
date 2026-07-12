import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/seed.dart';
import '../settings/settings.dart';
import 'music_tracks.dart';

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


/// Neither track ever fights the other (or other apps) for audio focus —
/// that was the bug where a match SFX silenced the music. iOS `ambient`
/// mixes by default AND respects the silent switch; passing mixWithOthers
/// explicitly is rejected by audioplayers' validation (that assertion made
/// the whole service throw on construction and killed the hint button).
final AudioContext _mixContext = AudioContext(
  android: const AudioContextAndroid(
    isSpeakerphoneOn: false,
    stayAwake: false,
    contentType: AndroidContentType.music,
    usageType: AndroidUsageType.game,
    audioFocus: AndroidAudioFocus.none,
  ),
  iOS: AudioContextIOS(
    category: AVAudioSessionCategory.ambient,
    options: const {},
  ),
);

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService(ref);
  ref.onDispose(service.dispose);
  return service;
});

/// The asset of the track audibly playing right now, null when silent —
/// the jukebox marks it so a disliked track can be identified and
/// switched off (§10.1).
final nowPlayingProvider =
    NotifierProvider<NowPlayingNotifier, String?>(NowPlayingNotifier.new);

class NowPlayingNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? asset) => state = asset;
}

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
  // The current game's identity — kept so the track can be re-derived when
  // the jukebox pool changes mid-game.
  String? _slot, _seed;

  AudioService(this.ref) {
    // Sound is decoration: NOTHING here may ever throw into gameplay.
    _guard(() async {
      await _fx.setPlayerMode(PlayerMode.lowLatency);
      await _fx.setAudioContext(_mixContext);
      await _music.setReleaseMode(ReleaseMode.loop);
      await _music.setAudioContext(_mixContext);
    });
    WidgetsBinding.instance.addObserver(this);

    ref.listen<Settings>(settingsProvider, (prev, next) {
      _guard(() async {
        await _music.setVolume(next.musicVolume);
        if (prev?.musicOn == true && !next.musicOn) await _music.stop();
        if (prev?.musicOn == false && next.musicOn) await _restart();
        // Jukebox: if the playing track was switched off (or the pool was
        // empty and a track came back), re-pick. A pool change that leaves
        // the current track alone never interrupts it.
        if (prev != null &&
            !setEquals(prev.disabledTracks, next.disabledTracks) &&
            _context != _MusicContext.none &&
            (_track == null || !_pool.contains(_track))) {
          _track = _pick();
          await _restart();
        }
      });
    });
  }

  /// Audio failures are logged, never thrown — a broken speaker must not
  /// break the game (learned 2026-07-12: a throwing constructor killed the
  /// hint button).
  Future<void> _guard(Future<void> Function() body) async {
    try {
      await body();
    } catch (e) {
      debugPrint('AudioService: $e');
    }
  }

  /// Animation track: end the previous sound, start the new one.
  Future<void> play(SoundEvent event) => _guard(() async {
        final settings = ref.read(settingsProvider);
        if (settings.effectsVolume <= 0) return;
        await _fx.stop();
        await _fx.play(AssetSource(_soundFiles[event]!),
            volume: settings.effectsVolume);
      });

  /// The jukebox pool (§10.1): every track the player hasn't switched off,
  /// in canonical order. May be empty — then no music plays.
  List<String> get _pool {
    final off = ref.read(settingsProvider).disabledTracks;
    return [
      for (final t in kMusicTracks)
        if (!off.contains(t.asset)) t.asset,
    ];
  }

  /// Menu music never interrupts: whatever already plays (game handoff,
  /// settings preview) simply carries on — so the settings jukebox can
  /// still name the track that annoyed you in-game. Only silence gets a
  /// fresh random pool pick.
  Future<void> playMenuMusic() => _guard(() async {
        if (_context == _MusicContext.menu) return;
        final keep = _track != null && _pool.contains(_track);
        _context = _MusicContext.menu;
        _slot = null;
        _seed = null;
        if (keep) return; // already playing — leave it alone
        _track = _pick();
        await _restart();
      });

  /// Jukebox audition (§10.1): play [asset] right now as the menu track —
  /// even one that's switched off. Leaving settings keeps it playing.
  Future<void> playPreview(String asset) => _guard(() async {
        _context = _MusicContext.menu;
        _slot = null;
        _seed = null;
        _track = asset;
        await _restart();
      });

  /// A game picks its own track: fixed per adventure level, seed-rotated
  /// for free/daily (§10.1) — always within the jukebox pool.
  Future<void> playGameMusic({required String slot, required String seed}) =>
      _guard(() async {
        _context = _MusicContext.game;
        _slot = slot;
        _seed = seed;
        _track = _pick();
        await _restart();
      });

  String? _pick() {
    final pool = _pool;
    if (pool.isEmpty) return null;
    switch (_context) {
      case _MusicContext.menu:
        return pool[Random().nextInt(pool.length)];
      case _MusicContext.game:
        final slot = _slot, seed = _seed;
        if (slot != null && slot.startsWith('level:')) {
          final level = int.tryParse(slot.substring('level:'.length)) ?? 1;
          return pool[(level - 1) % pool.length];
        }
        return pool[seedHash(seed ?? '').abs() % pool.length];
      case _MusicContext.none:
        return null;
    }
  }

  Future<void> _restart() async {
    await _music.stop();
    final settings = ref.read(settingsProvider);
    final track = _track;
    if (!settings.musicOn || track == null || _context == _MusicContext.none) {
      ref.read(nowPlayingProvider.notifier).set(null);
      return;
    }
    await _music.play(AssetSource(track), volume: settings.musicVolume);
    ref.read(nowPlayingProvider.notifier).set(track);
  }

  Future<void> stopMusic() => _guard(() async {
        _context = _MusicContext.none;
        _track = null;
        _slot = null;
        _seed = null;
        await _music.stop();
        ref.read(nowPlayingProvider.notifier).set(null);
      });

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Backgrounding always stops music — never a sound from a closed den.
    // (`inactive` is ignored: dialogs and the shade shouldn't kill the track.)
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _guard(() async {
        await _music.stop();
        ref.read(nowPlayingProvider.notifier).set(null);
      });
    } else if (state == AppLifecycleState.resumed) {
      _guard(_restart);
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fx.dispose();
    _music.dispose();
  }
}
