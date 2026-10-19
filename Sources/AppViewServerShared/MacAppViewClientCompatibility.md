# Совместимость со Swift AppView.app (mac-клиент)

AppView.app и AppViewServer обмениваются данными **только** через wire v2: JSON (`AVJS` / `WireRequestEnvelope`) и бинарные скриншоты (`AVPG`). NSSecureCoding / `NSKeyedArchiver` для Peertalk **не используются**.

## Обязательно сохранять

### 1. Wire v2 маппинг (`WireRequestResponseMapper`, `WireHierarchyMapper`)

Все `AppViewRequestType` (200–214) и push (303–304) должны кодироваться/декодироваться через `Wire*` struct и `AVWireCodecV2`.

### 2. `AppViewConnectionAttachment` / ответы

Внутренний API mac/iOS по-прежнему использует `AppViewConnectionResponseAttachment`; на wire уходит `WireResponseEnvelope`, не keyed archive.

### 3. Ключи и семантика полей wire JSON

Не менять имена полей в `WireCodableModels` без bump версии протокола.

`AppViewAttrType.json` → `WireAttrValue.kind == "json"` + `jsonDocument` (UTF-8). Mac dashboard разбирает через `AppViewJSONAttributeSupport` (дерево `title` / `desc` / `details`).

`AppViewAttrType.customObj` → `WireAttrValue.kind == "custom"` + `customSummary` (или `string` для NSString).

Клиентские запросы: `WireClientRequestPayload` → `WireRequestEnvelope` (без `NSDictionary` в `AVInspectableApp` / `AVAppsManager`).

### 4. `AppViewGeometryCoding` / скриншоты

- iOS отдаёт detail JSON + `AVPG` PNG.
- Mac буферизует скриншоты до появления oid в иерархии (`AVConnectionManager+WireV2`).

### 5. `.appview` на диске

Только `AVJ2` + JSON (`WireAppViewFileCodec`). Legacy v1 не открывается.

### 6. Negotiation

Hierarchy-запрос шлёт `minWireVersion: 2`. Сервер всегда отвечает wire v2.

## Проверка после изменений

```bash
AppView/Scripts/verify_wire_v2_ping.sh
AppView/Scripts/verify_ui_hierarchy_mcp.sh
AppViewServer/Scripts/verify_appview_integration.sh
```

Stock QMUI AppView.app (NSSecureCoding Peertalk) **не поддерживается**.

## Swift-only module (legacy `@objc` cleanup)

- **Wire / files:** только Codable JSON (`Wire*`, `AVJ2`); публичный ObjC API pod **не поддерживается**.
- **Снимаем:** `@objc(AppView*)` на моделях в `AppViewServerShared` и transitional `.h` в `Src/Main` (см. план «уход от @objc и .h»).
- **Оставляем:** `@objcMembers` / `#selector` / `init(coder:)` в mac AppKit UI (`AppViewClient/Base`, `Dashboard`, `Static`); runtime whitelist (`NSClassFromString("AppViewConfig")`, exception bridge `.m`).
- **Gates:** `bash AppView/Scripts/run_legacy_gates.sh` (`count_swift_objc.sh`, baseline `AppViewServer/Scripts/objc_legacy_baseline.env`).

### Ожидаемые остатки `@objc` (после фаз A–F)

Инвентарь: `bash AppViewServer/Scripts/count_swift_objc.sh`. Ноль `@objc` в репозитории **невозможен** без отказа от AppKit/Peertalk.

| Категория | Где (примеры) | Зачем | Снимать? |
|-----------|---------------|-------|----------|
| **G7 модели** | `AppViewServerShared` | `@objc(AppView*)` на wire-моделях | **Нет** (baseline = 0, gate) |
| **Peertalk** | `AppViewServerPeertalk/AppViewPT*.swift` | `@objc(AppView_PTChannel)`, delegate | **Нет** |
| **Runtime probe** | `AVS_ConnectionManager` | `@objc(AppView)` для `NSClassFromString("AppView")` | **Нет** |
| **Runtime handlers** | `AVS_RequestHandler`, `AVS_*Maker`, `AVS_InvocationRuntimeHelper` | `@objc(AVS_*)` + динамические имена классов | **Нет** (Phase E) |
| **Blueprint / constraint** | `AppViewDashboardBlueprint`, `AppViewAutoLayoutConstraint` | Сгенерированные ObjC-селекторы; dashboard `@objc var` | **Нет** (генератор / AppKit) |
| **Shared helpers** | `NSObject+AppView`, `Array+AppView`, `String+AppView` | `@objc` на extension-методах для runtime | Phase E |
| **File codec** | `AVWireCodec` | Swift `enum`, без `@objc` | **Снято** |
| **Mac AppKit UI** | `AppViewClient/Base`, `Dashboard`, `Static` | `@objc(LK*)` + `@objcMembers`, `#selector` | **Нет** |
| **ShortCocoa / Connection** | `ShortCocoa+*.swift`, `AVConnection*.swift` | Layout / Peertalk wrappers | Phase E |

Топ файлов по `@objc(` (типично): Server — `AVS_CustomAttrSetterManager`, `AppViewDashboardBlueprint`, `NSObject+AppView`; Client — `ShortCocoa+Layout`, `AVPreviewView`, `AppViewMsgAttribute`.

## Runtime whitelist (`NSClassFromString` / `perform`)

Намеренно оставляем только:

| Symbol | Где | Зачем |
|--------|-----|-------|
| `AppViewConfig` | `AVS_ConfigManager` | Опциональный конфиг demo/host app |
| `AVS_MCPHTTPServer` / `AppViewServer.MCPHTTPServer` | `AVS_ConnectionManager` | MCP HTTP на iOS (optional subspec) |
| `AppView` | `AVS_ConnectionManager+Detect` | Probe linked AppViewServer |
| Dynamic class names | `AVS_RequestHandler`, `AVS_AttrGroupsMaker`, `AVS_InvocationRuntimeHelper`, `AVS_TraceManager` | Fetch/invoke по имени класса из wire |

Peertalk (`AppView_PTChannel`, delegates) — `@objc` на протоколе/delegate-методах; wire v2 не использует keyed archive.
