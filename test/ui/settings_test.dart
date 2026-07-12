import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knobelfuchs/ui/audio/music_tracks.dart';
import 'package:knobelfuchs/ui/settings/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> containerWith(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    final p = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPrefsProvider.overrideWithValue(p)],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('jukebox (§10.1)', () {
    test('every track starts enabled', () async {
      final c = await containerWith({});
      expect(c.read(settingsProvider).disabledTracks, isEmpty);
    });

    test('switched-off tracks are stored and read back', () async {
      final c = await containerWith({});
      final n = c.read(settingsProvider.notifier);
      n.setTrackEnabled(kMusicTracks[1].asset, false);
      n.setTrackEnabled(kMusicTracks[4].asset, false);
      expect(c.read(settingsProvider).disabledTracks,
          {kMusicTracks[1].asset, kMusicTracks[4].asset});

      // Fresh container over the same stored list = app restart.
      final c2 = await containerWith({
        'music_off': [kMusicTracks[1].asset, kMusicTracks[4].asset],
      });
      expect(c2.read(settingsProvider).disabledTracks,
          {kMusicTracks[1].asset, kMusicTracks[4].asset});
    });

    test('switching a track back on removes it from the set', () async {
      final c = await containerWith({
        'music_off': [kMusicTracks[0].asset],
      });
      c.read(settingsProvider.notifier)
          .setTrackEnabled(kMusicTracks[0].asset, true);
      expect(c.read(settingsProvider).disabledTracks, isEmpty);
    });

    test('a disliked track that left the pool is forgotten', () async {
      final c = await containerWith({
        'music_off': ['music/removed.mp3', kMusicTracks[2].asset],
      });
      expect(c.read(settingsProvider).disabledTracks,
          {kMusicTracks[2].asset});
    });
  });
}
