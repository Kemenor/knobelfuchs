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
- Phases 0–5 ✅ (mockups · engine · board UI + Free Form · persistence · Daily +
  Abenteuer · polish: sounds/music/settings/Anleitung/QR). On-device verification
  pending for phases 4–5 (tablet with its owner) — first tablet session: smoke-test
  Daily calendar, Abenteuer, sounds/music, settings, scanner, deep link.
- Remaining: Phase 6 release (fox icon done; fastlane, signing, store listing,
  landing page under fuchsnest.ch once live). Full match/collapse motion pass =
  iterate on device.
- 71 tests green. Debug installs via `flutter build apk --debug` +
  `adb install -r build\app\outputs\flutter-apk\app-debug.apk`.
