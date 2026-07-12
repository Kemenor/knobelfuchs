# Knobelfuchs — Game Design

The first fuchs **game**. A calm number-match puzzle (the classic pen-and-paper
"Zahlenknobeln" / *Take Ten* mechanic, known from Number Match / Number Clash /
Numberzilla) — built the fuchs way: **no ads, no paywalled assists, no dark patterns**.
Challenge comes from *player-chosen* limits and targets, never from a shop.

This doc owns the **what**: rules, modes, and semantics. [`PLAN.md`](./PLAN.md) owns the
**how**.

## 1. Why it exists

Watching a family member play an ad-riddled Number Match clone: the game itself is
lovely — gentle, absorbing, endlessly replayable. Everything around it is hostile
(interstitials, "watch ad for a hint", fake urgency). The mechanic is a decades-old
public-domain paper game; nobody owns it. So we build the respectful version, tuned for
the person it's for: **tablet-first** (Xiaomi Pad 5), big digits, honest challenge.

Hints and row-adds *are* limited here too — but as **game parameters the player set
themselves** (or a level defines), like the number of mines in Minesweeper. Running out
is part of the puzzle, never a checkout moment.

## 2. The board

- A grid of **9 columns**; rows grow downward as the game progresses.
- Each cell is either a **digit 1–9** or **cleared** (was matched away).
- The board reads like text: **row-major reading order**, left→right, top→bottom.

### 2.1 Seeds
Every game is generated from a **seed**, so the same seed always produces the
identical game on every device. This is the backbone of all three modes (§6) and of
challenge-sharing (§7).

- **Seeds are strings** — words welcome (`herbst-fuchs`), numbers are just strings
  too. Normalization makes dictated seeds robust: trim → Unicode **NFC** → lowercase →
  internal whitespace collapses to a single dash; letters/digits/dashes only, max
  **32 chars**. The app always displays (and QR-encodes) the normalized form.
- The engine hashes the normalized string with a **fixed FNV-1a** (hand-rolled — never
  the platform's `hashCode`, which isn't stable) into the PRNG's integer space.
- **Randomized seeds** are drawn as 6-digit strings ("738 291") — easy to read out
  loud at a family lunch.
- **Daily seeds** are internal — `yyyymmdd` in their own namespace (the mode is mixed
  into the hash), never typed, never colliding with player seeds.
- The current seed is visible on the game screen and the run-end screen, so any game
  can be shared after the fact.

### 2.2 Opening deal & fairness gate
The opening is **35 digits — 3 full rows + 8** (a named constant; width is always 9,
and the board has **no length cap** — an ∞-adds board may grow as long as its player
enjoys). 35 matches the reference game's opening (verified against Number Clash on
the family tablet, 2026-07-12, amending the grilling's provisional 27), and the
partial last row puts the reading-order wrap in play from the very first board.

Raw randomness can deal a dead opening (zero pairs). The **fairness gate** prevents
it: after generating, the engine counts available pairs; below **3**, it rerolls
deterministically. The PRNG state is **`hash(seed, attempt)`** — seed and attempt are
separate hash inputs, so a reroll can never collide with another seed's (or another
day's) board. The attempt counter is internal; players only ever see their seed.

**Balanced deal** (added 2026-07-12): the 2026-07-11 daily contained no 5s — and 5
only pairs with 5, so the board lost its hardest constraint and played far too easy.
Player, daily and QR boards therefore deal from a **bag** (every digit 1–9 at least
⌊35/9⌋ = 3 times, the 8 remaining slots PRNG-drawn, seeded-shuffled) instead of raw
uniform draws. **Adventure levels keep the raw uniform deal on purpose** — the skew
quirk is curation material for deliberately easy or strange levels. The variant
derives from the seed namespace (`level:` = uniform), so replay and QR need no extra
field.

## 3. The rules

### 3.1 Matching pair
Two cells form a valid pair when **both** hold:

1. **Values:** the digits are **equal** (7‑7) *or* **sum to 10** (3‑7, 1‑9, 5‑5 counts
   as both).
2. **Line of sight** — the cells can "see" each other along one of:
   - the same **row**, all cells between them cleared;
   - the same **column**, all cells between them cleared;
   - the same **diagonal** (either direction), all cells between them cleared;
   - **reading order**: consecutive in row-major order ignoring cleared cells — this is
     what lets a pair wrap from the end of one line to the start of a later one.

