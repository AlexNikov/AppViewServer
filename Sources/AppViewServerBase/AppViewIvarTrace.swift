import Foundation

public let appviewIvarTraceRelationValueSelf = "self"

public struct AppViewIvarTrace: Hashable {
    public var relation: String?
    public var hostClassName: String?
    public var ivarName: String?

    public init() {}

    public func hash(into hasher: inout Hasher) {
        hasher.combine(hostClassName)
        hasher.combine(ivarName)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.hostClassName == rhs.hostClassName && lhs.ivarName == rhs.ivarName
    }
}
