#!/usr/bin/env bash
# Inventory @objc / @objcMembers / legacy .h; fail if above baseline (G6/G7).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO="$(cd "$ROOT/.." && pwd)"
BASELINE="$ROOT/Scripts/objc_legacy_baseline.env"

if [[ ! -f "$BASELINE" ]]; then
  echo "count_swift_objc: FAIL — missing $BASELINE" >&2
  exit 1
fi
# shellcheck source=/dev/null
source "$BASELINE"

count_rg() {
  local pattern="$1"
  local path="$2"
  shift 2
  rg -c "$pattern" "$path" "$@" 2>/dev/null | awk -F: '{s+=$2} END {print s+0}'
  true
}

SHARED_APPVIEW=$(count_rg '@objc\(AppView' "$ROOT/Sources/AppViewServerShared" --glob '*.swift')
BASE_H=$(find "$ROOT/Sources/AppViewServerBase" -name '*.h' 2>/dev/null | wc -l | tr -d ' ')
SOURCES_OBJC=$(count_rg '@objc\(' "$ROOT/Sources" --glob '*.swift')
SOURCES_OBJCMEMBERS=$(count_rg '@objcMembers' "$ROOT/Sources" --glob '*.swift')
MAC_CLIENT_OBJC=$(count_rg '@objc\(' "$REPO/AppView/AppViewClient" --glob '*.swift')

# G6: @objc( outside AppKit UI dirs and ShortCocoa/Connection wrappers
APPVIEWCLIENT_NON_UI=$(rg -c '@objc\(' "$REPO/AppView/AppViewClient" --glob '*.swift' 2>/dev/null | awk -F: '
{
  f = $1; c = $2
  if (f ~ /\/Base\// || f ~ /\/Dashboard\// || f ~ /\/Static\// || f ~ /\/Connection\//) next
  s += c
}
END { print s+0 }' || true)

LOG_DIR="$REPO/appview-verify-logs"
mkdir -p "$LOG_DIR"
STAMP="$(date +%Y%m%d-%H%M%S)"
INVENTORY="$LOG_DIR/objc-inventory-${STAMP}.txt"

{
  echo "RESULT: swift_objc_inventory"
  echo "  AppViewServerShared @objc(AppView*: $SHARED_APPVIEW (baseline <= $SHARED_APPVIEW_OBJC_ATOBJC)"
  echo "  AppViewServerBase *.h count:      $BASE_H (baseline <= $APPVIEWBASE_H_COUNT)"
  echo "  AppViewClient non-UI @objc(:       $APPVIEWCLIENT_NON_UI (baseline <= $APPVIEWCLIENT_NON_UI_OBJC_ATOBJC)"
  echo "  Sources @objc( total:            $SOURCES_OBJC"
  echo "  Sources @objcMembers total:      $SOURCES_OBJCMEMBERS"
  echo "  AppViewClient @objc( total:       $MAC_CLIENT_OBJC (G12 baseline <= ${APPVIEWCLIENT_TOTAL_OBJC_ATOBJC:-297})"
  echo ""
  echo "Top 10 files by @objc( in AppViewServerShared:"
  rg -c '@objc\(' "$ROOT/Sources/AppViewServerShared" --glob '*.swift' 2>/dev/null \
    | sort -t: -k2 -nr | head -10 || true
} | tee "$INVENTORY"

STATUS=0
if [[ "$SHARED_APPVIEW" -gt "$SHARED_APPVIEW_OBJC_ATOBJC" ]]; then
  echo "FAIL G7: AppViewServerShared @objc(AppView* $SHARED_APPVIEW exceeds baseline $SHARED_APPVIEW_OBJC_ATOBJC" >&2
  STATUS=1
fi
if [[ "$BASE_H" -gt "$APPVIEWBASE_H_COUNT" ]]; then
  echo "FAIL: AppViewServerBase *.h count $BASE_H exceeds baseline $APPVIEWBASE_H_COUNT" >&2
  STATUS=1
fi
if [[ "$APPVIEWCLIENT_NON_UI" -gt "$APPVIEWCLIENT_NON_UI_OBJC_ATOBJC" ]]; then
  echo "FAIL G6: AppViewClient non-UI @objc( $APPVIEWCLIENT_NON_UI exceeds baseline $APPVIEWCLIENT_NON_UI_OBJC_ATOBJC" >&2
  STATUS=1
fi
if [[ "$MAC_CLIENT_OBJC" -gt "${APPVIEWCLIENT_TOTAL_OBJC_ATOBJC:-297}" ]]; then
  echo "FAIL G12: AppViewClient total @objc( $MAC_CLIENT_OBJC exceeds baseline ${APPVIEWCLIENT_TOTAL_OBJC_ATOBJC:-297}" >&2
  STATUS=1
fi

# G13: unified SPM/pod — no legacy modular AppViewServer* imports in Sources/
LEGACY_MODULE_IMPORTS=$(rg -c '#if canImport\(AppViewServer' "$ROOT/Sources" --glob '*.swift' 2>/dev/null | awk -F: '{s+=$2} END {print s+0}' || true)
if [[ "$LEGACY_MODULE_IMPORTS" != "0" ]]; then
  echo "FAIL G13: found $LEGACY_MODULE_IMPORTS #if canImport(AppViewServer* in Sources/ (use unified module or #if canImport(AppViewShared))" >&2
  rg '#if canImport\(AppViewServer' "$ROOT/Sources" --glob '*.swift' 2>/dev/null | head -20 >&2 || true
  STATUS=1
fi

if [[ "$STATUS" -eq 0 ]]; then
  echo "count_swift_objc: PASS (inventory: $INVENTORY)"
fi
exit "$STATUS"