### 3.2 Match
Tap one cell (selects it, indigo highlight), tap a valid partner → both become
**cleared**. Tapping an invalid partner *moves the selection* there — never an error
sound, never a penalty. Tapping the selected cell deselects.

### 3.3 Row collapse
When every cell of a row is cleared, the row **disappears** and the board closes up.
A quiet moment of satisfaction — small animation, no fanfare screen.

### 3.4 Adding rows ("Nachlegen")
The **add button** appends *all surviving digits* in reading order to the end of the
board (the classic full-copy rule — the messier the board, the more material). Each
game has an **add budget** — default **5**, up to **limitless** where the mode allows
(§6). Adds are **never fairness-gated**: a copy that yields no new pair is the puzzle.
The remaining count sits on the button as neutral information; at 0 the button turns
**gray** (quietly unavailable, not alarmed — nothing red).

### 3.5 Hints
The **hint button** highlights **the first valid pair in reading order** (fox orange,
and it stays highlighted until both cells are tapped — impossible to miss;
*information, not command*). Deterministic-first matters: on a shared Daily board,
everyone's hint buys the same information — and it is exactly the baseline bot's move
(§4.1), so the assist system and the difficulty system are the same mathematics.

- Each game has a **hint budget** — default **5**, up to **limitless** where the mode
  allows. A hint is **consumed only when it reveals a new pair**; pressing hint while
  a highlight is still active re-pulses it for free.
- Highlight mechanics: hint and selection are **independent layers** — tapping works
  exactly as §3.2 regardless of orange. Each hinted cell releases *its own* orange
  when tapped; highlights are re-validated after every board change and drop silently
  if the pair stops being valid. Nothing ever blinks.
- Pressing hint when **no valid pair exists** shows the button gray and points at the
  add button instead — this **does not consume** a hint (telling you "nothing is
  there" is honesty, not help). There is **no passive** "pair exists" indicator —
  whether something is still there *is* the puzzle (revisit only on playtest
  evidence). At budget 0 the button turns gray.

### 3.6 Undo
Undo is a **true rewind**, one action per step, unlimited depth back to the opening:

- A step reverses a **match** (cells return, collapsed rows return) or an **add** (the
  copy vanishes **and the add budget is refunded** — un-mutating refunds).
- Score rewinds exactly with each step (the move log is replayed).
- **Hints live outside the move log** — never undone, never refunded; information
  can't be un-seen.
- **No redo.** Undoing and playing differently discards the old future.

### 3.7 End of a run
- **Board cleared** — the crowning finish (bonus, celebration). Final: "Nochmal",
  "Zum Menü".
- **Stuck** (no valid pair *and* add budget exhausted) — the engine **auto-detects**
  this and shows the run-end screen; hiding a dead end would just mean scanning a
  hopeless board. This is a natural end, *not a fail state*: no "GAME OVER", no red,
  the score simply stands. The screen offers a quiet **"Zurück aufs Brett"** — undo
  back in and try another line; a dead end means *this path* is exhausted, not you.
- **Results commit at every run-end**, best kept: Daily best per date, Adventure best
  per level (the target-beaten flag latches), Free Form last run + best-for-seed. End
  better after undoing back in and the better result simply stands.
- A game in progress is **autosaved** every move and waits indefinitely.

## 4. Scoring

Scores make seeds shareable ("beat 1 840 on this board") and give runs a shape. The
formula is **simple, transparent, and shown in-app** — no hidden multipliers:

**"Nur die Zahlen vom Anfangsbrett zählen — nachgelegte Zahlen sind Helfer, keine
Beute."** (originals-only, fixed 2026-07-12 after playtesting exposed that the
original formula rewarded add-spam: every add doubles the material, so volume points
swamp every fixed bonus and bot targets become trivially beatable.)

| Event | Points |
|---|---|
| Cell **from the opening board** cleared | **+10** — copies from Nachlegen score nothing (max 350) |
| Row cleared | **0** — the glass chime is the celebration; points would be farmable |
| Board fully cleared | **+250** |
| Each unused add | **+50** — **paid only on a cleared board**; **at most 4 adds are rewarded** (engine-enforced, family decision 2026-07-12) |

- **Fixed ceiling = 800 per board** — every score is comparable; targets are honest.
  With the default 5-add budget parity alone caps the bonus at 4×50 (clearing needs
  ≥1 add); the explicit cap extends the ceiling to Free-Form games with big budgets.
- **Hints never cost points.** Assist use is not punished — the budget is the only
  limit (information, never punishment).
