#if SHOULD_COMPILE_APPVIEW_SERVER
import Foundation
import Network
#if canImport(AppViewShared)
import AppViewShared
#endif

@objc(AVS_MCPHTTPServer)
@objcMembers
public final class MCPHTTPServer: NSObject {
    public static let shared = MCPHTTPServer()

    /// ObjC / `NSClassFromString` entry used by `AVS_ConnectionManager`.
    @objc public class func sharedServer() -> MCPHTTPServer { shared }

    /// Touch from `AppViewServerEntry` so MCP is linked and HTTP listen starts with the app.
    @objc public class func startDefaultListener() {
        shared.startWithPort(NSNumber(value: 47190))
    }

    private let queue = DispatchQueue(label: "appview.mcp.http")
    private var listener: NWListener?
    @MainActor private var handler: MCPHTTPHandler?

    /// ObjC entry from `AVS_ConnectionManager` (`performSelector` passes `NSNumber`).
    @objc(startWithPort:)
    public func startWithPort(_ portNumber: NSNumber) {
        startListening(onPort: portNumber.uint16Value)
    }

    @nonobjc
    public func startListening(onPort port: UInt16 = 47190) {
        queue.async {
            guard self.listener == nil else { return }

            do {
                let params = NWParameters.tcp
                params.allowLocalEndpointReuse = true
                params.requiredInterfaceType = .loopback

                guard let nwPort = NWEndpoint.Port(rawValue: port) else { return }
                params.requiredLocalEndpoint = NWEndpoint.hostPort(host: "127.0.0.1", port: nwPort)
                let listener = try NWListener(using: params)
                listener.newConnectionHandler = { [weak self] connection in
                    self?.handle(connection: connection)
                }
                listener.stateUpdateHandler = { state in
                    switch state {
                    case .ready:
                        NSLog("AppviewServer - Swift MCP HTTP Server started on 127.0.0.1:\(port)")
                    case .failed(let error):
                        NSLog("AppviewServer - MCP HTTP listener failed on 127.0.0.1:\(port): \(error.localizedDescription)")
                    default:
                        break
                    }
                }
                listener.start(queue: self.queue)
                self.listener = listener
                NSLog("AppViewServer - Swift MCP HTTP Server started on 127.0.0.1:\(port)")
            } catch {
                NSLog("AppViewServer - Failed to start Swift MCP HTTP server: \(error.localizedDescription)")
            }
        }
    }

    public func stop() {
        queue.async {
            self.listener?.cancel()
            self.listener = nil
        }
    }

    private func handle(connection: NWConnection) {
        connection.start(queue: queue)
        Task { [weak self] in
            guard let self else {
                connection.cancel()
                return
            }
            guard let data = await self.receive(from: connection) else { return }
            guard let request = MCPHTTPRequestParser.parse(data) else {
                await self.send(response: .error(message: "Bad request", statusCode: 400), on: connection)
                return
            }
            let response = await self.handleRequest(request)
            await self.send(response: response, on: connection)
        }
    }

    @MainActor
    private func handleRequest(_ request: MCPHTTPRequest) async -> MCPHTTPResponse {
        if handler == nil {
            handler = MCPHTTPHandler()
        }
        return await handler!.handle(request: request)
    }

    private func receive(from connection: NWConnection) async -> Data? {
        await withCheckedContinuation { continuation in
            connection.receive(minimumIncompleteLength: 1, maximumLength: 1_048_576) { data, _, _, error in
                if let data, error == nil {
                    continuation.resume(returning: data)
                } else {
                    connection.cancel()
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private func send(response: MCPHTTPResponse, on connection: NWConnection) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let payload = response.httpData
            connection.send(content: payload, completion: .contentProcessed { _ in
                connection.cancel()
                continuation.resume()
            })
        }
    }
}
#endif
