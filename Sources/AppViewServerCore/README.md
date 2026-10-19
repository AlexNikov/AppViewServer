# AppViewServerCoreSwift

Swift inspect makers (`AVS_*Maker`) that depend on ObjC UI categories in `AppViewServerCore`.

SPM: one-way dependency `AppViewServerCoreSwift` → `AppViewServerCore` (no cycle).  
Core headers import `@AppViewServerCoreSwift` when `APPVIEW_CORE_SWIFT_MAKERS` is set.
