> **Note:** fastlane regenerates `fastlane/README.md` (a bare lane list) on
> every run, so the real release guide lives here in `RELEASING.md`.
> Ported from knabberfuchs — same flow, same tooling.

# Releasing Knobelfuchs (`ch.fuchsnest.knobelfuchs`)

## The normal path (CI)

1. Write the four changelogs for the NEXT build number:
   `fastlane/metadata/android/<locale>/changelogs/<build>.txt`
   (locales: en-US, de-DE, fr-FR, it-IT — build 1 already exists).
2. `tool/cut_release.sh x.y.z` — verifies tree/changelogs/CI, bumps pubspec,
   tags `vX.Y.Z`, pushes.
3. The tag triggers:
   - `android.yml` → analyze+test gate → signed AAB → *completed* release on
     Play **internal** (instant, the family track) + **alpha** (closed testing).
   - `ios.yml` → analyze+test gate → TestFlight.

Manual fallback (Android): `flutter build appbundle --release` →
`python3 tool/play_upload_aab.py <track>` (needs
`fastlane/play-store-key.json` + `android/key.properties` locally).

## Repository secrets

| Secret | Status |
|---|---|
| `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, `ANDROID_STORE_PASSWORD` | ✅ set 2026-07-14 (keystore generated on the Windows box) |
| `PLAY_STORE_KEY_JSON_BASE64` | ⏳ reuse the knabberfuchs service-account key (ProtonDrive / Linux box) — also grant the service account access to this app in the Play Console |
| `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_API_KEY_P8_BASE64` | ⏳ reuse knabberfuchs's values (team-scoped key) |
| `IOS_DIST_CERT_P12_BASE64`, `IOS_DIST_CERT_PASSWORD`, `KEYCHAIN_PASSWORD` | ⏳ reuse knabberfuchs's values (team distribution cert) |
| `IOS_PROVISION_PROFILE_BASE64` | ⏳ NEW — App Store profile for `ch.fuchsnest.knobelfuchs` (Mac step below) |

**Keystore backup:** `android/upload-keystore.jks` + `android/key.properties`
exist only on the Windows box and in the GitHub secrets — copy both to
ProtonDrive like the knabberfuchs keystore. Losing the upload key is
recoverable via Play's upload-key reset, but the backup is cheaper.

## One-time Play Console setup (manual, owner account)

1. **Create the app**: Play Console → Create app → "Knobelfuchs", German
   default (or English), Game, Free.
2. **Link the service account**: Users and permissions → invite the
   knabberfuchs service account (or grant it app access under API access) with
   Release permission for this app. Then set `PLAY_STORE_KEY_JSON_BASE64`.
3. **First upload**: run the android.yml workflow (tag or dispatch to
   `internal`). Opt in to Play App Signing when prompted on first upload.
4. **Testers**: Testing → Internal testing → create an email list with the
   family's Google accounts → share the opt-in link. Internal releases are
   available within minutes and need no review.
5. **Console-only forms** (required before the *alpha/closed* release is
   reviewed, not for internal): store listing (texts/graphics come from
   `fastlane listing` or `tool/play_publish`-style push; screenshots still
   needed), content rating questionnaire, target audience, Data safety
   ("no data collected" — matches the privacy policy), privacy policy URL:
   `https://knobelfuchs.fuchsnest.ch/privacy/`.

## One-time App Store setup (manual, Mac + ASC)

1. Register bundle id `ch.fuchsnest.knobelfuchs`; create the app in App Store
   Connect (name Knobelfuchs, privacy policy URL as above).
2. On the Mac: open `ios/Runner.xcworkspace`, set the team, one manual signed
   TestFlight build (creates the App Store provisioning profile). Export
   `ios/ExportOptions.plist` (commit it) and the profile
   (`base64` → `IOS_PROVISION_PROFILE_BASE64` secret).
3. TestFlight → internal testers (family Apple IDs).
4. Screenshots + App Privacy answers in ASC before any App Store submission
   (`fastlane ios listing` pushes the text metadata).

## Layout

```
fastlane/
  Appfile                       package name + key path
  Fastfile                      android: validate/listing/internal · ios: beta/listing/release/validate
  play-store-key.json           Play service-account key — GITIGNORED
  AuthKey_<id>.p8               ASC API private key       — GITIGNORED
  metadata/android/<locale>/    title/short/full + changelogs/<build>.txt + images/
  metadata/ios/<locale>/        name/subtitle/keywords/description/promotional/release_notes/URLs
```

Play locales: en-US (default), de-DE, fr-FR, it-IT. App Store locales:
en-US, de-DE, fr-FR, it.

## Still needed before the *public* listings can go live

- **Screenshots**: phone + 7"/10" tablet for Play (the tablet matters — it's
  the primary device); 6.7" iPhone + 13" iPad for the App Store. Capture on
  real devices via adb / the simulator once the store entries exist.
- The de/fr/it copy is a first pass — give it a family read before publishing.
- `supply`/`deliver` don't cover the content-rating questionnaire, target
  audience, or Data-safety/App-Privacy forms — those stay in the consoles.
