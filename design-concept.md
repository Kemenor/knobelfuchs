# Knobelfuchs — Game Concept

The first fuchs **game**. A calm number-match puzzle (the classic pen-and-paper
"Zahlenknobeln" / *Take Ten* mechanic, known from Number Match / Number Clash /
Numberzilla) — built the fuchs way: **no ads, no lives, no timers, no paywalled hints, no
manipulation**. The predatory clones gate the fun behind ad-views; Knobelfuchs simply
*is* the fun.

This doc owns the **what**: rules, states, and semantics. [`PLAN.md`](./PLAN.md) owns the
**how**.

## 1. Why it exists

Watching a family member play an ad-riddled Number Match clone: the game itself is
lovely — gentle, absorbing, endlessly replayable. Everything around it is hostile
(interstitials, "watch ad for hint", fake urgency). The mechanic is a decades-old
public-domain paper game; nobody owns it. So we build the respectful version, tuned for
the person it's for: **tablet-first** (Xiaomi Pad 5), big digits, generous assists.

## 2. The board

- A grid of **9 columns**; rows grow downward as the game progresses.
- Each cell is either a **digit 1–9** or **cleared** (was matched away).
- The board reads like text: **row-major reading order**, left→right, top→bottom.

### 2.1 Opening deal
The traditional opening: the digits of the numbers **1 to 19** written out in reading
order (`1 2 3 … 9 1 0 1 1 1 2 …` = **29 digits**, filling 3 rows + 2 cells). Every game
starts from this same deal — the variety comes from play order, exactly like the paper
original. (A seeded-random opening is a possible later mode, not v1.)

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

### 3.4 Dealing more ("Nachlegen")
When the player wants more material (stuck or just strategic): the **deal button**
appends *all surviving digits* in reading order to the end of the board.
**Unlimited and free.** The deal count is shown as neutral information — lower is a
brag, higher is not a failure.

### 3.5 Win & end states
- **Win:** the board is completely empty. Celebration, stats, "play again".
- **There is no lose state.** No lives, no timer, no fail. A game can always continue
  or be abandoned; an abandoned game just waits (autosaved) until resumed or replaced.

## 4. Assists — generous by design

| Assist | Behaviour | Cost |
|---|---|---|
| **Hint** | Highlights one currently-valid pair (amber — *information, not command*). | Free, unlimited |
| **Undo** | Steps back one match (or one deal). Unlimited depth, back to the opening. | Free, unlimited |
| **Autosave** | Every move persists instantly; the app can be killed at any time. | Automatic |

The clones sell these back to the player through ads. Here they are simply part of the
game. If no valid pair exists on the board, the hint gently points at the deal button.

## 5. Stats — information, never punishment

Per game: matches made, rows cleared, deals used, duration (recorded, **not displayed
during play** — no clock on the game screen). Lifetime: games completed, total matches.
No streaks-with-guilt, no daily-login rewards, no notification nagging — **a game must
never call you back**; it waits.

## 6. Modes

- **v1: Classic.** One ongoing game, endless until cleared. "New game" restarts (with
  confirmation if a game is in progress).
- **Later (maybe):** a daily knobel (same seed for everyone), seeded-random openings,
  a harder ruleset (no diagonals). Only if they stay calm.

## 7. Audience & ergonomics

Built first for a retired parent on an **11″ tablet** (Xiaomi Pad 5, 2560×1600,
landscape or portrait):

- **Big digits** — cells scale with the screen; on the Pad ≈ 64 dp+, never below 48 dp.
- **Tap-tap interaction only** — no drag, no swipe, no long-press required anywhere in
  the game itself.
- **High contrast** digits in both themes; the accessibility font picker (Fuchsbau)
  applies to digits too — tabular figures throughout.
- **No moving parts** while thinking: the board is perfectly still until the player
  acts. Animations are short responses to input, never ambient.
- Phones remain supported — same layout, smaller cells, scrolling board.
