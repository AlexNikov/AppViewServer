# AppView iOS MCP: Cursor, Qwen Code и другие агенты

Источник правды для инспекции iOS UI через AppViewServer + **appview-ios-mcp**.

## Архитектура

Один pod **недостаточен** для AI-агента. Нужны **два слоя**:

```
AI agent (Cursor / Qwen Code / …)
    │  MCP (stdio)
    ▼
appview-ios-mcp          ← Node-мост: AppViewServer/appview-ios-mcp/
    │  HTTP REST
    ▼
AppViewServer (pod MCP)  ← внутри iOS app, 127.0.0.1:47190
    │
    ▼
UIKit / CALayer
```

| Слой | Где | Порт | Роль |
|------|-----|------|------|
| **AppViewServer** `subspec MCP` | iOS app (Debug) | `47190` | HTTP API: hierarchy, attributes, screenshot, tap, swipe |
| **appview-ios-mcp** | `AppViewServer/appview-ios-mcp/` | — | MCP tools; USB port-forward через usbmuxd |

HTTP API в **AppView.app** (macOS, `:47191` / `:47192`) — отдельный контур; для iOS — `appview-ios`, для mac inspector verify — `appview-verify` (только Cursor/monorepo).

---

## Установка

### Шаг 1 — Pod в iOS-проекте

```ruby
pod 'AppViewServer', :subspecs => ['Swift', 'MCP'], :configurations => ['Debug']
```

> **Warning:** не подключайте AppViewServer в Release.

Subspec `MCP` входит в `default_subspecs` podspec, но явное указание в Podfile снижает риск случайного отключения.

После изменений podspec в monorepo обновите поды mac-клиента при необходимости:

```bash
cd AppView && pod install
```

### Шаг 2 — Запуск приложения

1. Соберите и запустите demo/app в **Debug** на симуляторе (foreground).
2. Предпочтительные демо: `AppViewDemo/AppViewMCPSample`, `AppViewDemo/AppViewCustomInfoDemo`.

Smoke-тест HTTP:

```bash
curl -sf http://127.0.0.1:47190/status
curl -sf http://127.0.0.1:47190/hierarchy | head -c 200
```

Ожидается JSON с `"success": true`.

### Шаг 3 — Node-мост (Cursor)

```bash
cd appview-ios-mcp && npm install
```

