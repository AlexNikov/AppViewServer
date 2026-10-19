#if canImport(AppViewShared)
import AppViewShared
#endif
#if SHOULD_COMPILE_APPVIEW_SERVER

import Darwin
import Foundation
import UIKit

@MainActor
public final class AVS_ConnectionManager: NSObject {

    @objc public static let sharedInstance = AVS_ConnectionManager()

    /// Replaces ObjC `+load` — triggers singleton initialization when the module loads.
    public static let bootstrap: Void = {
        _ = sharedInstance
        return ()
    }()

    @objc public var applicationIsActive = false

    private var peerChannel: PTChannel?
    private var peerChannelUniqueID: Int32?
    private var listenChannel: PTChannel?
    private var peertalkListenPortCache = 0
    private var peertalkIsConnectedCache = false
    private var listeningTask: Task<Void, Never>?
    private var frameLoopTask: Task<Void, Never>?
    private var watchdogTask: Task<Void, Never>?
    private var portSearchInProgress = false
    let requestHandler = AVS_RequestHandler()
    private var lastPeerFrameAt: TimeInterval = 0
    private var peerConnectedAt: TimeInterval = 0

    private override init() {
        super.init()
        NSLog("AppViewServer - Will launch. Framework version: %@", appviewServerReadableVersion)

        AVS_LayoutConflictRecorder.shared.installIfAvailable()
        syncApplicationActiveStateFromUIKit()
        startLifecycleObservers()
        startMCPHTTPServerIfAvailable(port: 47190)
        startWatchdog()
        // Module may load after didFinishLaunching / scene activation — do not wait for a replayed notification.
        Task { await searchPortToListenIfNoConnection() }
        // Scene activation often lands after AppDelegate bootstrap — re-sync a few times.
        Task { @MainActor [weak self] in
            for delayNs in [300_000_000, 1_000_000_000, 2_000_000_000] as [UInt64] {
                try? await Task.sleep(nanoseconds: delayNs)
                guard let self else { return }
                self.syncApplicationActiveStateFromUIKit()
                if self.applicationIsActive {
                    await self.searchPortToListenIfNoConnection()
                }
            }
        }
    }

