#!/usr/bin/env bash
# Rebuild AppViewServer pod + open CollLayout demo for USB device testing.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"
echo "==> pod install (AppViewServer from ../../../AppViewServer)"
pod install
echo "==> Open Xcode — select physical iPhone (not Simulator), then Product → Run"
open AppViewCollectionLayoutDemo.xcworkspace
