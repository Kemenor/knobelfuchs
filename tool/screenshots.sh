#!/usr/bin/env bash
# Capture store screenshots with the integration_test harness (the single
# source of the shot list — integration_test/screenshots_test.dart) and file
# them into the fastlane layout that tool/play_publish.py uploads.
# (Ported from knabberfuchs.)
#
#   tool/screenshots.sh android [en de fr it]
#
# WARNING: uninstalls the app on the capture device first (fresh fixture
# state) — EXPORT A BACKUP on that device before running if its progress
# matters. Never point this at the tablet while it holds live progress.
#
# Uses the first `adb devices` device; override with DEVICE=<id>.
# SHOT_DIR chooses the Play slot: phoneScreenshots (default),
# sevenInchScreenshots or tenInchScreenshots (tablet capture).
set -euo pipefail

PLATFORM=${1:?usage: tool/screenshots.sh <android> [locales...]}
shift || true
LOCALES=("$@")
[ ${#LOCALES[@]} -gt 0 ] || LOCALES=(en de fr it)
SHOT_DIR=${SHOT_DIR:-phoneScreenshots}

cd "$(dirname "$0")/.."
command -v flutter >/dev/null || { echo "✗ flutter not on PATH"; exit 1; }

[ "$PLATFORM" = "android" ] || { echo "✗ only android capture is set up (ios comes with the Mac step)"; exit 1; }
DEVICE=${DEVICE:-$(adb devices | awk 'NR>1 && $2=="device"{print $1; exit}')}
[ -n "${DEVICE:-}" ] || { echo "✗ no adb device"; exit 1; }
echo "✓ target: $DEVICE → $SHOT_DIR"

for L in "${LOCALES[@]}"; do
  echo "=== capture $L ==="
  rm -rf "screenshots/$L"
  # Fresh app container per locale so the seeded fixture doesn't accumulate.
  adb -s "$DEVICE" uninstall ch.fuchsnest.knobelfuchs >/dev/null 2>&1 || true
  flutter drive \
    --driver=test_driver/integration_test.dart \
    --target=integration_test/screenshots_test.dart \
    --dart-define=LOCALE="$L" \
    -d "$DEVICE"
  ls "screenshots/$L"/*.png >/dev/null 2>&1 || { echo "✗ no screenshots produced for $L"; exit 1; }

  case "$L" in en) D=en-US;; de) D=de-DE;; fr) D=fr-FR;; it) D=it-IT;; *) D=$L;; esac
  DEST="fastlane/metadata/android/$D/images/$SHOT_DIR"
  mkdir -p "$DEST"
  rm -f "$DEST"/*.png
  # Google Play caps each slot at 8 — take the first 8 by NN_ ordering.
  ls "screenshots/$L"/*.png | sort | head -8 | xargs -I{} cp {} "$DEST/"
  echo "✓ $L → $DEST ($(ls "$DEST" | wc -l | tr -d ' ') files)"
done

echo "done — review the PNGs, then upload with: python tool/play_publish.py --commit"
