# AppViewServerOthers

Reserved for a future Swift module for `AVS_Helper`, `AVS_MultiplatformAdapter`, and `AVS_CustomAttrSetterManager`.

Phase 6 kept these in **AppViewServerCore** (ObjC) because their headers live under `Src/Main/Server/Others/` inside the Core clang module; a separate Swift pod caused duplicate `@objc` type definitions until headers are moved out of Core.

See `Sources/README.md` for the full migration matrix.
