import Foundation
#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

enum WireHierarchyObjectMapping {
    static func wireRef(_ object: AppViewObject?) -> WireObjectRef? {
        guard let object, object.oid != 0 else { return nil }
        return WireObjectRef(
            oid: object.oid,
            classChainList: object.classChainList,
            memoryAddress: object.memoryAddress,
            specialTrace: object.specialTrace,
            ivarTraces: object.ivarTraces?.map(wireIvarTrace(from:))
        )
    }

    static func appviewObject(from ref: WireObjectRef) -> AppViewObject {
        let object = AppViewObject()
        object.oid = ref.oid
        object.classChainList = ref.classChainList
        object.memoryAddress = ref.memoryAddress
        object.specialTrace = ref.specialTrace
        object.ivarTraces = ref.ivarTraces?.map(appviewIvarTrace(from:))
        return object
    }

    static func wireIvarTrace(from trace: AppViewIvarTrace) -> WireIvarTrace {
        WireIvarTrace(
            relation: trace.relation,
            hostClassName: trace.hostClassName,
            ivarName: trace.ivarName
        )
    }

    static func appviewIvarTrace(from wire: WireIvarTrace) -> AppViewIvarTrace {
        var trace = AppViewIvarTrace()
        trace.relation = wire.relation
        trace.hostClassName = wire.hostClassName
        trace.ivarName = wire.ivarName
        return trace
    }

    static func wireBackgroundColorRGBA(from color: AppViewColor?) -> [Double]? {
        guard let color else { return nil }
        let rgba = color.appview_rgbaComponents
        guard rgba.count >= 4 else { return nil }
        // JSONEncoder rejects NaN/Inf — sanitize like geometry fields.
        return rgba.map { $0.doubleValue.appviewJSONFinite }
    }

    static func appviewBackgroundColor(from rgba: [Double]?) -> AppViewColor? {
        guard let rgba, rgba.count >= 4 else { return nil }
        return AppViewColor.appview_color(fromRGBAComponents: rgba.map { NSNumber(value: $0) })
    }
}

public enum WireHierarchyMapper {
    public static func wirePayload(from info: AppViewHierarchyInfo) -> WireHierarchyPayload {
        WireHierarchyPayload(
            serverVersion: info.serverVersion,
            displayItems: (info.displayItems ?? []).map { wireItem(from: $0) },
            collapsedClassList: info.collapsedClassList,
            appInfo: info.appInfo.map { WireRequestResponseMapper.wireAppInfo(from: $0) }
        )
    }

    public static func appviewHierarchy(from payload: WireHierarchyPayload) -> AppViewHierarchyInfo {
        let info = AppViewHierarchyInfo()
        info.serverVersion = payload.serverVersion
        info.displayItems = payload.displayItems.map { appviewItem(from: $0) }
        info.collapsedClassList = payload.collapsedClassList
        if let wireApp = payload.appInfo {
            info.appInfo = WireRequestResponseMapper.appviewAppInfo(from: wireApp)
        }
        return info
    }

