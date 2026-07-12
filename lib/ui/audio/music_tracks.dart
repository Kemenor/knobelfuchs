/// The background-music pool (§10.1) — Kevin MacLeod / incompetech.com,
/// CC BY 4.0, credited in the About screen.
///
/// Own file so both the audio service and the settings (jukebox picker)
/// can import it without a cycle. **Order matters:** adventure levels map
/// to tracks by index, so the original three stay first — appending is
/// safe, reordering changes which level plays what.
library;

class MusicTrack {
  /// AssetSource path (relative to `assets/`).
  final String asset;

  /// The composition's proper name — shown as-is, never localized.
  final String title;

  const MusicTrack(this.asset, this.title);
}

const List<MusicTrack> kMusicTracks = [
  MusicTrack('music/wholesome.mp3', 'Wholesome'),
  MusicTrack('music/deliberate-thought.mp3', 'Deliberate Thought'),
  MusicTrack('music/porch-swing-days.mp3', 'Porch Swing Days'),
  MusicTrack('music/carefree.mp3', 'Carefree'),
  MusicTrack('music/bossa-antigua.mp3', 'Bossa Antigua'),
  MusicTrack('music/george-street-shuffle.mp3', 'George Street Shuffle'),
  MusicTrack('music/wallpaper.mp3', 'Wallpaper'),
  MusicTrack('music/airport-lounge.mp3', 'Airport Lounge'),
  MusicTrack('music/fretless.mp3', 'Fretless'),
  MusicTrack('music/daily-beetle.mp3', 'Daily Beetle'),
  MusicTrack('music/life-of-riley.mp3', 'Life of Riley'),
  MusicTrack('music/bass-walker.mp3', 'Bass Walker'),
];
