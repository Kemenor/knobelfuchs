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
| Persistence | **drift / SQLite** — current game (board + undo stack) and stats, with migrations |
| Design | **Material 3**, Fuchsbau triad & fonts via the [fuchsbau package](https://github.com/Kemenor/fuchsbau); deviations in [`DESIGN_SYSTEM.md`](./DESIGN_SYSTEM.md) |
| Layout | **Tablet-first, responsive** — Xiaomi Pad 5 (11″, 2560×1600) is the reference device, portrait *and* landscape; phones supported by the same adaptive layout |
| Networking | **None.** Fully on-device, no runtime keys |
| Notifications | **None.** Games don't nag (concept §5) |
| l10n | **en / de / fr / it** from day one; ARB files, no hardcoded strings |
| Navigation | Router-less (Fuchsbau): single stack, `push` for settings/stats sheets |
| Keys / SDK | `INTEGER` autoincrement PKs; min Android API **26**; arm64 release builds |
| Backup | ZIP (SQLite snapshot + JSON) — same pattern as siblings; low priority for v1 (stats are the only real data) |
| App id | `ch.knobelfuchs.app` *(domain TBD — decide before release)* |
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
- `canMatch(board, a, b)` — value rule && line-of-sight (row / column / diagonal /
  reading-order, skipping cleared cells).
- `match(board, a, b)` → new board, with collapsed rows removed.
- `deal(board)` → new board with surviving digits appended.
- `findHint(board)` → first valid pair or *none* (⇒ point at deal).
- `GameState` = board + move log; undo = replay log minus one (or store board
  snapshots — decide by measuring; boards are tiny).

## Build order

1. **Engine + tests.** The full ruleset as pure Dart, unit-tested against known
   positions (line-of-sight edge cases: wrap-around, diagonals through cleared gaps,
   5-5 pairs, collapse cascades).
2. **Board UI.** Adaptive grid, tap-tap selection, match/collapse animations, deal —
   playable end-to-end on the Pad 5, both orientations.
3. **Persistence.** Autosave every move; resume on launch; stats.
4. **Assists & polish.** Hint, undo, win celebration, settings (theme/font/language),
   l10n pass.
5. **Release.** Icon, store listing, fastlane, landing page (`docs/` + CNAME).

## Still open

- Domain name (knobelfuchs.ch?) → app id confirmation.
- Whether the fuchsbau package is consumed as a git dependency or path dependency
  during development.
- Later modes (daily knobel, seeded openings) — explicitly out of v1.
