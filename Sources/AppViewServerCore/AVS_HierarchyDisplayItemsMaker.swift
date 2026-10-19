#if canImport(AppViewShared)
import AppViewShared
#endif
#if SHOULD_COMPILE_APPVIEW_SERVER

import Foundation
import UIKit

private typealias AVMultiplatformAdapter = AVS_MultiplatformAdapter

public final class AVS_HierarchyDisplayItemsMaker: NSObject {

    /// `scanLayoutIssues` probes each view for ambiguous layout during this walk and replaces the scan cache.
    public static func items(
        withScreenshots hasScreenshots: Bool,
        attrList hasAttrList: Bool,
        lowImageQuality lowQuality: Bool,
        readCustomInfo: Bool,
        saveCustomSetter: Bool,
        scanLayoutIssues: Bool = false
    ) -> [AVDisplayItem] {
        AVS_TraceManager.sharedInstance().reload()

        let windows = AVMultiplatformAdapter.allWindows() as? [UIWindow] ?? []
        var result: [AVDisplayItem] = []
        result.reserveCapacity(windows.count)
        let issueCounter = AVS_LayoutIssueCounter(scanning: scanLayoutIssues)

        for window in windows {
            guard let item = displayItem(
                with: window.layer,
                screenshots: hasScreenshots,
                attrList: hasAttrList,
                lowImageQuality: lowQuality,
                readCustomInfo: readCustomInfo,
                saveCustomSetter: saveCustomSetter,
                issueCounter: issueCounter
            ) else { continue }
            item.representedAsKeyWindow = window.isKeyWindow
            result.append(item)
        }
        issueCounter.finish()
        return result
    }

    public static func subitems(of layer: CALayer) -> [AVDisplayItem] {
        guard let sublayers = layer.sublayers, !sublayers.isEmpty else { return [] }

        AVS_TraceManager.sharedInstance().reload()

        let issueCounter = AVS_LayoutIssueCounter(scanning: false)
        var resultSubitems: [AVDisplayItem] = []
        for sublayer in sublayers {
            guard let sublayerItem = displayItem(
                with: sublayer,
                screenshots: false,
                attrList: false,
                lowImageQuality: false,
                readCustomInfo: true,
                saveCustomSetter: true,
                issueCounter: issueCounter
            ) else { continue }
            resultSubitems.append(sublayerItem)
        }

        let customMaker = AVS_CustomDisplayItemsMaker(layer: layer, saveAttrSetter: true)
        if let customSubitems = customMaker.make() {
            resultSubitems.append(contentsOf: customSubitems)
        }
        return resultSubitems
    }

