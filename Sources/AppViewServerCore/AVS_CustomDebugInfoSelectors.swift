#if canImport(AppViewShared)
import AppViewShared
#endif
#if SHOULD_COMPILE_APPVIEW_SERVER

import Foundation

/// Host-app hooks `appview_customDebugInfos` / `appview_customDebugInfos_0` … `_5` (see demo README).
enum AVS_CustomDebugInfoSelectors {
    static let selectorNames: [String] = ["appview_customDebugInfos"]
        + (0..<5).map { "appview_customDebugInfos_\($0)" }
}

#endif
