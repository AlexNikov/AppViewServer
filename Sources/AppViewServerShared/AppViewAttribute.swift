import Foundation

public class AppViewAttribute: NSObject {
    public var identifier: String?
    public var displayTitle: String?
    public var attrType: AppViewAttrType = .none
    public var value: AttributeValue?
    public var extraValue: AttributeValue?
    public var customSetterID: String?

    /// Not encoded. Set by the owning display item.
    public weak var targetDisplayItem: AppViewDisplayItem?

    public override init() {
        super.init()
    }

    public func isUserCustom() -> Bool {
        identifier == AppViewSharedAttrID.attrUserCustom
    }

    public func duplicate() -> AppViewAttribute {
        let copy = AppViewAttribute()
        copy.identifier = identifier
        copy.displayTitle = displayTitle
        copy.value = value
        copy.attrType = attrType
        copy.extraValue = extraValue
        copy.customSetterID = customSetterID
        return copy
    }
}
