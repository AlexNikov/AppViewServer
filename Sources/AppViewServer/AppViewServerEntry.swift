#if canImport(AppViewShared)
import AppViewShared
#endif
import Foundation
#if os(iOS) || os(tvOS) || os(visionOS)
/// Triggers `AVS_ConnectionManager` bootstrap when the AppViewServer product module loads.
private let _appviewServerProductBootstrap: Void = {
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
}()
#endif

/// Optional explicit entry. Linking the pod already starts Peertalk and MCP via `+load`.
public enum AppViewServerEntry {
    /// Starts MCP HTTP when the MCP subspec is linked. The connection manager calls this path on launch.
    public static func bootstrapMCPIfAvailable() {
        let classNames = ["AVS_MCPHTTPServer", "AppViewServer.MCPHTTPServer"]
        for name in classNames {
            guard let mcpClass = NSClassFromString(name) as AnyObject? else { continue }
            let sel = NSSelectorFromString("startDefaultListener")
            if mcpClass.responds(to: sel) {
                _ = mcpClass.perform(sel)
                return
            }
            let sharedSel = NSSelectorFromString("sharedServer")
            if mcpClass.responds(to: sharedSel),
               let server = mcpClass.perform(sharedSel)?.takeUnretainedValue() as AnyObject?,
               server.responds(to: NSSelectorFromString("startWithPort:")) {
                _ = server.perform(NSSelectorFromString("startWithPort:"), with: NSNumber(value: 47190))
                return
            }
        }
    }
}
