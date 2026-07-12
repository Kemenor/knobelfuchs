# Knobelfuchs — UI mockups (visual canon)

Static HTML mockups, one file per screen, each with a **light/dark toggle**. Until the
Flutter widgets exist, these are the visual canon (family convention, see checkfuchs).

**The UI copy is German** — the primary playtester (the maker's mother, on a Xiaomi
Pad 5) reviews these directly. Final app is l10n'd en/de/fr/it as always.

| File | Screen |
|---|---|
| `01-home.html` | Home / mode select — the three modes wear the three triad colours |
| `02-spielbrett.html` | Game board, portrait — selection (indigo), hint (orange, persists), cleared ghosts, action bar with budgets |
| `03-spielbrett-quer.html` | Game board, landscape — board left, thumb rail right (Daily mode chrome) |
| `04-parameter-und-ende.html` | Free-Form parameter sheet + run-end screen with QR challenge |
| `05-abenteuer.html` | Story mode ("Abenteuer") level list — sequential unlock, no timers |
| `06-tages-knobel.html` | Daily Knobel calendar = date picker — past days playable/resumable per date, future locked by device date |
| `07-klang.html` | Sound & motion canon — every game event plays its animation + its **chosen** sound (frozen after the family audition, July 2026), plus the background-music pool |
| `08-einstellungen.html` | Settings — effect/music volumes, music toggle, motion Voll/Reduziert/Aus, appearance, font picker, language, About |

`sounds/` holds the **frozen** sound set (family audition, July 2026): Kenney.nl
"Interface Sounds" + "Music Jingles", **CC0 / public domain** (no attribution
required; credited anyway). Event → file mapping lives in `design-concept.md` §10.

`music/` holds background-music candidates by **Kevin MacLeod (incompetech.com), CC BY
4.0** — the mp3s are **gitignored**. Re-fetch into `music/` with the commands below.
The app copies in `assets/music/` are these files re-encoded to **128 kbps**
(`ffmpeg -i in.mp3 -vn -codec:a libmp3lame -b:a 128k out.mp3`) — background music
at 45 % volume doesn't need source bitrate, and it halves the bundle.

```powershell
$u = 'https://incompetech.com/music/royalty-free/mp3-royaltyfree'
Invoke-WebRequest "$u/Wholesome.mp3" -OutFile music/wholesome.mp3
Invoke-WebRequest "$u/Deliberate%20Thought.mp3" -OutFile music/deliberate-thought.mp3
Invoke-WebRequest "$u/Porch%20Swing%20Days%20-%20slower.mp3" -OutFile music/porch-swing-days.mp3
Invoke-WebRequest "$u/Carefree.mp3" -OutFile music/carefree.mp3
Invoke-WebRequest "$u/Bossa%20Antigua.mp3" -OutFile music/bossa-antigua.mp3
Invoke-WebRequest "$u/George%20Street%20Shuffle.mp3" -OutFile music/george-street-shuffle.mp3
Invoke-WebRequest "$u/Wallpaper.mp3" -OutFile music/wallpaper.mp3
Invoke-WebRequest "$u/Airport%20Lounge.mp3" -OutFile music/airport-lounge.mp3
Invoke-WebRequest "$u/Fretless.mp3" -OutFile music/fretless.mp3
Invoke-WebRequest "$u/Daily%20Beetle.mp3" -OutFile music/daily-beetle.mp3
Invoke-WebRequest "$u/Life%20of%20Riley.mp3" -OutFile music/life-of-riley.mp3
Invoke-WebRequest "$u/Bass%20Walker.mp3" -OutFile music/bass-walker.mp3
```

Terminology in the mockups (l10n keys later): *Nachlegen* = add rows · *Tipp* = hint ·
*Startwert/Seed* = seed · *Punkteziel* = score to beat · *Tages-Knobel* = daily
challenge · *Abenteuer* = story mode.
