# AppViewMCPSample

Minimal UIKit app for AppViewServer MCP smoke tests (label, text field, button, colored view).

## SPM (local package)

Use `AppViewMCPSample.xcodeproj` **without** CocoaPods:

```bash
cp AppViewMCPSample.xcodeproj/project.spm.pbxproj AppViewMCPSample.xcodeproj/project.pbxproj
xcodebuild -project AppViewMCPSample.xcodeproj -scheme AppViewMCPSample \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build
```

## CocoaPods

Restore the Pods project file, then use the workspace:

```bash
cp AppViewMCPSample.xcodeproj/project.pods.pbxproj AppViewMCPSample.xcodeproj/project.pbxproj
pod install
open AppViewMCPSample.xcworkspace
```

## Cursor / Qwen Code MCP

Full setup: [docs/CURSOR_MCP_SETUP.md](../../docs/CURSOR_MCP_SETUP.md).

**AppView monorepo** — from repo root:

```bash
cd appview-ios-mcp && npm install
```

- **Cursor:** enable `appview-ios` in Settings → MCP (`AppViewServer/.cursor/mcp.json` или monorepo `.cursor/mcp.json`)
- **Qwen Code:** `AppViewServer/.qwen/settings.json` or `qwen mcp add appview-ios node appview-ios-mcp/index.mjs -s project`

Run the app in Debug on simulator, then use tools:

- `appview_get_hierarchy`
- `appview_get_attributes`
- `appview_get_screenshot`
- `appview_tap`
- `appview_swipe`
- `appview_type_text`
- `appview_keyboard`
- `appview_long_press`

Smoke without Cursor:

```bash
curl -sf http://127.0.0.1:47190/status
```
