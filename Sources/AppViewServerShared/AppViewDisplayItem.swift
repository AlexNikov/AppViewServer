import Foundation
import CoreGraphics

public enum AppViewDisplayItemImageEncodeType: UInt {
    case none = 0
    case nsData = 1
    case image = 2
}

public enum AppViewDoNotFetchScreenshotReason: UInt {
    case permitted = 0
    case tooLarge = 1
    case userConfig = 2
}

public enum AppViewDisplayItemProperty: UInt {
    case none = 0
    case frameToRoot = 1
    case displayingInHierarchy = 2
    case inHiddenHierarchy = 3
    case isExpandable = 4
    case isExpanded = 5
    case soloScreenshot = 6
    case groupScreenshot = 7
    case isSelected = 8
    case isHovered = 9
    case avoidSyncScreenshot = 10
    case inNoPreviewHierarchy = 11
    case isInSearch = 12
    case highlightedSearchString = 13
}

public protocol AppViewDisplayItemDelegate: AnyObject {
    func displayItem(_ displayItem: AppViewDisplayItem, propertyDidChange property: AppViewDisplayItemProperty)
}

public class AppViewDisplayItem: NSObject, NSCopying {
    /// When non-nil, only `subitems` and `customAttrGroupList` are meaningful on the wire.
    public var customInfo: AppViewCustomDisplayItemInfo?
    public var subitems: [AppViewDisplayItem]? {
        didSet { didSetSubitems(oldValue: oldValue) }
    }

    public var isHidden: Bool = false {
        didSet { updateInHiddenHierarchyProperty() }
    }

    public var alpha: Float = 1 {
        didSet { updateInHiddenHierarchyProperty() }
    }

    public var frame: CGRect = CGRect.zero {
        didSet { recursivelyNotifyFrameToRootMayChange() }
    }

    public var bounds: CGRect = CGRect.zero {
        didSet { recursivelyNotifyFrameToRootMayChange() }
    }

    public var soloScreenshot: AppViewImage? {
        didSet {
            guard soloScreenshot !== oldValue else { return }
            notifyDelegates(with: .soloScreenshot)
        }
    }

    public var groupScreenshot: AppViewImage? {
        didSet {
            guard groupScreenshot !== oldValue else { return }
            notifyDelegates(with: .groupScreenshot)
        }
    }

    public var viewObject: AppViewObject?
    public var layerObject: AppViewObject?
    public var hostViewControllerObject: AppViewObject?

    public var attributesGroupList: [AppViewAttributesGroup]? {
        didSet { bindAttributes(to: attributesGroupList) }
    }

    public var customAttrGroupList: [AppViewAttributesGroup]? {
        didSet { bindAttributes(to: customAttrGroupList) }
    }

    public var eventHandlers: [AppViewEventHandler]?
    public var representedAsKeyWindow: Bool = false
    public var backgroundColor: AppViewColor?
    public var shouldCaptureImage: Bool = true
    public var customDisplayTitle: String?
    public var danceuiSource: String?
    /// Ambiguous (cached scan) plus recorded conflicts for this view. `nil` when there are none.
    public var layoutIssueCount: Int?

    // MARK: - Not encoded

    public weak var previewItemDelegate: AppViewDisplayItemDelegate? {
        didSet {
            previewItemDelegate?.displayItem(self, propertyDidChange: .none)
        }
    }
    public weak var rowViewDelegate: AppViewDisplayItemDelegate?
    public weak var superItem: AppViewDisplayItem?

    public private(set) var isExpandable: Bool = false {
        didSet {
            guard isExpandable != oldValue else { return }
            notifyDelegates(with: .isExpandable)
        }
    }

    public var isExpanded: Bool = false {
        didSet {
            guard isExpanded != oldValue else { return }
            subitems?.forEach { $0.updateDisplayingInHierarchyProperty() }
            notifyDelegates(with: .isExpanded)
        }
    }

    public private(set) var displayingInHierarchy: Bool = true {
        didSet {
            guard displayingInHierarchy != oldValue else { return }
            subitems?.forEach { $0.updateDisplayingInHierarchyProperty() }
            notifyDelegates(with: .displayingInHierarchy)
        }
    }

    public private(set) var inHiddenHierarchy: Bool = false {
        didSet {
            guard inHiddenHierarchy != oldValue else { return }
            subitems?.forEach { $0.updateInHiddenHierarchyProperty() }
            notifyDelegates(with: .inHiddenHierarchy)
        }
    }

    public var screenshotEncodeType: AppViewDisplayItemImageEncodeType = .none
    public var doNotFetchScreenshotReason: AppViewDoNotFetchScreenshotReason = .permitted {
        didSet {
            guard doNotFetchScreenshotReason != oldValue else { return }
            notifyDelegates(with: .avoidSyncScreenshot)
        }
    }

    public weak var previewLayer: NSObject?
    public weak var previewNode: NSObject?
    public var noPreview: Bool = false {
        didSet { updateInNoPreviewHierarchy() }
    }

    public private(set) var inNoPreviewHierarchy: Bool = false {
        didSet {
            guard inNoPreviewHierarchy != oldValue else { return }
            subitems?.forEach { $0.updateInNoPreviewHierarchy() }
            notifyDelegates(with: .inNoPreviewHierarchy)
        }
    }

