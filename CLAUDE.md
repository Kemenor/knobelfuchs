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
  Abenteuer · polish: sounds/music/settings/Anleitung/QR/jukebox). Both test
  devices verified (tablet = Mom's Xiaomi Pad 5 — **never install on it without
  explicit go-ahead**; phone = A024, install freely).
- Phase 6 release: signing keystore + CI pipeline DONE (knabberfuchs-style —
  `fastlane/RELEASING.md`). Play Console app, service account, secrets and
  Android screenshots DONE 2026-07-14; **closed testing live at 0.2.3+5**.
  Landing pages live: knobelfuchs.fuchsnest.ch (+/de/, /privacy/). Remaining:
  iOS Mac step (`HANDOVER_IOS_MAC.md`), family verdict on bot-vs-P75 targets
  (P75 shows in debug builds only), music audition (12 tracks),
  match/collapse motion pass.
- 2026-07-15 full review + fix pass: backup import transactional (staged
  temp + `.bak` swap, `user_version` cross-check, zip-bomb caps), challenge
  payloads range-checked, board ceiling 540, atomic run-end commit,
  Nachlegen follow-scroll fixed, music survives shade-peeks, §6.1 discard
  guard on every start path, DST-safe calendar. Rule changes are in
  design-concept.md §13 (2026-07-15 entry).
- Release flow: write 4 changelogs → `tool/cut_release.sh x.y.z` → v-tag → CI
  ships to Play internal+alpha and TestFlight. 106 tests green.
- Debug installs via `flutter build apk --debug` +
  `adb install -r build\app\outputs\flutter-apk\app-debug.apk`.