    public static func wireItem(from item: AppViewDisplayItem) -> WireDisplayItem {
        let oid = item.layerObject?.oid ?? item.viewObject?.oid ?? 0
        let wireCustomInfo: WireCustomDisplayItemInfo?
        if let customInfo = item.customInfo {
            let frameRect: Rect? = customInfo.frameInWindow.map { Rect($0) }
            wireCustomInfo = WireCustomDisplayItemInfo(
                frameInWindow: frameRect,
                title: customInfo.title,
                subtitle: customInfo.subtitle,
                danceuiSource: customInfo.danceuiSource
            )
        } else {
            wireCustomInfo = nil
        }
        return WireDisplayItem(
            oid: oid,
            frame: Rect(item.frame),
            bounds: Rect(item.bounds),
            isHidden: item.isHidden,
            alpha: item.alpha.appviewJSONFinite,
            shouldCaptureImage: item.shouldCaptureImage,
            customDisplayTitle: item.customDisplayTitle,
            representedAsKeyWindow: item.representedAsKeyWindow ? true : nil,
            layerRef: WireHierarchyObjectMapping.wireRef(item.layerObject),
            viewRef: WireHierarchyObjectMapping.wireRef(item.viewObject),
            hostViewControllerRef: WireHierarchyObjectMapping.wireRef(item.hostViewControllerObject),
            customInfo: wireCustomInfo,
            attributesGroupList: item.attributesGroupList?.map { WireAttributeMapper.wireGroup(from: $0) },
            customAttrGroupList: item.customAttrGroupList?.map { WireAttributeMapper.wireGroup(from: $0) },
            backgroundColorRGBA: WireHierarchyObjectMapping.wireBackgroundColorRGBA(from: item.backgroundColor),
            layoutIssueCount: item.layoutIssueCount.flatMap { $0 > 0 ? $0 : nil },
            subitems: item.subitems?.map { wireItem(from: $0) }
        )
    }

    public static func appviewItem(from wire: WireDisplayItem) -> AppViewDisplayItem {
        let item = AppViewDisplayItem()
        item.frame = wire.frame.cgRect
        item.bounds = wire.bounds.cgRect
        item.isHidden = wire.isHidden
        item.alpha = wire.alpha
        item.shouldCaptureImage = wire.shouldCaptureImage
        item.customDisplayTitle = wire.customDisplayTitle
        item.backgroundColor = WireHierarchyObjectMapping.appviewBackgroundColor(from: wire.backgroundColorRGBA)
        item.layoutIssueCount = wire.layoutIssueCount
        if wire.representedAsKeyWindow == true {
            item.representedAsKeyWindow = true
        }
        if let layerRef = wire.layerRef {
            item.layerObject = WireHierarchyObjectMapping.appviewObject(from: layerRef)
        }
        if let viewRef = wire.viewRef {
            item.viewObject = WireHierarchyObjectMapping.appviewObject(from: viewRef)
        }
        if let hostVCRef = wire.hostViewControllerRef {
            item.hostViewControllerObject = WireHierarchyObjectMapping.appviewObject(from: hostVCRef)
        }
        if let wireInfo = wire.customInfo {
            var info = AppViewCustomDisplayItemInfo()
            info.frameInWindow = wireInfo.frameInWindow?.cgRect
            info.title = wireInfo.title
            info.subtitle = wireInfo.subtitle
            info.danceuiSource = wireInfo.danceuiSource
            item.customInfo = info
        }
        if let groups = wire.attributesGroupList {
            item.attributesGroupList = groups.map { WireAttributeMapper.appviewGroup(from: $0) }
        }
        if let groups = wire.customAttrGroupList {
            item.customAttrGroupList = groups.map { WireAttributeMapper.appviewGroup(from: $0) }
        }
        item.subitems = wire.subitems?.map { appviewItem(from: $0) }
        return item
    }

    public static func wireDetail(from detail: AppViewDisplayItemDetail) -> WireDisplayItemDetailPayload {
        WireDetailMapper.wireDetail(from: detail)
    }

    public static func appviewDetail(from payload: WireDisplayItemDetailPayload) -> AppViewDisplayItemDetail {
        WireDetailMapper.appviewDetail(from: payload)
    }

    public static func applyWireDetail(_ payload: WireDisplayItemDetailPayload, to item: AppViewDisplayItem) {
        if let frame = payload.frame {
            item.frame = frame.cgRect
        }
        if let bounds = payload.bounds {
            item.bounds = bounds.cgRect
        }
        if let hidden = payload.isHidden {
            item.isHidden = hidden
        }
        if let alpha = payload.alpha {
            item.alpha = alpha
        }
        if let subitems = payload.subitems {
            item.subitems = subitems.map { appviewItem(from: $0) }
        }
    }
}