    /// Scene apps often bootstrap AppViewServer after UIKit already posted didBecomeActive.
    private func syncApplicationActiveStateFromUIKit() {
        let appState = UIApplication.shared.applicationState
        // During launch, state is often `.inactive` while the scene is already foreground — treat
        // anything except `.background` as active for Peertalk watchdog thresholds.
        if appState != .background {
            applicationIsActive = true
        }
        if #available(iOS 13.0, *) {
            let sceneForeground = UIApplication.shared.connectedScenes.contains {
                $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive
            }
            if sceneForeground {
                applicationIsActive = true
            }
            let onlyBackgroundScenes = !UIApplication.shared.connectedScenes.isEmpty
                && UIApplication.shared.connectedScenes.allSatisfy { $0.activationState == .background }
            if onlyBackgroundScenes, appState == .background {
                applicationIsActive = false
            }
        } else if appState == .background {
            applicationIsActive = false
        }
        AppViewDiagLog.log("iOS sync active=\(applicationIsActive) appState=\(appState.rawValue)")
    }

    /// Request-time re-sync: apps activated before the bootstrap observer subscribed
    /// (e.g. Xcode launch) never receive didBecomeActive — refresh on demand.
    @objc public func refreshApplicationActiveStateFromUIKit() -> Bool {
        syncApplicationActiveStateFromUIKit()
        return applicationIsActive
    }

    deinit {
        listeningTask?.cancel()
        frameLoopTask?.cancel()
        watchdogTask?.cancel()
    }

    // MARK: - Lifecycle

    private func startLifecycleObservers() {
        // Selector observers (not AsyncSequence): scene activation often fires before a
        // for-await subscription exists when AppViewServer bootstraps from AppDelegate.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(_handleApplicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(_handleApplicationDidFinishLaunching),
            name: UIApplication.didFinishLaunchingNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(_handleWillResignActiveNotification),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        if #available(iOS 13.0, *) {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(_handleSceneDidActivate),
                name: UIScene.didActivateNotification,
                object: nil
            )
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(_handleLocalInspect(_:)),
            name: .appview2D,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(_handleLocalInspect(_:)),
            name: .appview3D,
            object: nil
        )
        NotificationCenter.default.addObserver(
            forName: .appviewExport,
            object: nil,
            queue: .main
        ) { _ in
            AVS_ExportManager.sharedInstance().exportAndShare()
        }
        NotificationCenter.default.addObserver(
            forName: .appviewRelationSearch,
            object: nil,
            queue: .main
        ) { note in
            AVS_TraceManager.sharedInstance().addSearchTarger(note.object)
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleGetAppViewInfo(_:)),
            name: .getAppViewInfo,
            object: nil
        )
    }

    private func startWatchdog() {
        watchdogTask?.cancel()
        watchdogTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                self?.checkPeertalkZombiePeer()
            }
        }
    }

    // MARK: - Public API

    public func respond(_ data: AVConnectionResponseAttachment, requestType: UInt32, tag: UInt32) {
        respondWireV2(data, requestType: requestType, tag: tag)
    }

    @objc(pushData:type:)
    public func pushData(_ data: NSObject, type: UInt32) {
        guard AppViewWirePushTypes.all.contains(type) else {
            NSLog("AppViewServer - unsupported push type:%u", type)
            return
        }
        do {
            let jsonData = try AVWireCodecV2.encodeJSON(WirePushEnvelope(pushType: type))
            sendRawPayload(jsonData, frameOfType: type, tag: 0)
        } catch {
            NSLog("AppViewServer - wire v2 push JSON encode failed type:%u: %@", type, error as NSError)
        }
    }

    @objc public func mcpPeertalkListenPort() -> Int {
        peertalkListenPortCache
    }

    @objc public func mcpPeertalkIsConnected() -> Bool {
        peertalkIsConnectedCache
    }

    private func updatePeertalkCache(using channel: PTChannel?) async {
        guard let channel else {
            peertalkListenPortCache = 0
            peertalkIsConnectedCache = false
            return
        }
        let listening = await channel.isListening
        peertalkListenPortCache = listening ? await channel.targetPort : 0
        peertalkIsConnectedCache = await channel.isConnected
    }

    @objc public func nudgePeertalkListenForLaunchScreenDiscoveryIfNeeded() {
        AVServerConnectionTiming.recordInstant("server.relisten", durationMs: 0, attrs: ["source": "nudge"])
        Task { await searchPortToListenIfNoConnection() }
    }

    @objc public func searchPortToListenIfNoConnection() {
        Task { await searchPortToListenIfNoConnection() }
    }

    @objc public func prepareForNewMacClientConnection() {
        recycleStaleConnectedPeerIfNeeded(minIdle: 0)
        Task { await searchPortToListenIfNoConnection() }
    }

    // MARK: - Peertalk orchestration

    private func searchPortToListenIfNoConnection() async {
        if portSearchInProgress { return }
        if let listen = listenChannel, await listen.isListening {
            return
        }
        portSearchInProgress = true
        defer { portSearchInProgress = false }

        await clearDeadPeersIfNeeded()
        await recycleStaleListenPeerIfNeeded()
        await recycleStaleConnectedPeerIfNeededAsync(minIdle: 0.25)

        if let peer = peerChannel, await peer.isConnected, await peer.hasActiveTransport {
            let idle = Date().timeIntervalSince1970 - lastPeerFrameAt
            if lastPeerFrameAt > 0, idle < 0.25 {
                NSLog("AppViewServer - Abort to search ports. Already has connected channel.")
                return
            }
        }

        NSLog("AppViewServer - Searching port to listen...")
        frameLoopTask?.cancel()
        frameLoopTask = nil
        listeningTask?.cancel()
        listeningTask = nil
        if let listen = listenChannel {
            await listen.close()
            listenChannel = nil
        }
        if let peer = peerChannel {
            await peer.close()
            peerChannel = nil
            peerChannelUniqueID = nil
        }
        lastPeerFrameAt = 0
        peerConnectedAt = 0

        if isiOSAppOnMac() {
            await searchPortToListen(from: Int32(AppViewSimulatorIPv4PortNumberStart), to: Int32(AppViewSimulatorIPv4PortNumberEnd))
        } else {
            await searchPortToListen(from: Int32(AppViewUSBDeviceIPv4PortNumberStart), to: Int32(AppViewUSBDeviceIPv4PortNumberEnd))
        }
    }

    private func searchPortToListen(from: Int32, to: Int32) async {
        var current = from
        while current <= to {
            let channel = PTChannel()
            do {
                try await channel.listen(onPort: UInt16(current))
                NSLog("AppViewServer - Connected successfully on 127.0.0.1:%d", current)
                AppViewDiagLog.log("Peertalk listen OK port=\(current)")
                AVServerConnectionTiming.recordInstant(
                    "server.listen.port",
                    durationMs: 0,
                    attrs: ["port": Int(current)]
                )
                listenChannel = channel
                peerChannel = channel
                peerChannelUniqueID = await channel.uniqueID
                await updatePeertalkCache(using: channel)
                listeningTask = Task { @MainActor [weak self] in
                    await self?.runAcceptLoop(on: channel)
                }
                return
            } catch {
                await channel.close()
                if current < to {
                    NSLog("AppViewServer - 127.0.0.1:%d is unavailable(%@). Will try anothor address ...", current, error as NSError)
                    AppViewDiagLog.log("Peertalk listen skip port=\(current) errno=\((error as NSError).code)")
                    current += 1
                } else {
                    NSLog("AppViewServer - 127.0.0.1:%d is unavailable(%@).", current, error as NSError)
                    NSLog(
                        "AppViewServer - Peertalk listen FAILED on all ports %d-%d (errno in log above). Rebuild iOS app after pod install.",
                        from,
                        to
                    )
                    return
                }
            }
        }
    }

    private func runAcceptLoop(on listenChannel: PTChannel) async {
        for await peer in await listenChannel.acceptedChannels() {
            let previous = peerChannel
            peerChannel = peer
            peerConnectedAt = Date().timeIntervalSince1970
            peerChannelUniqueID = await peer.uniqueID
            await updatePeertalkCache(using: peer)
            lastPeerFrameAt = Date().timeIntervalSince1970
            if let previous {
                let previousID = await previous.uniqueID
                let listenID = await listenChannel.uniqueID
                if previousID != listenID {
                    await previous.cancel()
                }
            }
            frameLoopTask?.cancel()
            frameLoopTask = Task { @MainActor [weak self] in
                await self?.runFrameLoop(on: peer)
            }
            pushData(NSObject(), type: AppViewWirePushTypes.serverReady)
        }
        await searchPortToListenIfNoConnection()
    }

    private func runFrameLoop(on channel: PTChannel) async {
        let channelID = await channel.uniqueID
        do {
            for try await frame in await channel.frames() {
                guard peerChannelUniqueID == channelID else { break }
                lastPeerFrameAt = Date().timeIntervalSince1970
                await handleFrame(frame)
            }
        } catch {
            await handleChannelEnd(channelID: channelID, error: error as NSError)
        }
    }

    private func handleFrame(_ frame: PTFrame) async {
        guard !frame.payload.isEmpty else {
            NSLog("AppViewServer - didReceive frame type:%u tag:%u empty payload", frame.type, frame.tag)
            return
        }
        if frame.type != AppViewWireFormat.frameTypeJSON,
           frame.type != AppViewWireFormat.frameTypeScreenshot,
           !(await requestHandler.canHandleRequestType(frame.type)) {
            NSLog("AppViewServer - reject unknown frame type:%u tag:%u", frame.type, frame.tag)
            await peerChannel?.close()
            return
        }
        let data = frame.payload
        if frame.type == AppViewWireFormat.frameTypeJSON {
            await handleWireJSONCommand(data, tag: frame.tag)
            return
        }
        do {
            let envelope = try AVWireCodecV2.decodeJSON(WireRequestEnvelope.self, from: data)
            await handleWireJSONRequest(envelope, tag: frame.tag)
            return
        } catch {
            if data.first == UInt8(ascii: "{") {
                NSLog(
                    "AppViewServer - wire request JSON decode failed type:%u tag:%u bytes:%zu error:%@ preview:%@",
                    frame.type,
                    frame.tag,
                    data.count,
                    error as NSError,
                    String(data: data.prefix(120), encoding: .utf8) ?? ""
                )
            }
        }
        if AppViewWirePushTypes.all.contains(frame.type),
           let push = try? AVWireCodecV2.decodeJSON(WirePushEnvelope.self, from: data) {
            guard AppViewWireFormat.validateWireVersion(push.wireVersion, context: "push") else {
                return
            }
            await requestHandler.handleRequestType(push.pushType, tag: frame.tag, object: nil)
            return
        }
        NSLog(
            "AppViewServer - expected JSON request/push, got type:%u tag:%u payload:%zu",
            frame.type,
            frame.tag,
            data.count
        )
    }

    private func handleChannelEnd(channelID: Int32, error: NSError?) async {
        guard peerChannelUniqueID == channelID else {
            if peerChannel == nil {
                await searchPortToListenIfNoConnection()
            }
            return
        }
        NSLog("AppViewServer - channel DidEndWithError:%@", String(describing: error))
        NotificationCenter.default.post(
            name: NSNotification.Name(rawValue: AVS_ConnectionDidEndNotificationName as String),
            object: self
        )
        peerChannel = nil
        peerChannelUniqueID = nil
        peertalkListenPortCache = 0
        peertalkIsConnectedCache = false
        lastPeerFrameAt = 0
        peerConnectedAt = 0
        await searchPortToListenIfNoConnection()
        try? await Task.sleep(nanoseconds: 300_000_000)
        await searchPortToListenIfNoConnection()
    }

    func sendRawPayload(_ data: Data, frameOfType: UInt32, tag: UInt32) {
        guard let peerChannel else { return }
        Task {
            do {
                try await peerChannel.send(type: frameOfType, tag: tag, payload: data)
            } catch {
                NSLog(
                    "AppViewServer - wire v2 sendFrame failed type:%u tag:%u error:%@",
                    frameOfType,
                    tag,
                    error as NSError
                )
            }
        }
    }

    // MARK: - Peer maintenance

    private func clearDeadPeersIfNeeded() async {
        if let peer = peerChannel, !(await peer.isListening), !(await peer.isConnected) {
            AppViewDiagLog.log("iOS clear dead Peertalk peer — re-listen")
            await peer.close()
            peerChannel = nil
            peerChannelUniqueID = nil
            lastPeerFrameAt = 0
            peerConnectedAt = 0
        }
        if !isiOSAppOnMac(),
           let peer = peerChannel,
           await peer.isConnected,
           !(await peer.isListening),
           !(await peer.hasActiveTransport) {
            await prepareForNewMacClientConnectionAsync()
        }
    }

    private func recycleStaleListenPeerIfNeeded() async {
        guard let peer = peerChannel, await peer.isListening else { return }
        if await peer.hasActiveTransport { return }
        AppViewDiagLog.log("iOS stale listen peer (no transport) — recycle for re-listen")
        await peer.close()
        peerChannel = nil
        peerChannelUniqueID = nil
        peerConnectedAt = 0
    }

    private func recycleStaleConnectedPeerIfNeededAsync(minIdle: TimeInterval) async {
        guard let peer = peerChannel, !(await peer.isListening), await peer.isConnected else { return }
        if await peer.hasActiveTransport {
            let idle = Date().timeIntervalSince1970 - lastPeerFrameAt
            if lastPeerFrameAt > 0, idle >= minIdle {
                AppViewDiagLog.log("iOS recycle stale peer idle=\(String(format: "%.2f", idle))s — re-listen")
                await peer.cancel()
                peerChannel = nil
                peerChannelUniqueID = nil
                lastPeerFrameAt = 0
                peerConnectedAt = 0
            }
            return
        }
        AppViewDiagLog.log("iOS stale peer (connected, no transport) — closing for re-listen")
        await peer.close()
        peerChannel = nil
        peerChannelUniqueID = nil
        peerConnectedAt = 0
    }

    private func recycleStaleConnectedPeerIfNeeded(minIdle: TimeInterval = 0.8) {
        Task { await recycleStaleConnectedPeerIfNeededAsync(minIdle: minIdle) }
    }

    private func prepareForNewMacClientConnectionAsync() async {
        await recycleStaleConnectedPeerIfNeededAsync(minIdle: 0)
        await searchPortToListenIfNoConnection()
    }

    private func checkPeertalkZombiePeer() {
        Task { await checkPeertalkZombiePeerAsync() }
    }

    private func checkPeertalkZombiePeerAsync() async {
        syncApplicationActiveStateFromUIKit()
        if let peer = peerChannel, await peer.isListening {
            if !(await peer.hasActiveTransport) {
                AppViewDiagLog.log("iOS watchdog stale listen (no transport) — recycle")
                await peer.close()
                peerChannel = nil
                peerChannelUniqueID = nil
                peerConnectedAt = 0
                await searchPortToListenIfNoConnection()
            }
            return
        }

        guard let peer = peerChannel else {
            if applicationIsActive || !isiOSAppOnMac() {
                await searchPortToListenIfNoConnection()
            }
            return
        }

        if !(await peer.isListening), !(await peer.isConnected) {
            AppViewDiagLog.log("iOS watchdog dead peer — clear and re-listen")
            await peer.close()
            peerChannel = nil
            peerChannelUniqueID = nil
            lastPeerFrameAt = 0
            peerConnectedAt = 0
            await searchPortToListenIfNoConnection()
            return
        }

        if await peer.isConnected {
            if !(await peer.isListening), !(await peer.hasActiveTransport) {
                AppViewDiagLog.log("iOS watchdog connected zombie w/o transport — re-listen")
                await prepareForNewMacClientConnectionAsync()
                return
            }
            if !(await peer.hasActiveTransport) {
                AppViewDiagLog.log("iOS watchdog connected peer w/o transport — re-listen")
                await prepareForNewMacClientConnectionAsync()
                return
            }
            let connected = Date().timeIntervalSince1970 - peerConnectedAt
            let idle = Date().timeIntervalSince1970 - lastPeerFrameAt
            let idleThreshold: TimeInterval = isiOSAppOnMac()
                ? (applicationIsActive ? 5.0 : 0.8)
                : (applicationIsActive ? 30.0 : 0.8)
            if lastPeerFrameAt <= 0 || idle >= idleThreshold {
                AppViewDiagLog.log(
                    "iOS watchdog stale connected idle=\(String(format: "%.1f", idle))s active=\(applicationIsActive) — re-listen"
                )
                await prepareForNewMacClientConnectionAsync()
            }
        }
    }

    private func handleWillResignActive() {
        Task { await handleWillResignActiveAsync() }
    }

    private func handleWillResignActiveAsync() async {
        if let channel = peerChannel {
            if await channel.isListening { return }
            if !(await channel.isConnected) {
                await channel.close()
                peerChannel = nil
                peerChannelUniqueID = nil
                peerConnectedAt = 0
            }
        }
        ensurePeertalkListenAfterResigningActive()
    }

    private func ensurePeertalkListenAfterResigningActive() {
        #if targetEnvironment(simulator)
        return
        #else
        guard !isiOSAppOnMac() else { return }
        Task { await searchPortToListenIfNoConnection() }
        #endif
    }

    @objc private func _handleApplicationDidFinishLaunching() {
        AppViewDiagLog.log("iOS didFinishLaunching — schedule Peertalk listen")
        Task { await searchPortToListenIfNoConnection() }
    }

    @objc private func _handleApplicationDidBecomeActive() {
        applicationIsActive = true
        AppViewDiagLog.log("iOS didBecomeActive — ensure Peertalk listen")
        recycleStaleConnectedPeerIfNeeded(minIdle: 0.25)
        Task { await searchPortToListenIfNoConnection() }
    }

    @objc private func _handleWillResignActiveNotification() {
        applicationIsActive = false
        handleWillResignActive()
    }

    @objc private func _handleSceneDidActivate(_ note: Notification) {
        applicationIsActive = true
        AppViewDiagLog.log("iOS scene didActivate — ensure Peertalk listen")
        recycleStaleConnectedPeerIfNeeded(minIdle: 0.25)
        Task { await searchPortToListenIfNoConnection() }
    }

    private func startMCPHTTPServerIfAvailable(port: UInt16) {
        let classNames = ["AVS_MCPHTTPServer", "AppViewServer.MCPHTTPServer"]
        let sharedSelectors = ["sharedServer", "shared", "sharedInstance"]
        let startSel = NSSelectorFromString("startWithPort:")
        for className in classNames {
            guard let mcpClass = NSClassFromString(className) as AnyObject? else { continue }
            var server: AnyObject?
            for selName in sharedSelectors {
                let sharedSel = NSSelectorFromString(selName)
                if mcpClass.responds(to: sharedSel) {
                    server = mcpClass.perform(sharedSel)?.takeUnretainedValue() as AnyObject?
                    if server != nil { break }
                }
            }
            if server == nil, let nsClass = mcpClass as? NSObject.Type {
                server = nsClass.init()
            }
            guard let server, server.responds(to: startSel) else { continue }
            _ = server.perform(startSel, with: NSNumber(value: port))
            return
        }
        NSLog(
            "AppViewServer - Swift MCP HTTP server unavailable (add AppViewServer/MCP subspec; tried %@)",
            classNames.joined(separator: ", ")
        )
    }

    private func isiOSAppOnMac() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        #if os(iOS)
        let info = ProcessInfo.processInfo
        return info.isiOSAppOnMac || info.isMacCatalystApp
        #else
        return false
        #endif
        #endif
    }

    @objc private func _handleLocalInspect(_ note: Notification) {
        let alertController = UIAlertController(
            title: "AppView",
            message: "Failed to run local inspection. The feature has been removed. Please use the computer version of AppView or consider SDKs like FLEX for similar functionality.",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        guard let keyWindow = AVS_MultiplatformAdapter.keyWindow(),
              let rootViewController = keyWindow.rootViewController else {
            return
        }
        rootViewController.present(alertController, animated: true)
        NSLog("AppViewServer - Failed to run local inspection. The feature has been removed. Please use the computer version of AppView or consider SDKs like FLEX for similar functionality.")
    }

    @objc private func handleGetAppViewInfo(_ note: Notification) {
        guard let userInfo = note.userInfo,
              let infoWrapper = userInfo["infos"] as? NSMutableDictionary else {
            if note.userInfo?["infos"] == nil {
                NSLog("AppViewServer - GetAppViewInfo failed. Params invalid.")
            }
            return
        }
        infoWrapper["appviewServerVersion"] = appviewServerReadableVersion
    }
}

/// Allows `NSClassFromString("AppView")` to detect whether AppViewServer is linked.
@objc(AppView)
private final class AppView: NSObject {}

#endif
