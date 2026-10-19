# AppViewCollectionLayoutDemo (Swift baseline)

Эталонное Swift-демо для сравнения иерархии UI: `UICollectionView` с compositional layout, ячейки на Auto Layout / frame / mixed, левая панель на frame layout.

Пары для verify:
- **Baseline (эталон):** `AppViewServer-baseline+mcp` — этот проект, bundle `AppView.AppViewCollectionLayoutDemoBaseline`, display name **CollLayout Baseline**
- **Swift refactor:** `AppViewServer/AppViewDemo/AppViewCollectionLayoutDemo` — bundle `AppView.AppViewCollectionLayoutDemo`, display name **CollLayout Swift**

## CocoaPods

```bash
cd AppViewServer-baseline+mcp/AppViewDemo/AppViewCollectionLayoutDemo
pod install
open AppViewCollectionLayoutDemo.xcworkspace
```

Подключает `AppViewServer` (Swift + MCP) из `AppViewServer/` через CocoaPods path `../../../AppViewServer`.

## Сборка

```bash
xcodebuild -workspace AppViewCollectionLayoutDemo.xcworkspace \
  -scheme AppViewCollectionLayoutDemo \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug build
```

## Accessibility IDs (для MCP / verify)

| ID | Описание |
|----|----------|
| `collectionLayoutRoot` | корневой view |
| `leftRailFrameLayout` | левая панель (frame) |
| `mainCollectionView` | collection view |
| `cell_constraint_N` | Auto Layout ячейки |
| `cell_frame_N` | frame ячейки |
| `cell_mixed_N` | mixed ячейки |
| `section_header_N` | заголовки секций |
