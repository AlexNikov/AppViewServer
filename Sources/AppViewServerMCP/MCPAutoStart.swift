#if SHOULD_COMPILE_APPVIEW_SERVER
#if APPVIEW_SERVER_MCP
import Foundation

/// Starts MCP HTTP when the MCP subspec is linked into the app binary.
private let _appviewMCPAutoStart: Void = {
    MCPHTTPServer.shared.startWithPort(NSNumber(value: 47190))
}()
#endif
#endif
