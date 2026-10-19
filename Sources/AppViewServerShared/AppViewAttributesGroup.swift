import Foundation

public struct AppViewAttributesGroup: Hashable {
    public var userCustomTitle: String?
    public var identifier: String?
    public var attrSections: [AppViewAttributesSection]?

    public init() {}

    public func uniqueKey() -> String? {
        identifier == AppViewSharedAttrID.groupUserCustom ? userCustomTitle : identifier
    }

    public func isUserCustom() -> Bool {
        identifier == AppViewSharedAttrID.groupUserCustom
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(uniqueKey())
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.identifier == rhs.identifier else { return false }
        if lhs.identifier == AppViewSharedAttrID.groupUserCustom {
            return lhs.userCustomTitle == rhs.userCustomTitle
        }
        return true
    }

    public func duplicated() -> AppViewAttributesGroup {
        var copy = self
        copy.attrSections = attrSections?.map { $0.duplicated() }
        return copy
    }
}
