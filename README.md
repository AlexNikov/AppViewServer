> **Fork.** [AppViewServer](https://github.com/AlexNikov/AppViewServer) is a fork of [LookinServer](https://github.com/QMUI/LookinServer). The macOS app is [AppView](https://github.com/AlexNikov/AppView), a fork of [Lookin](https://github.com/QMUI/Lookin) by Hugh Li.

# Introduction
You can inspect and modify views in iOS app via AppView, just like UI Inspector in Xcode, or another app called Reveal.

# Integration Guide
To use the [AppView](https://github.com/AlexNikov/AppView) macOS app, you need to integrate AppViewServer (iOS framework of AppView) into your iOS project.

> **Warning**
> 1. Never integrate AppViewServer in Release building configuration.
> 2. Do not use versions earlier than 1.0.6, as it contains a critical bug that could lead to online incidents in your project.

## via CocoaPods:

**One pod** — `AppViewServer` (subspecs `Swift` / `MCP` are optional build flags, not separate pods). Legacy modular podspecs (`AppViewServerCore`, `AppViewServerBase`, …) were removed in 1.2.8; use `AppViewServer` instead.

### Swift Project
`pod 'AppViewServer', :subspecs => ['Swift'], :configurations => ['Debug']`
### Objective-C Project
`pod 'AppViewServer', :configurations => ['Debug']`
## via Swift Package Manager:
`https://github.com/AlexNikov/AppViewServer.git`

Products: **`AppViewServer`** (full debug server, iOS/tvOS) and **`AppViewShared`** (wire/models subset — AppView mac client parity). Folders under `Sources/` are layout only, not separate SPM modules. Local verify: `bash Scripts/verify_spm_unified_build.sh`.

## MCP (Model Context Protocol) — Debug only

HTTP API on `127.0.0.1:47190` inside the iOS app. For AI agents you also need **appview-ios-mcp** (Node) — see [docs/CURSOR_MCP_SETUP.md](docs/CURSOR_MCP_SETUP.md) and [appview-ios-mcp/README.md](appview-ios-mcp/README.md).

### CocoaPods
```ruby
pod 'AppViewServer', :subspecs => ['Swift', 'MCP'], :configurations => ['Debug']
```

### Cursor / Qwen Code

```bash
cd appview-ios-mcp && npm install
```

Enable `appview-ios` in your agent MCP settings. Example Cursor config (paths relative to this repo root):

```json
{
  "mcpServers": {
    "appview-ios": {
      "command": "node",
      "args": ["appview-ios-mcp/index.mjs"]
    }
  }
}
```

Run your app in **Debug** on simulator, then:

```bash
curl http://127.0.0.1:47190/status
curl http://127.0.0.1:47190/hierarchy
```

Sample app: [`AppViewDemo/AppViewMCPSample/`](AppViewDemo/AppViewMCPSample/). See [AppViewMCPSample README](AppViewDemo/AppViewMCPSample/README.md).

### HTTP routes

Full list and curl examples: [Sources/AppViewServerMCP/README.md](Sources/AppViewServerMCP/README.md).

| Method | Path | Description |
|--------|------|-------------|
| GET | `/status` | App name, bundle id, screen metrics |
| GET | `/hierarchy` | View/layer tree |
| GET | `/tap-targets` | Tappable views |
| GET | `/view/:oid/attributes` | Attribute groups |
| POST | `/view/:oid/attributes` | Modify attribute |
| GET | `/view/:oid/screenshot` | PNG base64 |
| POST | `/tap` | Synthetic tap (`oid` or `x`+`y`) |
| POST | `/swipe` | Synthetic swipe (`oid`+`direction` or coordinates) |

Swift runtime lives in `Sources/AppViewServer*` (wire v2 only), including ivar trace (`AppViewServerBase`) and `AppViewObjCExceptionCatch.m` + `AppViewObjCExceptionBridge.swift`; see [`Sources/README.md`](Sources/README.md).

# Repository
- iOS framework: https://github.com/AlexNikov/AppViewServer
- macOS app: https://github.com/AlexNikov/AppView

---
> **Форк.** [AppViewServer](https://github.com/AlexNikov/AppViewServer) — форк [LookinServer](https://github.com/QMUI/LookinServer). macOS-клиент: [AppView](https://github.com/AlexNikov/AppView), форк [Lookin](https://github.com/QMUI/Lookin).

# Введение
AppView позволяет просматривать и изменять UI-объекты в iOS-приложении — как UI Inspector в Xcode или приложение Reveal.

# Установка AppViewServer
Если вы впервые используете AppView в iOS-проекте, сначала подключите AppViewServer (macOS-клиент: [AppView](https://github.com/AlexNikov/AppView)).

> **Warning**
>
> 1. Не подключайте AppViewServer в конфигурации AppStore / Release.
> 2. Не используйте версии ниже 1.0.6 — в них критический баг, который может привести к инцидентам на проде.

## Через CocoaPods:

**Один pod** — `AppViewServer` (subspecs `Swift` / `MCP` — опциональные флаги сборки, не отдельные поды). С 1.2.8 модульные podspec (`AppViewServerCore`, `AppViewServerBase` и т.д.) удалены; используйте `AppViewServer`.

### Swift-проект
`pod 'AppViewServer', :subspecs => ['Swift'], :configurations => ['Debug']`
### Objective-C-проект
`pod 'AppViewServer', :configurations => ['Debug']`

## Через Swift Package Manager:
`https://github.com/AlexNikov/AppViewServer.git`

# Репозитории
- iOS AppViewServer: https://github.com/AlexNikov/AppViewServer
- macOS-приложение: https://github.com/AlexNikov/AppView
