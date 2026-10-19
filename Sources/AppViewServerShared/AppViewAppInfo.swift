import Foundation

public enum AppViewAppInfoDevice: Int {
    case simulator = 0
    case iPad = 1
    case others = 2
}

public class AppViewAppInfo: NSObject, NSCopying {
    public var appInfoIdentifier: UInt = 0
    public var shouldUseCache: Bool = false
    public var serverVersion: Int32 = 0
    public var serverReadableVersion: String?
    public var swiftEnabledInAppViewServer: Int32 = 0
    public var screenshot: AppViewImage?
    public var appIcon: AppViewImage?
    public var appName: String?
    public var appBundleIdentifier: String?
    public var deviceDescription: String?
    public var osDescription: String?
    public var osMainVersion: UInt = 0
    public var deviceType: AppViewAppInfoDevice = .others
    public var screenWidth: Double = 0
    public var screenHeight: Double = 0
    public var screenScale: Double = 0
    #if os(macOS)
    public var cachedTimestamp: TimeInterval = 0
    #endif

    public override init() {
        super.init()
    }

    public func isEqual(toAppInfo info: AppViewAppInfo?) -> Bool {
        guard let info else { return false }
        return appName == info.appName
            && deviceDescription == info.deviceDescription
            && osDescription == info.osDescription
            && deviceType == info.deviceType
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? AppViewAppInfo else { return false }
        return isEqual(toAppInfo: other)
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(appName)
        hasher.combine(deviceDescription)
        hasher.combine(osDescription)
        hasher.combine(deviceType.rawValue)
        return hasher.finalize()
    }

    // MARK: - NSCopying

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = AppViewAppInfo()
        copy.appIcon = appIcon
        copy.appName = appName
        copy.deviceDescription = deviceDescription
        copy.osDescription = osDescription
        copy.osMainVersion = osMainVersion
        copy.deviceType = deviceType
        copy.screenWidth = screenWidth
        copy.screenHeight = screenHeight
        copy.screenScale = screenScale
        copy.appInfoIdentifier = appInfoIdentifier
        copy.shouldUseCache = shouldUseCache
        copy.serverVersion = serverVersion
        copy.serverReadableVersion = serverReadableVersion
        copy.swiftEnabledInAppViewServer = swiftEnabledInAppViewServer
        copy.screenshot = screenshot
        copy.appBundleIdentifier = appBundleIdentifier
        return copy
    }

    private enum CodingKey {
        static let appIcon = "1"
        static let screenshot = "2"
        static let deviceDescription = "3"
        static let osDescription = "4"
        static let appName = "5"
        static let screenWidth = "6"
        static let screenHeight = "7"
        static let deviceType = "8"
    }

}
