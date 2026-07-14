# Handover: knobelfuchs iOS/TestFlight setup (Mac session)

You are picking up the knobelfuchs project on Thomas's Mac. Your mission is the
**one-time iOS setup** that unlocks the TestFlight pipeline — everything else
(Android, Play closed testing, store listing, landing pages) is already live.
Read `CLAUDE.md` and `fastlane/RELEASING.md` first; they are current.

## Context in three sentences

Knobelfuchs (`ch.fuchsnest.knobelfuchs`) is a calm number-match puzzle — the
first fuchs *game*, sibling of knabberfuchs (already LIVE on the App Store,
same Apple team, same conventions — use its repo as the reference
implementation whenever unsure). Releases are tag-driven: `tool/cut_release.sh
x.y.z` pushes a v-tag, `.github/workflows/android.yml` ships to Play (working,
closed testing live at version 0.2.3+5), and `.github/workflows/ios.yml` ships
to TestFlight — **currently failing at the signing step by design**, because
one secret and one file don't exist yet. Creating them is your job.

## What already exists (do not redo)

- `ios/` is configured: bundle id `ch.fuchsnest.knobelfuchs`, deep-link scheme
  `knobelfuchs://` (CFBundleURLTypes), `NSCameraUsageDescription` (QR scanner).
- GitHub repo secrets on `Kemenor/knobelfuchs`, all verified working for
  Android: `ASC_KEY_ID` (B8TQ2VVZMA), `ASC_ISSUER_ID`, `ASC_API_KEY_P8_BASE64`
  (team-scoped App Store Connect API key, App Manager role),
  `IOS_DIST_CERT_P12_BASE64` + `IOS_DIST_CERT_PASSWORD` (the team's Apple
  Distribution cert, shared with knabberfuchs), `KEYCHAIN_PASSWORD`.
- **Missing:** `IOS_PROVISION_PROFILE_BASE64` (App Store provisioning profile
  for THIS bundle id) and a committed `ios/ExportOptions.plist`.
- `fastlane/Fastfile` has the ios lanes (`beta`, `listing`, `release`,
  `validate`); `fastlane/metadata/ios/` holds the full App Store metadata in
  en-US/de-DE/fr-FR/it, privacy URL `https://knobelfuchs.fuchsnest.ch/privacy/`.
- The ASC API `.p8` lives in ProtonDrive `knabberfuchs-secrets/`
  (`AuthKey_B8TQ2VVZMA.p8`); place a copy at `fastlane/AuthKey_B8TQ2VVZMA.p8`
  (gitignored — never commit, print, or paste key material).

## Your tasks, in order

1. **Register the bundle id + create the app in App Store Connect.**
   Prefer `fastlane produce` with the API key (app name "Knobelfuchs",
   primary language German, SKU `knobelfuchs`); the ASC UI is the fallback —
   Thomas is present and does any step requiring his Apple ID login himself.
2. **Xcode sanity pass** (`open ios/Runner.xcworkspace`): team set,
   `TARGETED_DEVICE_FAMILY = 1,2` (the game is TABLET-FIRST — iPad support is
   not optional), bundle id correct, no signing warnings.
3. **One signed App Store build.** Let Xcode automatic signing create the App
   Store provisioning profile for `ch.fuchsnest.knobelfuchs`, archive, upload
   to TestFlight once manually (or `flutter build ipa` + `fastlane ios beta`).
4. **Export the CI artifacts:**
   - `ios/ExportOptions.plist` — method `app-store`, manual signing, the team
     id and the NEW profile name. Mirror knabberfuchs's file. **Commit it.**
   - The `.mobileprovision` of the new profile → `base64 -i <file> | gh secret
     set IOS_PROVISION_PROFILE_BASE64 --repo Kemenor/knobelfuchs --body-file -`
     (or pass via `--body` — ensure no trailing newline corruption; verify by
     re-running CI rather than by printing anything).
5. **Prove the pipeline:** `gh workflow run ios.yml --repo Kemenor/knobelfuchs`
   → the `testflight` job must go green and the build must appear in
   TestFlight. That is the definition of done.
6. **TestFlight internal testers:** add Thomas's Apple ID (ask him which — do
   not guess) to an internal group so installs work immediately.
7. **Push the App Store metadata:** `fastlane ios validate`, then
   `fastlane ios listing`. Nothing is submitted for review — drafts only.
8. **Update the ledgers:** mark `IOS_PROVISION_PROFILE_BASE64` ✅ in
   `fastlane/RELEASING.md`, refresh the State block in `CLAUDE.md`, commit,
   push. Back up the new profile to ProtonDrive `knobelfuchs-secrets/`
   (the Android keystore backup convention lives there already).

## Deferred — do not start unless asked

iOS store screenshots (`tool/screenshots.sh ios`, needs a 6.9" iPhone +
13" iPad simulator run — the shot list is `integration_test/screenshots_test.dart`
and already produced the Android sets), App Store review submission
(`fastlane ios release` — Thomas decides when), and anything gameplay-related.

## House rules that bite

- `lib/domain/` is pure Dart — no Flutter/I/O/clock/platform-hashCode. You
  should not need to touch `lib/` at all in this session.
- Never commit secrets; `AuthKey_*.p8`, `*.p12`, `key.properties`,
  `play-store-key.json` are gitignored — keep it that way.
- `flutter analyze` and `flutter test` must be green before any commit
  (92 tests currently green).
- Commit messages: plain prose, no double quotes (they break the Windows-side
  tooling Thomas also uses), no Generated-with footers.
- German user-facing copy uses Swiss orthography (ss, never ß).
- If anything in this handover contradicts what you find in the repo, trust
  the repo and say so out loud.
