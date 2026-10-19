# appview-ios-mcp

Node.js MCP-мост для AI-агентов (Cursor, Qwen Code, Claude Code и др.): stdio MCP → HTTP AppViewServer в iOS app (`127.0.0.1:47190`).

Полная инструкция (pod + симулятор + USB): [../docs/CURSOR_MCP_SETUP.md](../docs/CURSOR_MCP_SETUP.md).

## Зачем две части

| Часть | Где | Роль |
|-------|-----|------|
| **AppViewServer** pod `MCP` | iOS app Debug | HTTP API на `:47190` |
| **appview-ios-mcp** (эта папка) | Mac, Node 18+ | MCP tools для агента |

Одного pod **недостаточно** — агент не говорит с `:47190` напрямую.

## Установка

### 1. Pod в iOS-проекте

```ruby
pod 'AppViewServer', :subspecs => ['Swift', 'MCP'], :configurations => ['Debug']
```

### 2. Зависимости моста

```bash
cd appview-ios-mcp
npm install
```

### 3. Запуск iOS app

Соберите и запустите приложение в **Debug** на симуляторе (foreground).

```bash
curl -sf http://127.0.0.1:47190/status
```

### 4. Подключение агента

**Cursor** — в `.cursor/mcp.json` (корень monorepo `AppView/` или этот репозиторий):

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

Из monorepo AppView путь: `AppViewServer/appview-ios-mcp/index.mjs`.

**Qwen Code** — `.qwen/settings.json`:

```json
{
  "mcpServers": {
    "appview-ios": {
      "command": "node",
      "args": ["appview-ios-mcp/index.mjs"],
      "timeout": 60000
    }
  }
}
```

Или CLI:

```bash
qwen mcp add appview-ios node appview-ios-mcp/index.mjs -s project
```

Проверка: `/mcp list` → `appview-ios` connected.

## MCP tools (44)

### App context
`appview_get_active_app`, `appview_set_expected_app`, `appview_clear_expected_app`

All view tools accept optional `expectedBundleId` and attach `_appContext.warning` when the foreground app changed since the last call.

### Inspect
`appview_get_hierarchy`, `appview_get_status`, `appview_get_screen`, `appview_get_tap_targets`, `appview_list_text_inputs`, `appview_get_attributes`, `appview_get_all_properties`, `appview_get_screenshot`, `appview_compare_screenshots`, `appview_get_custom_info`, `appview_get_hierarchy_details`, `appview_get_selectors`, `appview_find_view`, `appview_get_view_at_point`, `appview_wait_for_view`, `appview_get_orientation`, `appview_get_appearance`, `appview_get_logs`

`appview_get_hierarchy` принимает `includeSystemViews` (по умолчанию всё дерево). `false` убирает контейнеры с именем на `_` и `UITransitionView`, `UIDropShadowView`, `UILayoutContainerView`, `UINavigationTransitionView`, `UIViewControllerWrapperView`, поднимая их детей. `appview_get_screen` с `outline: true` добавляет дерево без frame и без пустых `children`. Узел дерева получает `layoutIssueCount`, когда он больше нуля (кэш ambiguous-скана плюс записанные конфликты); скан ambiguous запускает только mac-клиент при подключении и Reload, MCP его не вызывает. `appview_get_attributes` в группе Auto Layout отдаёт `al_l` (ошибки `kind`/`title`/`constraintIds`) и `al_c_c` (констрейнты с `id`, который совпадает с `constraintIds`).

### Gestures / input
`appview_tap`, `appview_tap_by_label`, `appview_double_tap`, `appview_long_press`, `appview_swipe`, `appview_drag`, `appview_pinch`, `appview_scroll`, `appview_toggle`, `appview_select_row`, `appview_type_text`, `appview_clear_text`, `appview_keyboard`, `appview_shake`

### Runtime / dev
`appview_modify_attribute`, `appview_modify_custom_attr`, `appview_invoke_method`, `appview_set_orientation`, `appview_set_appearance`, `appview_wire_selftest`, `appview_relisten_peertalk`

### Device
`appview_list_devices`, `appview_connect_device`

## Файлы

| Файл | Назначение |
|------|------------|
| `index.mjs` | MCP server bootstrap |
| `register-tools.mjs` | MCP tool definitions |
| `client.mjs` | HTTP → `:47190` |
| `device-manager.mjs` | USB iproxy / simulator |
| `usbmuxd.mjs` | usbmuxd на Mac |

## Troubleshooting

- **Нет связи** — app не в Debug / не запущен; `curl http://127.0.0.1:47190/status`
- **Порт занят** — `lsof -ti tcp:47190`
- **Несколько устройств** — сначала `appview_connect_device`