Cursor MCP config (paths relative to this [AppViewServer](https://github.com/AlexNikov/AppViewServer) repo root):

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

If you keep [AppView](https://github.com/AlexNikov/AppView) and AppViewServer as sibling folders, use `args: ["AppViewServer/appview-ios-mcp/index.mjs"]` from the parent directory.

См. также [appview-ios-mcp/README.md](../appview-ios-mcp/README.md).

Перезапустите Cursor → **Settings → MCP** → включите `appview-ios`.

### Шаг 3b — Node-мост (Qwen Code)

Требования: [Qwen Code CLI](https://qwenlm.github.io/qwen-code-docs/) и Node.js 18+.

```bash
cd appview-ios-mcp && npm install
```

**CLI** (из корня AppViewServer):

```bash
qwen mcp add appview-ios node appview-ios-mcp/index.mjs -s project
```

**Вручную** в `~/.qwen/settings.json` или `.qwen/settings.json` (пути относительно корня AppViewServer):

```json
{
  "mcpServers": {
    "appview-ios": {
      "command": "node",
      "args": ["appview-ios-mcp/index.mjs"],
      "description": "AppViewServer iOS — hierarchy, tap, swipe (:47190)",
      "timeout": 60000
    }
  }
}
```

Проверка в сессии Qwen Code:

```
/mcp list
```

Должен появиться `appview-ios` со статусом connected (при запущенном iOS app).

Документация Qwen Code MCP: [MCP servers](https://qwenlm.github.io/qwen-code-docs/en/developers/tools/mcp-server/).

### Шаг 4 — Использование tools

Типичный workflow:

1. `appview_get_screen` — где экран, какие VC, alert и что можно нажать. `outline: true` — компактное дерево без frame
2. `appview_get_hierarchy` / `appview_get_tap_targets` / `appview_find_view` — найти `oid`. У hierarchy `includeSystemViews: false` прячет системные контейнеры
3. `appview_get_attributes` / `appview_get_all_properties` / `appview_get_custom_info` — атрибуты
4. `appview_get_screenshot` / `appview_compare_screenshots` — скриншот и сравнение с предыдущим снимком
5. Жесты: `appview_tap`, `appview_tap_by_label`, `appview_swipe`, `appview_long_press`, `appview_pinch`, `appview_scroll`, `appview_shake`, …
6. Текст: `appview_type_text`, `appview_keyboard`, `appview_clear_text`
7. Runtime: `appview_get_orientation` / `appview_set_orientation`, `appview_get_appearance` / `appview_set_appearance`, `appview_get_logs`

**44 MCP tool** — полный список: [appview-ios-mcp/README.md](../appview-ios-mcp/README.md).

---

## MCP tools ↔ HTTP (основные)

| MCP tool | HTTP |
|----------|------|
| `appview_get_status` | `GET /status` |
| `appview_get_screen` | `GET /screen` (`?outline=1`) |
| `appview_get_tap_targets` | `GET /tap-targets` |
| `appview_get_all_properties` | `GET /view/:oid/properties` |
| `appview_find_view` | `POST /find-view` |
| `appview_modify_attribute` | `POST /view/:oid/attributes` |
| `appview_get_custom_info` | `GET /view/:oid/custom-info` |
| `appview_invoke_method` | `POST /invoke-method` |
| `appview_get_orientation` / `appview_set_orientation` | `GET` / `POST /orientation` |
| `appview_get_appearance` / `appview_set_appearance` | `GET` / `POST /appearance` |
| `appview_shake` | `POST /shake` |
| `appview_get_logs` | `GET /logs` |
| `appview_compare_screenshots` | `POST /screenshot-compare` |
| `appview_list_devices` | — (Mac) |
| `appview_connect_device` | — (Mac iproxy) |

Полная таблица HTTP routes — [Sources/AppViewServerMCP/README.md](../Sources/AppViewServerMCP/README.md).

---

## USB-устройство

На симуляторе мост ходит на `http://127.0.0.1:47190` напрямую.

На физическом устройстве:

1. `appview_list_devices` — список USB + booted simulators
2. `appview_connect_device` с UDID — поднимает iproxy на Mac (`127.0.0.1:47191` → device `:47190`)
3. При нескольких устройствах view-tools (`hierarchy`, `tap`, …) требуют сначала выбрать target через `appview_connect_device`

Приложение с AppViewServer должно быть **в foreground** на устройстве.

---

## Monorepo AppView vs только AppViewServer

| Workspace | Путь в `mcp.json` |
|-----------|-------------------|
| Корень `AppView/` | `AppViewServer/appview-ios-mcp/index.mjs` |
| Корень `AppViewServer/` | `appview-ios-mcp/index.mjs` |

Мост лежит в **[appview-ios-mcp/README.md](../appview-ios-mcp/README.md)** — отдельный README в этой папке.

**Fallback (без tap/swipe):** `npx -y appview-mcp-ios` — upstream npm, устаревший набор tools.

---

## Troubleshooting

| Симптом | Решение |
|---------|---------|
| `Cannot connect to AppViewServer` | App не запущен или не Debug; проверьте `curl http://127.0.0.1:47190/status` |
| Порт `:47190` занят | `lsof -ti tcp:47190` — убейте stale listener; перезапустите app |
| MCP `appview-ios` не стартует (Cursor) | `cd appview-ios-mcp && npm install`; Disable/Enable в Cursor |
| MCP `appview-ios` не в списке (Qwen Code) | Запуск из корня AppViewServer; `/mcp list` |
| `Tool expected a Zod schema` | `cd appview-ios-mcp && npm install` |
| `multiple_devices` | Вызовите `appview_connect_device` перед hierarchy/tap |
| IPv4 vs IPv6 | Предпочитайте `127.0.0.1:47190`; некоторые демо слушают `[::1]` |
| Subspec MCP не в сборке | Podfile: `:subspecs => ['Swift', 'MCP']`, только `Debug` |

Wire verify (из [AppView](https://github.com/AlexNikov/AppView) mac client, если клонирован рядом):

```bash
bash Scripts/verify_wire_v2_ping.sh
```

В этом репозитории: `bash Scripts/verify_wire_v2_roundtrip.sh`.

---

## Связанные файлы

| Файл | Назначение |
|------|------------|
| [Sources/AppViewServerMCP/README.md](../Sources/AppViewServerMCP/README.md) | HTTP routes, curl-примеры |
| [AppViewDemo/AppViewMCPSample/README.md](../AppViewDemo/AppViewMCPSample/README.md) | Smoke demo |
| [appview-ios-mcp/README.md](../appview-ios-mcp/README.md) | MCP-мост: установка и tools |
| [appview-ios-mcp/index.mjs](../appview-ios-mcp/index.mjs) | Точка входа Node MCP |
| [AppView](https://github.com/AlexNikov/AppView) | macOS клиент |
