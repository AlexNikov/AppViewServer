import Foundation

public class AppViewHierarchyInfo: NSObject, NSCopying {
    public var displayItems: [AppViewDisplayItem]?
    public var colorAlias: [String: Any]?
    public var collapsedClassList: [String]?
    public var appInfo: AppViewAppInfo?
    public var serverVersion: Int32 = 0

    public override init() {
        super.init()
    }

    // MARK: - NSCopying

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = AppViewHierarchyInfo()
        copy.serverVersion = serverVersion
        copy.appInfo = appInfo?.copy() as? AppViewAppInfo
        copy.collapsedClassList = collapsedClassList
        copy.colorAlias = colorAlias
        copy.displayItems = displayItems?.appview_map { $1.copy() as? AppViewDisplayItem }
        return copy
    }

    private enum CodingKey {
        static let displayItems = "1"
        static let appInfo = "2"
        static let colorAlias = "3"
        static let collapsedClassList = "4"
    }

}
