import Foundation

public struct AppViewAttributeModification {
    public var targetOid: UInt = 0
    public var setterSelector: Selector = NSSelectorFromString("")
    public var getterSelector: Selector = NSSelectorFromString("")
    /// Stable attr id (e.g. `vl_v_h`) so the server can take the fast visibility path without rebuilding attr groups.
    public var attrIdentifier: AppViewAttrIdentifier?
    public var attrType: AppViewAttrType = .none
    public var value: AttributeValue?
    public var clientReadableVersion: String?

    public init() {}
}
