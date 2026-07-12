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
    test('defaults to auto', () async {
      final c = await containerWith({});
      expect(c.read(settingsProvider).musicTrack, isNull);
    });

    test('a pinned track is stored and read back', () async {
      final c = await containerWith({});
      final pin = kMusicTracks[3].asset;
      c.read(settingsProvider.notifier).setMusicTrack(pin);
      expect(c.read(settingsProvider).musicTrack, pin);

      // Fresh container over the same prefs = app restart.
      final c2 = await containerWith({'music_track': pin});
      expect(c2.read(settingsProvider).musicTrack, pin);
    });

    test('unpinning removes the stored key', () async {
      final c = await containerWith({'music_track': kMusicTracks[0].asset});
      c.read(settingsProvider.notifier).setMusicTrack(null);
      expect(c.read(settingsProvider).musicTrack, isNull);
    });

    test('a pinned track that left the pool falls back to auto', () async {
      final c = await containerWith({'music_track': 'music/removed.mp3'});
      expect(c.read(settingsProvider).musicTrack, isNull);
    });
  });
}