- **Parity fact:** a 35-digit opening is odd and matches remove two, so **clearing
  is impossible without at least one Nachlegen** — the add button is load-bearing.
- Three alternative formulas (classic volume-scoring, adds-cost-points,
  adds-cheapen-pairs) remain implemented behind `ScoringVariant` for future
  playtests; the UI is fixed to originals-only.

### 4.1 Score to beat
A game can carry a **target score**. Beating it is the win condition in Daily and
Story modes and an optional spice in Free Form.

- **Daily & Adventure targets are computed, not designed:** the deterministic
  **baseline bot** (greedy: always the first valid pair in reading order, adds when
  stuck, **same add budget as the run**, no hints) plays the seed at generation time.
  **Target = bot score × factor, rounded to the nearest 10** — Daily: **0.9** (the bot
  is greedy; the game forgives a little suboptimal play), Adventure: **ramps 0.9 → 1.0**
  across the levels. Same seed ⇒ same target on every device — no server, no
  authoring burden.
- **Free Form targets are never computed** (with ∞ adds the bot wouldn't terminate):
  manual entry or QR-filled only, validated against the 800 ceiling — a target no
  board can pay is a typo, not a challenge.
- A player-facing difficulty setting (shifting the factor) is a **v2 candidate** —
  the machinery is one multiplier.

## 5. Accessibility — hard requirements

The primary player is an older adult on an 11″ tablet. Two items are **must-have**
(elevated above Fuchsbau's usual should-have):

1. **Font scaling.** Every UI text respects the OS text scale **up to 200 % without
   clipping or truncation**; board digits are sized by cell geometry (≈ 64–72 dp cells
   on the Pad 5) and are already huge. Layouts reflow, never ellipsize a number.
2. **Legible typefaces.** The Fuchsbau font picker (Figtree default · System ·
   **Atkinson Hyperlegible** · **OpenDyslexic**) applies to *everything, including the
   board digits*. Tabular figures throughout.

Plus the Fuchsbau baseline: touch targets ≥ 48 dp (board cells well above), full
contrast in both themes, tap-tap interaction only — no drag, no long-press, no gesture
anywhere in the game.

## 6. The three modes

One engine, three framings. Each mode owns one colour of the Fuchsbau triad:

| Mode | Colour | Seed | Adds | Hints | Target |
|---|---|---|---|---|---|
| **Free Form** | fox orange | player-set or randomized | **5** default → limitless | **5** default → limitless | optional |
| **Daily Knobel** | indigo | derived from the date | fixed (5) | fixed (5) | computed (§4.1), always on |
| **Story** | emerald | fixed per level | per level | per level | per level, always on |

### 6.1 Free Form
The everyday mode. **One saved run at a time** — the home card resumes it in a single
tap; starting a new game over a live run confirms calmly first ("das laufende Spiel
wird verworfen — 2 340 Punkte"). Multi-slot is deferred until someone asks. The
parameter sheet:

- **Seed** — empty = randomized (shown in-game so it can be shared); words or numbers
  (§2.1), enterable to replay or take on a challenge.
- **Adds** — stepper, 0 … 20, then ∞. Default 5.
- **Hints** — stepper, 0 … 20, then ∞. Default 5.
- **Score to beat** — optional number, default off (manual or QR-filled; never
  computed here).

Sensible defaults mean the sheet is one tap ("Los!") for players who don't care —
parameters are power, summoned not imposed.

### 6.2 Daily Knobel
One board per calendar day: **seed = the date** (local), so every player worldwide
knobles the *same* board — no server, no account, pure math. Adds and hints fixed at 5;
the target score is computed from the seed (§4.1). Result (score, beaten y/n) is stored
per date.

**Past days stay playable.** The mode opens on a **month-calendar date picker**: any
past day (or today) can be started, resumed, or replayed — a rainy Sunday can catch up
the whole week. Each date keeps its own autosaved run, so leaving Tuesday half-finished
to play Wednesday loses nothing. The archive begins at the **epoch, 2026‑07‑01** (a
named constant — the fox has posed one puzzle a day since it existed); the calendar's
back arrow grays out there. **Future dates are locked** (quiet gray lock, checked
against the device date) — the point of a daily is that everyone meets the same board
*on* the day; tomorrow simply isn't knowable yet.

Clock edges, decided: a run **belongs to the date it was started for** (starting July
12's board at 23:50 and finishing at 00:20 is a July‑12 result), and there is **zero
anti-cheat** — no server, no leaderboard, no prize; whoever sets their tablet a year
ahead to peek gets that joy for free. The future-lock is a design statement, not
security.

A missed day is simply an open slot, still waiting — **no streak guilt, no red, no
notification**. The daily waits; it never calls.

### 6.3 Story
A curated, numbered level collection (v1: ~20 levels). Each level = seed + add budget +
hint budget + target (bot × ramping factor, §4.1); **ending a run with score ≥ target
unlocks the next level** (the beaten flag latches — a later worse run never re-locks
anything). Difficulty climbs by tightening budgets (5/5 early → 2/1 late) with the
target factor ramping 0.9 → 1.0 — never by timers; the exact curve is curated during
playtesting. Progress is stored locally; **each level keeps its own saved run** —
replaying beaten level 5 never touches half-finished level 6. Replaying is always
allowed (best score kept).

## 7. Challenge sharing (QR)

Free Form settings encode into a QR code on the run-end screen — "beat me on this
board." Fully offline, peer-to-peer, no server; the QR *is* the challenge.

- **Payload:** a deep link, `knobelfuchs://c?v=1&s=<seed>&a=<adds>&h=<hints>&t=<target>`
  — the **`v` version field is mandatory from day one** (a v2 app reads old codes and
  politely declines future ones). The seed travels in normalized form (§2.1).
- **No names, no message field** — the target *is* the personal touch, and shareable
  artifacts carry no personal data.
- **Scanning pre-fills the parameter sheet — never auto-starts.** The sheet stays
  editable after scanning; the app doesn't police honor.
- The `knobelfuchs://` scheme is registered on **both Android and iOS** (intent-filter
  / `CFBundleURLTypes`), so system-camera scans work too; the in-app scanner
  (knabberfuchs precedent) is convenience. Https App/Universal Links under
  fuchsnest.ch — doubling as a "get the app" page — are a **v2 candidate**.

## 8. Stats — information, never punishment

**Record everything from day one, surface modestly.** Every run writes its full record
(mode, seed, config, score, target, pairs, rows, adds/hints used, duration,
timestamps) — the schema exists from the first release so no history is ever lost.

Surfaced in v1: the run-end screen (per-run), the Daily calendar (per-date results),
Adventure's best scores. **No lifetime-statistics page in v1** — the data waits; the
page is a v2 candidate shaped by what turns out to be interesting.

Never surfaced, by design: duration during play (no clock on the game screen), and
anything streak-like — the calendar shows what *was played*, never counts what
wasn't. No daily-login rewards, no notifications — **a game must never call you
back**; it waits.

## 9. Ergonomics (Pad 5 reference)

- **Big digits** — cells scale with the screen; on the Pad ≈ 64–72 dp, floor 48 dp.
- **Stillness rule:** the board is perfectly still until the player acts; animations
  are short (≤ 250 ms) responses to input, never ambient.
- Portrait and landscape both first-class (§ DESIGN_SYSTEM); phones supported by the
  same adaptive layout.

## 10. Sound & motion — reward the action, never bait the return

Good game feel is not a dark pattern. A found pair *should* feel satisfying — the line
we hold is **who initiates**: every sound and every animation is a *response to the
player's action*, never a lure. No sound ever calls into the room, nothing blinks on
its own, no comeback fanfares, no daily-login jingle. What we avoid is not rewarding
the player — it's *manipulating* them.

| Event | Motion (≤ 250 ms, response-only) | Sound — **frozen** (family playtest, 2026-07; Kenney CC0) |
|---|---|---|
| Select cell | spring-scale + indigo | `select_002` |
| Pair matched | emerald pop, fade to ghost | `confirmation_001` |
| Row collapse | row lifts and dissolves | `glass_002` |
| Add rows | new digits step in from below | `scroll_002` |
| Hint | pair turns orange, **stays until both are tapped** | `question_001` |
| Quietly unavailable | dim to gray (no shake) | `minimize_001` |
| Board cleared | emerald wave across cells | `jingles_PIZZI10` (the one loud moment; exempt from 250 ms) |
| Level unlocked | brief pop on the next level | `jingles_PIZZI01` |

### 10.1 Background music
Calm instrumental loops, quietly under the game — the one *ambient* element, and it's
opt-out-able in two taps:

- **Adventure:** each level has **its own fixed track** — part of the level's identity,
  like its seed and budgets.
- **Free Form & Daily:** the whole pool rotates.
- Music plays **only during a game in the foreground** — never from the background,
  never as a lure. Volume separate from effects; on/off in settings.
- **Jukebox** (shipped 2026-07-12): settings list every track with an on/off
  switch — dislike a track and the rotation simply skips it. The per-level /
  per-board selection above always draws from the *enabled* pool; new tracks
  default to on (the disliked set is what's stored). All tracks off = silence,
  honestly. Pool: seven Kevin MacLeod tracks (CC BY 4.0). Track titles are
  proper names, never localized.

### 10.2 Motion setting
Animations come in three levels — **Voll / Reduziert / Aus** (full / reduced / off) —
because good motion for one player is noise for another. *Reduziert* keeps only
essential state changes; *Aus* swaps states instantly. The OS "reduce motion"
preference is respected as the default.

**Scroll policy** (part of the stillness contract): the view only ever moves to follow
the player's own action — Nachlegen scrolls the first appended row into view (≤ 250 ms;
an instant jump under Reduziert/Aus), undoing an add scrolls back, and nothing else
ever scrolls or moves the viewport.

### 10.3 Settings surface (v1)
Effects volume (default **80 %**) · music on/off (**default on**) + volume (default
**45 %**) · motion (Voll/Reduziert/Aus) · appearance (system/light/dark) · font (the
Fuchsbau picker) · language (follows the system locale, en fallback, manual override;
the German localization uses **Swiss orthography** — ss, never ß) · about. **No
account, no premium, no notifications section — none exist.** Text size follows the
OS (§5). Settings and the Anleitung live on **Home only** (gear + `?`); the game
screen stays chrome-minimal.
Mockup: [`examples/ui/08-einstellungen.html`](./examples/ui/08-einstellungen.html).

- **All audio optional:** settings toggles, and the device's silent mode is always
  respected.
- **Assets:** sounds from Kenney.nl "Interface Sounds" + "Music Jingles" (**CC0**);
  music candidates by **Kevin MacLeod / incompetech.com (CC BY 4.0**, credited in the
  About screen**)**. Everything auditioned in
  [`examples/ui/07-klang.html`](./examples/ui/07-klang.html).
- The stillness rule (§9) is untouched: between responses, the board is perfectly
  still — music is sound, not motion.

## 11. Learning the game

New players meet a mechanic whose line-of-sight rules (diagonals! reading-order wrap!)
are genuinely non-obvious. v1 answer: a **static, illustrated "Anleitung"** screen —
the pairing rule, the four sight-lines as small diagrams, Nachlegen/Tipp/Undo, and the
scoring table (fulfilling §4's "shown in-app" promise). Reachable any time from Home
(a quiet `?` beside the settings gear), plus a **one-time, skippable** offer on first
launch ("Zum ersten Mal hier? → Kurz erklärt / Überspringen"). No interactive
tutorial — Adventure level 1's generous budgets are the soft on-ramp.

## 12. Home navigation

Each mode card does the *most-wanted thing*, not the same thing: **Freies Spiel**
resumes the live run in one tap (no run → parameter sheet; "new game anyway" lives in
the game screen's menu) · **Tages-Knobel** always opens the calendar · **Abenteuer**
always opens the level list.

## 13. Open items

**Still open (playtest-shaped):**
1. The Adventure 20-level curve (budget/factor curation) — during playtesting.
2. Passive hint-availability indicator — rejected for v1; revisit only if playtesting
   shows hopeless-board scanning.

**Resolved (design grilling, 2026-07):** fairness gate + salted rerolls · full-copy
adds · scoring formula (flat 10, stacking rows, conditional add bonus) · auto-end with
undo-back-in + best-kept commits · true-rewind undo · deterministic hints with free
re-pulse · bot targets ×0.9/ramp · daily clock semantics + zero anti-cheat · QR
payload with versioning on both platforms · run slots (FF single, per-date, per-level)
· engine constants (35/9/no cap — opening amended from 27 to 35 on 2026-07-12 to
match the reference game) · record-all stats · music default on · word seeds
with normalization + FNV-1a · daily epoch 2026-07-01 · Swiss German · home-card
semantics · scroll policy · hint/selection layering.

**Deferred (v2 candidates):** difficulty setting (target-factor shift) · Free Form
multi-slot · lifetime statistics page · https App/Universal
Links under fuchsnest.ch · seed-word wordlist for prettier random seeds.
(The jukebox track picker shipped 2026-07-12 — §10.1.)
