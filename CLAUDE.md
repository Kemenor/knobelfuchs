# Knobelfuchs — working guide

Calm number-match puzzle (Take Ten / Zahlenknobeln), the first fuchs **game**.
Tablet-first (Xiaomi Pad 5), ad-free, local-first, no dark patterns.

## Read first
- [`design-concept.md`](./design-concept.md) — frozen rules & semantics (the *what*).
  §13 is the decision ledger from the 2026-07 design grilling.
- [`PLAN.md`](./PLAN.md) — stack, engine sketch, build order (the *how*).
- [`DESIGN_SYSTEM.md`](./DESIGN_SYSTEM.md) — inherits fuchsbau; knobelfuchs deviations.
- [`examples/ui/`](./examples/ui/) — HTML mockups = visual canon (German, family-approved).

## Toolchain
- **Windows box:** Flutter native at `C:\flutter`, on PATH — plain `flutter analyze`,
  `flutter test`, `flutter run`.
- **Linux box:** Flutter via distrobox — `distrobox enter flutter -- bash -lc 'flutter <cmd>'`.
- Mockup live preview: `npx live-server --port=8642 --no-browser examples/ui`.

## Non-negotiables
- `lib/domain/` is **pure Dart** — no Flutter, no I/O, no clock, no platform `hashCode`
  (determinism across devices is a game feature: seeds, fairness rerolls, bot targets).
- Every rule change starts in `design-concept.md`, then engine + tests, then UI.
- Red is for destructive actions only. Nothing in normal play is ever red.
- German UI copy uses Swiss orthography (ss, never ß). l10n: en/de/fr/it.
- App id `ch.fuchsnest.knobelfuchs`; deep link scheme `knobelfuchs://` (both platforms).

## State (keep current)
- Phase 0 (mockups) ✅ family-approved · Phase 1 (engine + tests) ✅ 57 tests green ·
  next: Phase 2 — board UI + Free Form on the fuchsbau theme.
