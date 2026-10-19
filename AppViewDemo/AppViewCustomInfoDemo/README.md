# AppViewCustomInfoDemo

## Запуск (обязательно workspace + Pods)

Не открывайте `AppViewCustomInfoDemo.xcodeproj` напрямую — без Pods сборка/запуск ломается.

```bash
cd AppViewServer/AppViewDemo/AppViewCustomInfoDemo
pod install
open AppViewCustomInfoDemo.xcworkspace   # не .xcodeproj
```

Или одной командой:

```bash
bash AppViewServer/AppViewDemo/AppViewCustomInfoDemo/run_demo.sh
```

Bundle id: `AppView.AppViewCustomInfoDemoSwift`

## Если Xcode ругается на Package.swift (SwiftPM)

Корень `AppViewServer/` — это Swift Package для SPM, не iOS-приложение. После правок `Package.swift`:

```bash
cd AppViewServer
rm -rf .build
swift package reset
swift package resolve
```

Демо через CocoaPods **не** требует успешного `swift build` на macOS.
