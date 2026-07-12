# Knobelfuchs — Plan

A calm, ad-free number-match puzzle — the first fuchs **game**, tablet-first for a
Xiaomi Pad 5. The rules and semantics are frozen in
[`design-concept.md`](./design-concept.md) (the *what*); **this doc owns the *how***:
stack, architecture, and build order. When the two disagree, the concept wins for
semantics; this plan wins for implementation.

## Philosophy carried into the build

1. **The engine is a pure function.** Board, match validation, line-of-sight, deal,
   collapse, undo — all pure Dart over immutable state. No I/O, no widgets, no clock
   (the game has *no time semantics* by design). 100 % unit-testable.
2. **A game must never call you back.** No notifications at all — the one fuchs app
   where even `flutter_local_notifications` is omitted.
3. **Every move is durable.** Autosave on each action; process death is invisible.

## Decisions

| Area | Decision |
|---|---|
| Framework | **Flutter**, Android-first (iOS possible) — same toolchain as siblings |
| Game engine | **None — plain Flutter.** A static grid puzzle needs no Flame/game loop; widgets + implicit animations suffice. The Fuchsbau stack needs **no expansion** |
| State | **Riverpod** |
| Persistence | **drift / SQLite** — saved runs (board + undo log, one per mode), daily-knobel history, story progress, lifetime stats; with migrations |
| Seeds & RNG | **Seeded PRNG in the domain core** (injected, deterministic) — same seed ⇒ identical board on every device. Daily seed = local date; targets from the deterministic baseline bot (concept §4.1) |
| QR sharing | `qr_flutter` (render) + `mobile_scanner` (scan — knabberfuchs precedent). Free-Form challenge payload only; later phase |
| Design | **Material 3**, Fuchsbau triad & fonts via the [fuchsbau package](https://github.com/Kemenor/fuchsbau); deviations in [`DESIGN_SYSTEM.md`](./DESIGN_SYSTEM.md) |
| Layout | **Tablet-first, responsive** — Xiaomi Pad 5 (11″, 2560×1600) is the reference device, portrait *and* landscape; phones supported by the same adaptive layout |
| Networking | **None.** Fully on-device, no runtime keys |
| Notifications | **None.** Games don't nag (concept §5) |
| l10n | **en / de / fr / it** from day one; ARB files, no hardcoded strings |
| Navigation | Router-less (Fuchsbau): single stack, `push` for settings/stats sheets |
| Keys / SDK | `INTEGER` autoincrement PKs; min Android API **26**; arm64 release builds |
| Backup | ZIP (SQLite snapshot + JSON) — same pattern as siblings; low priority for v1 (stats are the only real data) |
| App id | `ch.fuchsnest.knobelfuchs` — the family convention: one collection domain (**fuchsnest.ch**), app ids `ch.fuchsnest.<appname>` |
| Repo | `Kemenor/knobelfuchs`, public, Apache-2.0 |

## Architecture

```
lib/
  core/        theme glue (fuchsbau), formatting
  data/
    db/        drift tables: saved_game (board, undo log), game_stats
    repositories/
  domain/      PURE engine — Board (immutable), pair validation, line-of-sight
               scan, deal, row collapse, hint finder, undo. No Flutter, no drift.
  ui/
    game/      board widget (adaptive cell size), selection, animations,
               deal/hint/undo bar, win celebration
    stats/     lifetime + per-game stats sheet
    settings/  theme, font picker, language, about
  l10n/        app_en.arb + de/fr/it mirrors
```

### Engine sketch

- `Board` = immutable list of cells (digit or cleared) + column count (9).
- `generate(seed)` → opening board (seeded PRNG, deterministic across devices).
- `canMatch(board, a, b)` — value rule && line-of-sight (row / column / diagonal /
  reading-order, skipping cleared cells).
- `match(board, a, b)` → new board, with collapsed rows removed.
- `addRows(board)` → new board with surviving digits appended (budget enforced by
  `GameState`, not the board).
- `findHint(board)` → first valid pair or *none* (⇒ point at add; free).
- `score(events)` — the transparent formula (concept §4): pair +10, row +50, clear
  +250, unused add +50.
- `baselineBot(seed, ruleset)` → target score: greedy first-pair-in-reading-order,
  adds when stuck; deterministic, runs at generation time.
- `GameState` = board + budgets (adds/hints remaining) + move log + score; undo =
  replay log minus one (or board snapshots — decide by measuring; boards are tiny).
- `GameConfig` = seed + add budget + hint budget + optional target — one struct for
  all three modes *and* the QR payload.

## Build order

0. **Mockups first** — `examples/ui/` HTML canon for family feedback *before* any
   Flutter code; the primary player reviews the board, home, and end screens.
1. **Engine + tests.** The full ruleset as pure Dart, unit-tested against known
   positions (line-of-sight edge cases: wrap-around, diagonals through cleared gaps,
   5-5 pairs, collapse cascades), seeded generation determinism, scoring, the
   baseline bot.
2. **Board UI + Free Form.** Adaptive grid, tap-tap selection, match/collapse
   animations, add/hint/undo with budgets, the parameter sheet — playable end-to-end
   on the Pad 5, both orientations.
3. **Persistence.** Autosave every move; resume on launch; run history + stats.
4. **Daily & Story.** Date seed + computed target; the level list + unlock chain
   (curate ~20 levels via the bot).
5. **Polish.** Win/run-end screens, settings (theme/font/language, 200 % scale pass),
   l10n, QR share/scan.
6. **Release.** Icon, store listing, fastlane, landing page (under fuchsnest.ch).

## Toolchain note

Development happens on two machines: the Linux box (Flutter via the `flutter`
distrobox, per fuchsbau) and the Windows box (Flutter native at `C:\flutter`, on
PATH — plain `flutter` works).

## Still open

- Landing page location under fuchsnest.ch (subdomain vs. path) — decide before release.
- Whether the fuchsbau package is consumed as a git dependency or path dependency
  during development.
- Scoring weights + story difficulty curve — freeze after family playtesting
  (concept §10).
