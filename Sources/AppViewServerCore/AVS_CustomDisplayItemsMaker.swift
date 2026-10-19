#if canImport(AppViewShared)
import AppViewShared
#endif
#if SHOULD_COMPILE_APPVIEW_SERVER

import Foundation
import UIKit

@objc(AVS_CustomDisplayItemsMaker)
public final class AVS_CustomDisplayItemsMaker: NSObject {
    private weak var layer: CALayer?
    private let saveAttrSetter: Bool
    private var allSubitems: [AVDisplayItem] = []

    @objc(initWithLayer:saveAttrSetter:)
    public init(layer: CALayer, saveAttrSetter: Bool) {
        self.layer = layer
        self.saveAttrSetter = saveAttrSetter
        super.init()
    }

    @objc public func make() -> [AVDisplayItem]? {
        guard let layer else {
            assertionFailure()
            return nil
        }

        for name in AVS_CustomDebugInfoSelectors.selectorNames {
            makeSubitems(for: layer, selectorName: name)
            if let view = layer.avs_hostView {
                makeSubitems(for: view, selectorName: name)
            }
        }

        return allSubitems.isEmpty ? nil : allSubitems
    }

    private func makeSubitems(for viewOrLayer: AnyObject, selectorName: String) {
        guard let rawData = AVS_ObjCRuntimeBridge.invokeNoArgMethod(on: viewOrLayer, selectorName: selectorName) as? [String: Any] else {
            return
        }
        makeSubitems(fromRawData: rawData)
    }

    private func makeSubitems(fromRawData data: [String: Any]) {
        guard let rawSubviews = data["subviews"] as? [[String: Any]] else { return }
        let newSubitems = displayItems(fromRawArray: rawSubviews)
        allSubitems.append(contentsOf: newSubitems)
    }

    private func displayItems(fromRawArray rawArray: [[String: Any]]) -> [AVDisplayItem] {
        rawArray.compactMap { displayItem(fromRawDict: $0) }
    }

    private func displayItem(fromRawDict dict: [String: Any]) -> AVDisplayItem? {
        guard let title = dict["title"] as? String else { return nil }

        let newItem = AVDisplayItem()
        if let subviews = dict["subviews"] as? [[String: Any]] {
            newItem.subitems = displayItems(fromRawArray: subviews)
        }
        newItem.isHidden = false
        newItem.alpha = 1

        var customInfo = AppViewCustomDisplayItemInfo()
        customInfo.title = title
        customInfo.subtitle = dict["subtitle"] as? String
        if let frameValue = dict["frameInWindow"] as? NSValue {
            customInfo.frameInWindow = frameValue.cgRectValue
        } else if let rect = dict["frameInWindow"] as? CGRect {
            customInfo.frameInWindow = rect
        }
        customInfo.danceuiSource = dict["appview_source"] as? String
        newItem.customInfo = customInfo

        if let properties = dict["properties"] as? [[String: Any]] {
            newItem.customAttrGroupList = AVS_CustomAttrGroupsMaker.makeGroups(fromRawProperties: properties, saveCustomSetter: saveAttrSetter)
        }

        return newItem
    }
}

#endif
