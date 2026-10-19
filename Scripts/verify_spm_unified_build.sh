#!/usr/bin/env bash
# Build unified SPM targets locally (not remote git package).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${DEST:-platform=iOS Simulator,name=iPhone 17 Pro}"
FAIL=0

echo "==> AppViewShared (macOS)"
cd "$ROOT"
if ! swift build --target AppViewShared -c debug; then
  echo "FAIL: AppViewShared macOS build" >&2
  FAIL=1
fi

echo "==> AppViewServer (iOS Simulator via Xcode scheme)"
if ! xcodebuild -scheme AppViewServer \
  -destination "$DEST" \
  -configuration Debug \
  build -quiet; then
  echo "FAIL: AppViewServer iOS Simulator build" >&2
  FAIL=1
fi

if [[ "$FAIL" -ne 0 ]]; then
  echo "RESULT: FAIL — verify_spm_unified_build" >&2
  exit 1
fi

echo "RESULT: PASS — verify_spm_unified_build (AppViewShared macOS + AppViewServer iOS)"
