# Sources/ — Swift source folders (AppViewServer + AppViewShared)

All runtime code lives under `Sources/**`, including ivar trace and the ObjC exception bridge.

**CocoaPods:** iOS apps integrate a single pod — [`AppViewServer.podspec`](../AppViewServer.podspec) (`APPVIEW_UNIFIED_MODULE=1`). Folders below are source layout, not separate pods. The AppView mac client uses [`AppViewShared.podspec`](../AppViewShared.podspec).

**Swift Package Manager:** same layout — products `AppViewServer` (full iOS/tvOS server) and `AppViewShared` (wire/models subset for the mac client). SPM splits shared vs server-only sources because a `.swift` file can belong to only one target; server code uses `#if canImport(AppViewShared) import AppViewShared #endif` for CocoaPods parity. ObjC exception catch (`.m`) is target `AppViewServerObjCBridge`.

| Folder | Role |
|--------|------|
| `AppViewServerBase/` | `AppViewIvarTrace` (`.h` + `.swift`) |
| `AppViewServerOthers/AppViewObjCExceptionCatch.m` | единственный ObjC: `@try/@catch` для `NSException` |
| `AppViewServerShared/AppViewObjCExceptionBridge.swift` | Swift API (`tryExecute` / `catchException`) |
| `AppViewServerShared/` | Wire v2 (`Wire/`), `.appview` codec (`AVWireCodec`), models, Peertalk helpers |
| `AppViewServerCategories/` | UIKit/Foundation categories (Swift) |
| `AppViewServerCore/` | Hierarchy makers, blueprint, invocation (Swift) |
| `AppViewServerConnection/` | Peertalk connection + request handlers |
| `AppViewServerPeertalk/` | Peertalk transport (Swift) |
| `AppViewServerMCP/` | MCP HTTP `127.0.0.1:47190` |
| `AppViewServerOthers/` | Config, trace, export, helpers |
| `AppViewServerConnectionBootstrap/` | Server auto-start (Swift) |

Pod source lists for bridge + base: [`Scripts/appview_src_manifest.rb`](../Scripts/appview_src_manifest.rb).

## Wire protocol (production)

| Format | Role |
|--------|------|
| **Wire v2** | JSON `WireRequestEnvelope` / `WireResponseEnvelope` (`AVJS`) + PNG screenshot frames (`AVPG`) on Peertalk |
| **`.appview` files** | `AVJ2` magic + JSON (`WireAppViewFileCodec`) |

NSSecureCoding / wire v1 is **not** supported in Swift AppView or Swift AppViewServer. For historical ObjC wire behavior, compare against `AppView-baseline+mcp` manually.

See [MacAppViewClientCompatibility.md](AppViewServerShared/MacAppViewClientCompatibility.md).

## ObjC exception catch

| File | Purpose |
|------|---------|
| `AppViewServerOthers/AppViewObjCExceptionCatch.m` | `AppViewCatchObjCException` (`@try/@catch`) |
| `AppViewServerShared/AppViewObjCExceptionBridge.swift` | Swift wrapper; `AppViewObjectGetIvarSELName` in `.m` for gesture KVC |

ObjC cannot be removed entirely (Swift does not catch `NSException`). Validate:

```bash
bash AppViewServer/Scripts/verify_src_manifest.sh
```

## CI inventory

```bash
bash AppViewServer/Scripts/count_objc_legacy.sh
```

## Verify

| Symptom | Script |
|---------|--------|
| Custom info | `bash AppView/Scripts/verify_custom_info_client.sh` |
| Inspector tree | `bash AppView/Scripts/verify_ui_hierarchy_mcp.sh` (default: Swift + golden) |
| Tap | `bash AppView/Scripts/verify_ui_tap_mcp.sh` (default: Swift + golden) |
| Wire v2 | `bash AppView/Scripts/verify_wire_v2_ping.sh` |
| ObjC parity (manual/nightly) | `SKIP_OBJC_BASELINE=0` on hierarchy/tap/custom_info scripts |

Deprecated (wire v1, archived): `bash AppViewServer/Scripts/archive/verify_qmui_wire_baseline.sh` — baseline-only, not CI. Use `verify_wire_v2_ping.sh`.
