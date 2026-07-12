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

### 2.1 Opening deal
Every game is generated from a **seed**: the opening rows are drawn from a seeded PRNG,
so the same seed always produces the identical game. This is the backbone of all three
modes (§6) and of challenge-sharing (§7). The opening size is ~3 rows (tunable
constant, same for all modes).

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
board. Each game has an **add budget** — default **5**, up to **limitless** where the
mode allows (§6). The remaining count sits on the button as neutral information; at 0
the button turns **gray** (quietly unavailable, not alarmed — nothing red).

### 3.5 Hints
The **hint button** highlights one currently-valid pair (amber — *information, not
command*). Each game has a **hint budget** — default **5**, up to **limitless** where
the mode allows. Pressing hint when **no valid pair exists** shows the button gray and
points at the add button instead — this **does not consume** a hint (telling you
"nothing is there" is honesty, not help). At budget 0 the button turns gray.

### 3.6 End of a run
- **Board cleared** — the crowning finish (bonus, celebration).
- **No moves left** (no valid pair, add budget exhausted) — the run **completes** with
  its score. This is a natural end, *not a fail state*: no "GAME OVER", no red, the
  score simply stands. One quiet screen: score, target comparison, "again?".
- A game in progress is **autosaved** every move and waits indefinitely.

## 4. Scoring

Scores make seeds shareable ("beat 1 840 on this board") and give runs a shape. The
formula is **simple, transparent, and shown in-app** — no hidden multipliers:

| Event | Points |
|---|---|
| Pair matched | **+10** |
| Row cleared | **+50** |
| Board fully cleared | **+250** |
| Each unused add at the end | **+50** |

- **Hints never cost points.** Assist use is not punished — the budget is the only
  limit (information, never punishment).
- The formula is a v1 proposal — **frozen only after family playtesting**.

### 4.1 Score to beat
A game can carry a **target score**. Beating it is the win condition in Daily and
Story modes and an optional spice in Free Form. Targets are **computed, not designed**:
a deterministic **baseline bot** (greedy: always the first valid pair in reading order,
adds when stuck) plays the seed at generation time; its final score is the target. Same
seed ⇒ same target on every device — no server, no authoring burden.

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
The everyday mode. "New game" opens a small parameter sheet:

- **Seed** — empty = randomized (shown after generation so it can be shared);
  enterable to replay or take on a challenge.
- **Adds** — stepper, 0 … 20, then ∞. Default 5.
- **Hints** — stepper, 0 … 20, then ∞. Default 5.
- **Score to beat** — optional number, default off.

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
to play Wednesday loses nothing. **Future dates are locked** (quiet gray lock, checked
against the device date) — the point of a daily is that everyone meets the same board
*on* the day; tomorrow simply isn't knowable yet.

A missed day is simply an open slot, still waiting — **no streak guilt, no red, no
notification**. The daily waits; it never calls.

### 6.3 Story
A curated, numbered level collection (v1: ~20 levels). Each level = seed + add budget +
hint budget + target score; **beating the target unlocks the next level**. Difficulty
climbs by tightening budgets and raising targets — never by timers. Progress is stored
locally; replaying a beaten level is always allowed (best score kept).

## 7. Challenge sharing (QR)

Free Form settings (seed, add budget, hint budget, score to beat) encode into a QR code
on the run-end screen — "beat me on this board." Scanning one inside knobelfuchs
pre-fills the parameter sheet. Fully offline, peer-to-peer, no server; the QR *is* the
challenge. (Scan via in-app camera view; family precedent: knabberfuchs's scanner.)

## 8. Stats — information, never punishment

Per run: score, matches, rows cleared, adds/hints used, duration (recorded, **not
displayed during play** — no clock on the game screen). Lifetime: runs, boards cleared,
daily history, story progress. No streaks-with-guilt, no daily-login rewards, no
notifications — **a game must never call you back**; it waits.

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

| Event | Motion (≤ 250 ms, response-only) | Sound (candidates) |
|---|---|---|
| Select cell | spring-scale + indigo | soft select/click |
| Pair matched | emerald pop, fade to ghost | pluck / confirm |
| Row collapse | row lifts and dissolves | glass chime |
| Add rows | new digits step in from below | drop / shuffle |
| Hint | one amber pulse on the pair | soft question ping |
| Quietly unavailable | dim to gray (no shake) | low muted tone |
| Board cleared | emerald wave across cells | short jingle (the one loud moment; exempt from 250 ms) |
| Level unlocked | brief pop on the next level | short upbeat |

- **All sounds optional:** a settings toggle, and the device's silent mode is always
  respected. No background music in v1.
- **Assets:** Kenney.nl "Interface Sounds" + "Music Jingles", both **CC0** — bundled,
  no attribution required (we credit anyway). Candidates are auditioned with their
  animations in [`examples/ui/07-klang.html`](./examples/ui/07-klang.html).
- The stillness rule (§9) is untouched: between responses, the board is perfectly
  still.

## 11. Open questions (for family playtesting)

1. Should the hint button *passively* show gray whenever no pair exists (constant free
   information — kinder, but removes the scanning challenge)? v1: only on press.
2. Scoring weights (§4) — tune after real runs.
3. Opening size (3 rows?) and Story difficulty curve.
4. ~~Daily calendar view — v2 candidate.~~ **Promoted to v1** (family requirement):
   the calendar *is* the daily date picker (§6.2).
5. Final sound picks per event (§10) — audition via `07-klang.html`, then freeze.