    public var previewZIndex: Int = -1
    public var preferToBeCollapsed: Bool = false
    public var hasDeterminedExpansion: Bool = false
    public var isInSearch: Bool = false {
        didSet { notifyDelegates(with: .isInSearch) }
    }

    public var highlightedSearchString: String? {
        didSet { notifyDelegates(with: .highlightedSearchString) }
    }

    private var indentLevelStorage: Int = 0

    public override init() {
        super.init()
        updateDisplayingInHierarchyProperty()
    }

    public func displayingObject() -> AppViewObject? {
        viewObject ?? layerObject
    }

    public func indentLevel() -> Int {
        indentLevelStorage
    }

    public func queryAllAttrGroupList() -> [AppViewAttributesGroup] {
        var result: [AppViewAttributesGroup] = []
        if let attributesGroupList {
            result.append(contentsOf: attributesGroupList)
        }
        if let customAttrGroupList {
            result.append(contentsOf: customAttrGroupList)
        }
        return result
    }

    public func notifySelectionChangeToDelegates() {
        notifyDelegates(with: .isSelected)
    }

    public func notifyHoverChangeToDelegates() {
        notifyDelegates(with: .isHovered)
    }
    public class func flatItems(fromHierarchicalItems items: [AppViewDisplayItem]) -> [AppViewDisplayItem] {
        flatItems(fromHierarchicalItems: items, parentIndent: -1)
    }

    private class func flatItems(
        fromHierarchicalItems items: [AppViewDisplayItem],
        parentIndent: Int
    ) -> [AppViewDisplayItem] {
        var result: [AppViewDisplayItem] = []
        for item in items {
            let indent = parentIndent + 1
            item.indentLevelStorage = indent
            result.append(item)
            if let subitems = item.subitems, !subitems.isEmpty {
                result.append(contentsOf: flatItems(fromHierarchicalItems: subitems, parentIndent: indent))
            }
        }
        return result
    }

    public func recursivelyNotifyFrameToRootMayChange() {
        notifyDelegates(with: .frameToRoot)
        subitems?.forEach { $0.recursivelyNotifyFrameToRootMayChange() }
    }

    // MARK: - NSCopying

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = AppViewDisplayItem()
        copy.subitems = subitems?.appview_map { $1.copy() as? AppViewDisplayItem }
        copy.customInfo = customInfo
        copy.isHidden = isHidden
        copy.alpha = alpha
        copy.frame = frame
        copy.bounds = bounds
        copy.soloScreenshot = soloScreenshot
        copy.groupScreenshot = groupScreenshot
        copy.viewObject = viewObject?.copy() as? AppViewObject
        copy.layerObject = layerObject?.copy() as? AppViewObject
        copy.hostViewControllerObject = hostViewControllerObject?.copy() as? AppViewObject
        copy.attributesGroupList = attributesGroupList?.map { $0.duplicated() }
        copy.customAttrGroupList = customAttrGroupList?.map { $0.duplicated() }
        copy.eventHandlers = eventHandlers
        copy.shouldCaptureImage = shouldCaptureImage
        copy.representedAsKeyWindow = representedAsKeyWindow
        copy.customDisplayTitle = customDisplayTitle
        copy.danceuiSource = danceuiSource
        copy.backgroundColor = backgroundColor
        copy.layoutIssueCount = layoutIssueCount
        copy.updateDisplayingInHierarchyProperty()
        return copy
    }

    // MARK: - Private

    private static func decodeScreenshot(_ object: Any) -> AppViewImage? {
        if let data = object as? Data {
            return AppViewCodingBridge.decodedObject(data, type: .image) as? AppViewImage
        }
        return object as? AppViewImage
    }

    private func didSetSubitems(oldValue: [AppViewDisplayItem]?) {
        oldValue?.forEach { $0.superItem = nil }
        isExpandable = (subitems?.isEmpty == false)
        subitems?.forEach { child in
            child.superItem = self
            child.updateInHiddenHierarchyProperty()
            child.updateDisplayingInHierarchyProperty()
        }
    }

    private func bindAttributes(to groups: [AppViewAttributesGroup]?) {
        groups?.forEach { group in
            group.attrSections?.forEach { section in
                section.attributes?.forEach { $0.targetDisplayItem = self }
            }
        }
    }

    fileprivate func updateDisplayingInHierarchyProperty() {
        if let superItem, (!superItem.displayingInHierarchy || !superItem.isExpanded) {
            displayingInHierarchy = false
        } else {
            displayingInHierarchy = true
        }
    }

    fileprivate func updateInHiddenHierarchyProperty() {
        if superItem?.inHiddenHierarchy == true || isHidden || alpha <= 0 {
            inHiddenHierarchy = true
        } else {
            inHiddenHierarchy = false
        }
    }

    fileprivate func updateInNoPreviewHierarchy() {
        if superItem?.inNoPreviewHierarchy == true || noPreview {
            inNoPreviewHierarchy = true
        } else {
            inNoPreviewHierarchy = false
        }
    }

    private func notifyDelegates(with property: AppViewDisplayItemProperty) {
        previewItemDelegate?.displayItem(self, propertyDidChange: property)
        rowViewDelegate?.displayItem(self, propertyDidChange: property)
    }
}