    private static func displayItem(
        with layer: CALayer,
        screenshots hasScreenshots: Bool,
        attrList hasAttrList: Bool,
        lowImageQuality lowQuality: Bool,
        readCustomInfo: Bool,
        saveCustomSetter: Bool,
        issueCounter: AVS_LayoutIssueCounter
    ) -> AVDisplayItem? {
        let item = AVDisplayItem()
        var layerFrame = layer.frame

        if let hostView = layer.avs_hostView, let superview = hostView.superview {
            layerFrame = superview.convert(layerFrame, to: nil)
        }

        if validateFrame(layerFrame) {
            item.frame = layer.frame
        } else {
            NSLog(
                "AppViewServer - The layer frame(%@) seems really weird. AppView will ignore it to avoid potential render error in AppView.",
                NSCoder.string(for: layer.frame)
            )
            item.frame = .zero
        }
        item.bounds = layer.bounds

        if hasScreenshots {
            item.soloScreenshot = layer.avs_soloScreenshot(withLowQuality: lowQuality)
            item.groupScreenshot = layer.avs_groupScreenshot(withLowQuality: lowQuality)
            item.screenshotEncodeType = AppViewDisplayItemImageEncodeType.nsData
        }

        if hasAttrList {
            item.attributesGroupList = AVS_AttrGroupsMaker.attrGroups(for: layer)
            let maker = AVS_CustomAttrGroupsMaker(layer: layer)
            maker.execute()
            item.customAttrGroupList = maker.getGroups()
            item.customDisplayTitle = maker.getCustomDisplayTitle()
            item.danceuiSource = maker.getDanceUISource()
        } else if readCustomInfo {
            item.customDisplayTitle = customDisplayTitle(for: layer)
        }

        item.layerObject = AVS_ObjCRuntimeBridge.appviewObject(for: layer) as! AVObject
        item.shouldCaptureImage = AVSConfigManager.shouldCaptureScreenshot(of: layer)

        if let view = layer.avs_hostView {
            item.isHidden = view.isHidden
            item.alpha = Float(view.alpha)
            item.viewObject = AVS_ObjCRuntimeBridge.appviewObject(for: view) as! AVObject
            let issueCount = issueCounter.count(for: view, oid: item.viewObject?.oid ?? 0)
            item.layoutIssueCount = issueCount > 0 ? issueCount : nil
            item.eventHandlers = AVS_EventHandlerMaker.make(for: view)
            item.backgroundColor = view.backgroundColor
                ?? UIColor.avs_colorWithCGColor(view.layer.backgroundColor)
            if let viewController = view.avs_findHostViewController() {
                item.hostViewControllerObject = AVS_ObjCRuntimeBridge.appviewObject(for: viewController) as! AVObject
            }
        } else {
            item.isHidden = layer.isHidden
            item.alpha = Float(layer.opacity)
            item.backgroundColor = UIColor.avs_colorWithCGColor(layer.backgroundColor)
        }

        if let sublayers = layer.sublayers, !sublayers.isEmpty {
            var allSubitems: [AVDisplayItem] = []
            allSubitems.reserveCapacity(sublayers.count)
            for sublayer in sublayers {
                guard let sublayerItem = displayItem(
                    with: sublayer,
                    screenshots: hasScreenshots,
                    attrList: hasAttrList,
                    lowImageQuality: lowQuality,
                    readCustomInfo: readCustomInfo,
                    saveCustomSetter: saveCustomSetter,
                    issueCounter: issueCounter
                ) else { continue }
                allSubitems.append(sublayerItem)
            }
            item.subitems = allSubitems
        }

        if readCustomInfo {
            let customMaker = AVS_CustomDisplayItemsMaker(layer: layer, saveAttrSetter: saveCustomSetter)
            if let customSubitems = customMaker.make(), !customSubitems.isEmpty {
                if let existing = item.subitems {
                    item.subitems = existing + customSubitems
                } else {
                    item.subitems = customSubitems
                }
            }
        }

        return item
    }

    private static func validateFrame(_ frame: CGRect) -> Bool {
        !frame.isNull && !frame.isInfinite && !cgRectIsNaN(frame) && !cgRectIsInf(frame) && !cgRectIsUnreasonable(frame)
    }

    private static func customDisplayTitle(for layer: CALayer) -> String? {
        for name in AVS_CustomDebugInfoSelectors.selectorNames {
            if let title = customDisplayTitle(from: layer, selectorName: name) {
                return title
            }
            if let view = layer.avs_hostView,
               let title = customDisplayTitle(from: view, selectorName: name) {
                return title
            }
        }
        return nil
    }

    private static func customDisplayTitle(from object: AnyObject, selectorName: String) -> String? {
        guard let rawData = AVS_ObjCRuntimeBridge.invokeNoArgMethod(on: object, selectorName: selectorName) as? [String: Any],
              let title = rawData["title"] as? String,
              !title.isEmpty else {
            return nil
        }
        return title
    }

    private static func cgRectIsNaN(_ rect: CGRect) -> Bool {
        rect.origin.x.isNaN || rect.origin.y.isNaN || rect.size.width.isNaN || rect.size.height.isNaN
    }

    private static func cgRectIsInf(_ rect: CGRect) -> Bool {
        rect.origin.x.isInfinite || rect.origin.y.isInfinite || rect.size.width.isInfinite || rect.size.height.isInfinite
    }

    private static func cgRectIsUnreasonable(_ rect: CGRect) -> Bool {
        abs(rect.origin.x) > 100_000
            || abs(rect.origin.y) > 100_000
            || rect.size.width < 0
            || rect.size.height < 0
            || rect.size.width > 100_000
            || rect.size.height > 100_000
    }
}

#endif
