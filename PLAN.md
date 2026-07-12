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
| Persistence | **drift / SQLite** — saved runs (board + undo log; Free Form/Story one each, Daily **one per date** so half-finished days survive), daily-knobel history, story progress, lifetime stats; with migrations |
| Seeds & RNG | **String seeds** (words or digits), normalized (trim/NFC/lowercase/spaces→dash, ≤32 chars), hashed with a **hand-rolled FNV-1a** (never platform `hashCode`) into the PRNG. Fairness gate ≥3 pairs via **`hash(seed, attempt)`** rerolls (no cross-seed collisions). Daily = internal `yyyymmdd` namespace, epoch **2026-07-01**. Targets from the baseline bot × factor (0.9 daily, 0.9→1.0 adventure), rounded to 10 |
| Deep links | `knobelfuchs://c?v=1&s&a&h&t` registered on **Android (intent-filter) and iOS (CFBundleURLTypes)**; scan pre-fills the sheet, never auto-starts |
| QR sharing | `qr_flutter` (render) + `mobile_scanner` (scan — knabberfuchs precedent). Free-Form challenge payload only; later phase |
| Audio | **`audioplayers`** — low-latency mode for action-response sounds, a looping player for background music (concept §10). Sounds: Kenney **CC0**, bundled. Music: Kevin MacLeod **CC BY 4.0** (credited in About); mp3s are **not in git** (too heavy — `examples/ui/README.md` has the re-fetch commands); bundled into the app at build time. Jukebox track picker = post-v1 |
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

Constants: opening **3 rows = 27 digits**, width **9** always, **no board-length cap**,
fairness floor **≥3 pairs**, daily epoch **2026-07-01**.

- `normalizeSeed(raw)` → trim → NFC → lowercase → whitespace→dash, ≤32 chars;
  `fnv1a(normalized)` → engine seed. All deterministic, all in pure Dart.
- `Board` = immutable list of cells (digit or cleared) + column count (9).
- `generate(seed)` → opening board via `prng(hash(seed, attempt))`, attempt++ until
  ≥3 available pairs (deterministic across devices).
- `canMatch(board, a, b)` — value rule && line-of-sight (row / column / diagonal /
  reading-order, skipping cleared cells).
- `match(board, a, b)` → new board, with collapsed rows removed.
- `addRows(board)` → full copy of survivors appended (never gated; budget enforced by
  `GameState`, refunded on undo).
- `findHint(board)` → **first valid pair in reading order** or *none*; consumption
  logic (free re-pulse, free "nothing there") lives in `GameState`; highlights
  re-validate after every board change.
- `isStuck(state)` — no valid pair && adds exhausted ⇒ auto run-end (undo-back-in
  allowed; results commit best-kept on every end).
- `score(events)` — frozen formula: pair +10 flat; row +50 stacking; clear +250;
  unused adds +50 **only on a cleared board**.
- `baselineBot(seed, config)` → plays first-pair-greedy with the run's add budget, no
  hints; `target = round10(botScore × factor)` — daily 0.9, adventure ramps 0.9→1.0.
- `GameState` = board + budgets + move log + score; undo = true rewind (matches and
  adds only — hints are outside the log); no redo.
- `GameConfig` = seed + add budget + hint budget + optional target — one struct for
  all three modes *and* the QR payload (`v=1` mandatory).
- Saved-run slots: Free Form **one**, Daily **per date**, Adventure **per level**;
  every run's full record written from day one (stats surfaced modestly, lifetime
  page v2).

## Build order

0. ✅ **Mockups first** — `examples/ui/` HTML canon, family-approved (sounds frozen,
   colours refined, calendar + settings added).
1. ✅ **Engine + tests.** The full ruleset as pure Dart in `lib/domain/` — seeds
   (normalize + FNV-1a), fairness-gated generation, line-of-sight, collapse, adds,
   hints, undo-as-replay, scoring, bot targets, daily, QR codec — 57 tests green.
2. **Board UI + Free Form.** Adaptive grid, tap-tap selection, match/collapse
   animations, add/hint/undo with budgets, the parameter sheet — playable end-to-end
   on the Pad 5, both orientations.
3. **Persistence.** Autosave every move; resume on launch; run history + stats.
4. **Daily & Story.** Date seed + computed target; the **month-calendar picker**
   (past days playable/resumable per-date, future locked by device date); the level
   list + unlock chain (curate ~20 levels via the bot).
5. **Polish.** Win/run-end screens, sound & motion pass (the family's picks from
   `07-klang.html`), settings (theme/font/language/sound, 200 % scale pass), l10n,
   QR share/scan.
6. **Release.** Icon, store listing, fastlane, landing page (under fuchsnest.ch).

## Toolchain note

Development happens on two machines: the Linux box (Flutter via the `flutter`
distrobox, per fuchsbau) and the Windows box (Flutter native at `C:\flutter`, on
PATH — plain `flutter` works).

## Still open

- Landing page location under fuchsnest.ch (subdomain vs. path) — decide before release.
- Whether the fuchsbau package is consumed as a git dependency or path dependency
  during development.
- The Adventure 20-level curve (budgets + target factors) — curate during playtesting.
- App icon / fox artwork — release phase (concept §13 lists the v2 candidates).
