#!/usr/bin/env bash
# Cut a test release: bump pubspec, verify the four changelogs, commit, tag,
# push. The v-tag then triggers CI (android.yml → Play internal + alpha,
# ios.yml → TestFlight), which re-asserts tag == pubspec as the backstop.
# (Ported from knabberfuchs.)
#
#   tool/cut_release.sh 0.1.0
#
# The build number is auto-incremented from pubspec. Changelog files for the
# NEW build number must already exist (all four locales) — write them first:
#   fastlane/metadata/android/<locale>/changelogs/<build>.txt
set -euo pipefail

VERSION=${1:?usage: tool/cut_release.sh <x.y.z>}
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "✗ '$VERSION' is not x.y.z"; exit 1; }

cd "$(dirname "$0")/.."

BRANCH=$(git rev-parse --abbrev-ref HEAD)
[ "$BRANCH" = "main" ] || { echo "✗ on '$BRANCH', releases cut from main"; exit 1; }
# Tracked changes only (-uno): untracked scratch can't reach the release
# commit — the script stages nothing but pubspec.yaml.
[ -z "$(git status --porcelain -uno)" ] || { echo "✗ working tree has uncommitted tracked changes"; exit 1; }

git fetch -q origin main
[ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ] \
  || { echo "✗ main is not in sync with origin/main (pull/push first)"; exit 1; }

CURRENT=$(grep -m1 '^version:' pubspec.yaml | awk '{print $2}')
CUR_BUILD=${CURRENT##*+}
NEW_BUILD=$((CUR_BUILD + 1))
NEW="$VERSION+$NEW_BUILD"
[ "$VERSION" != "${CURRENT%%+*}" ] || { echo "✗ $VERSION is already the current version ($CURRENT)"; exit 1; }
# Reject going backwards: sort -V puts the higher version last.
HIGHEST=$(printf '%s\n%s\n' "${CURRENT%%+*}" "$VERSION" | sort -V | tail -1)
[ "$HIGHEST" = "$VERSION" ] || { echo "✗ $VERSION is lower than the current version ($CURRENT)"; exit 1; }
echo "✓ pubspec: $CURRENT → $NEW"

MISSING=0
for LOC in en-US de-DE fr-FR it-IT; do
  F="fastlane/metadata/android/$LOC/changelogs/$NEW_BUILD.txt"
  if [ ! -s "$F" ]; then echo "✗ missing changelog: $F"; MISSING=1; fi
done
[ "$MISSING" -eq 0 ] || { echo "  write the four changelogs for build $NEW_BUILD, then re-run"; exit 1; }
echo "✓ changelogs $NEW_BUILD.txt ×4 locales exist"
echo "ℹ reminder: fastlane/metadata/ios/*/release_notes.txt is the TestFlight/App-Store"
echo "  'What's New' — update it if this build changes user-visible behaviour"

# Best-effort CI check on the tip commit (gh optional).
if command -v gh >/dev/null 2>&1; then
  CONCLUSIONS=$(gh api "repos/{owner}/{repo}/commits/$(git rev-parse HEAD)/check-runs" \
    --jq '[.check_runs[].conclusion] | unique | join(",")' 2>/dev/null || echo "unknown")
  case "$CONCLUSIONS" in
    success) echo "✓ CI green on HEAD" ;;
    "")      echo "⚠ no CI runs found for HEAD (still running?) — the tag build re-tests anyway" ;;
    *)       echo "⚠ CI on HEAD: $CONCLUSIONS — the tag build gates on tests, a red one won't ship" ;;
  esac
fi

sed -i.bak "s/^version: .*/version: $NEW/" pubspec.yaml && rm pubspec.yaml.bak
git add pubspec.yaml
git commit -q -m "chore(release): $NEW"
git tag "v$VERSION"
git push origin main "v$VERSION"
echo "✓ pushed main + v$VERSION → CI ships to Play internal + alpha and TestFlight"
