import Foundation

public enum AppViewAttributesSectionStyle: Int {
    case `default` = 0
    case style0 = 1
    case style1 = 2
    case style2 = 3
}

public struct AppViewAttributesSection {
    public var identifier: String?
    public var attributes: [AppViewAttribute]?

    public init() {}

    public func isUserCustom() -> Bool {
        identifier == AppViewSharedAttrID.secUserCustom
    }

    public func duplicated() -> AppViewAttributesSection {
        var copy = self
        copy.attributes = attributes?.map { $0.duplicate() }
        return copy
    }
}
