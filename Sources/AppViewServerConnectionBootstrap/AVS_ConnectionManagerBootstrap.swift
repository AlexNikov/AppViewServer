#if canImport(AppViewShared)
import AppViewShared
#endif
#if SHOULD_COMPILE_APPVIEW_SERVER

import Foundation

/// Called from `AVS_ConnectionLoadHook +load` once the Swift runtime is up.
@_cdecl("appview_server_bootstrap")
public func appview_server_startFromLoad() {
    if Thread.isMainThread {
        MainActor.assumeIsolated {
            _ = AVS_ConnectionManager.bootstrap
        }
    } else {
        DispatchQueue.main.sync {
            MainActor.assumeIsolated {
                _ = AVS_ConnectionManager.bootstrap
            }
        }
    }
}

/// Keeps `appview_server_bootstrap` in the binary: `-ObjC` / the framework class list
/// retain this class, and `start` references the C entry used by `+load`.
@objc(AVS_ConnectionAutoStart)
public final class AVS_ConnectionAutoStart: NSObject {
    @objc public static func start() {
        appview_server_startFromLoad()
    }
}

/// Kept so any earlier touch of this file still reaches the same singleton.
private enum AVS_ConnectionManagerBootstrap {
    static let activated: Void = {
        appview_server_startFromLoad()
        return ()
    }()
}

private let _lksConnectionManagerBootstrapToken: Void = AVS_ConnectionManagerBootstrap.activated

#endif
