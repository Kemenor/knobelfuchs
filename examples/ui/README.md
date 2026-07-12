# Knobelfuchs — UI mockups (visual canon)

Static HTML mockups, one file per screen, each with a **light/dark toggle**. Until the
Flutter widgets exist, these are the visual canon (family convention, see checkfuchs).

**The UI copy is German** — the primary playtester (the maker's mother, on a Xiaomi
Pad 5) reviews these directly. Final app is l10n'd en/de/fr/it as always.

| File | Screen |
|---|---|
| `01-home.html` | Home / mode select — the three modes wear the three triad colours |
| `02-spielbrett.html` | Game board, portrait — selection (indigo), hint (amber), cleared ghosts, action bar with budgets |
| `03-spielbrett-quer.html` | Game board, landscape — board left, thumb rail right (Daily mode chrome) |
| `04-parameter-und-ende.html` | Free-Form parameter sheet + run-end screen with QR challenge |
| `05-abenteuer.html` | Story mode ("Abenteuer") level list — sequential unlock, no timers |
| `06-tages-knobel.html` | Daily Knobel calendar = date picker — past days playable/resumable per date, future locked by device date |
| `07-klang.html` | Sound & motion audition board — every game event plays its animation + sound candidates (A/B) |

`sounds/` holds the sound candidates: Kenney.nl "Interface Sounds" + "Music Jingles",
**CC0 / public domain** (no attribution required; credited anyway).

Terminology in the mockups (l10n keys later): *Nachlegen* = add rows · *Tipp* = hint ·
*Startwert/Seed* = seed · *Punkteziel* = score to beat · *Tages-Knobel* = daily
challenge · *Abenteuer* = story mode.
