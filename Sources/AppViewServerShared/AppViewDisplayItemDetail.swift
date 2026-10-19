import Foundation

public struct AppViewDisplayItemDetail {
    public var displayItemOid: UInt = 0
    public var groupScreenshot: AppViewImage?
    public var soloScreenshot: AppViewImage?
    public var frameValue: NSValue?
    public var boundsValue: NSValue?
    public var hiddenValue: NSNumber?
    public var alphaValue: NSNumber?
    public var customDisplayTitle: String?
    public var danceUISource: String?
    public var attributesGroupList: [AppViewAttributesGroup]?
    public var customAttrGroupList: [AppViewAttributesGroup]?
    public var subitems: [AppViewDisplayItem]?
    public var failureCode: Int = 0

    public init() {}
}
