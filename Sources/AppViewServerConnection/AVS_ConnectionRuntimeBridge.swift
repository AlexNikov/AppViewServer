#if canImport(AppViewShared)
import AppViewShared
#endif
#if SHOULD_COMPILE_APPVIEW_SERVER

import Foundation
import UIKit

@MainActor
public final class AVS_ConnectionRuntimeBridge: NSObject {

    private static let setHiddenSelector = NSSelectorFromString("setHidden:")
    private static let setOpacitySelector = NSSelectorFromString("setOpacity:")

    public static func handleInbuiltAttrModification(
        _ modification: AppViewAttributeModification
    ) async throws -> AppViewDisplayItemDetail {
        guard let receiver = NSObject.avs_object(withOid: modification.targetOid) else {
            AppViewDiagLog.log(
                "inbuilt FAIL objNotFound targetOid=\(modification.targetOid) attr=\(modification.attrIdentifier ?? "?") sel=\(NSStringFromSelector(modification.setterSelector))"
            )
            throw appviewErrObjNotFound()
        }

        let visibilityOnly = isVisibilityOnlyModification(modification)
        AppViewDiagLog.log(
            "inbuilt recv oid=\(modification.targetOid) class=\(NSStringFromClass(type(of: receiver))) visibilityOnly=\(visibilityOnly) attr=\(modification.attrIdentifier ?? "?") sel=\(NSStringFromSelector(modification.setterSelector))"
        )

        if visibilityOnly {
            if let applyError = applyVisibilityModification(modification, to: receiver) as NSError? {
                if applyError.code != AppViewSharedErrCode.exception.rawValue {
                    throw applyError
                }
            }
            guard let detail = makeVisibilityDetail(for: modification, receiver: receiver) else {
                AppViewDiagLog.log("inbuilt FAIL visibility detail nil oid=\(modification.targetOid)")
                throw appviewErrObjNotFound()
            }
            AppViewDiagLog.log(
                "inbuilt OK visibility detailOid=\(detail.displayItemOid) hidden=\(detail.hiddenValue?.boolValue ?? false)"
            )
            return detail
        }

        if let validationError = AVS_InvocationRuntimeHelper.applySetter(
            for: modification,
            receiver: receiver
        ) as NSError? {
            if validationError.code != AppViewSharedErrCode.exception.rawValue {
                throw validationError
            }
        }

        guard let layer = layer(for: receiver) else {
            throw appviewErrObjNotFound()
        }

        var detail = AppViewDisplayItemDetail()
        detail.displayItemOid = Self.preferredDisplayItemOid(for: receiver, fallback: modification.targetOid)
        detail.frameValue = NSValue(cgRect: layer.frame)
        detail.boundsValue = NSValue(cgRect: layer.bounds)
        fillVisibilityFields(in: &detail, layer: layer)
        detail.attributesGroupList = AVS_AttrGroupsMaker.attrGroups(for: layer) as? [AppViewAttributesGroup]

        if let version = modification.clientReadableVersion,
           !version.isEmpty,
           version.appview_numbericOSVersion() >= 10004 {
            let maker = AVS_CustomAttrGroupsMaker(layer: layer)
            maker.execute()
            detail.customAttrGroupList = maker.getGroups() as? [AppViewAttributesGroup]
        }

        AppViewDiagLog.log(
            "inbuilt OK full path detailOid=\(detail.displayItemOid) attrGroups=\(detail.attributesGroupList?.count ?? 0)"
        )
        return detail
    }

    /// Hidden/Opacity: skip attr-group rebuild; assign properties directly (no invokeSetter — avoids UIView layout hangs).
    private static func isVisibilityOnlyModification(_ modification: AppViewAttributeModification) -> Bool {
        if let attrID = modification.attrIdentifier {
            if attrID == AppViewAttr_ViewLayer_Visibility_Hidden || attrID == AppViewAttr_ViewLayer_Visibility_Opacity {
                return true
            }
        }
        let sel = NSStringFromSelector(modification.setterSelector)
        if sel.contains("setHidden") || sel.contains("setOpacity") {
            return true
        }
        if modification.setterSelector == setHiddenSelector || modification.setterSelector == setOpacitySelector {
            return true
        }
        if modification.attrType == .BOOL, modification.setterSelector == setHiddenSelector {
            return true
        }
        if modification.attrType == .float || modification.attrType == .double,
           modification.setterSelector == setOpacitySelector || sel == "setOpacity:" {
            return true
        }
        return false
    }

    /// Hierarchy / dashboard key items by `viewObject.oid` when a hosted UIView exists.
    private static func preferredDisplayItemOid(for receiver: NSObject, fallback: UInt) -> UInt {
        if let view = receiver as? UIView,
           let obj = AVS_ObjCRuntimeBridge.appviewObject(for: view) as? AVObject,
           obj.oid != 0 {
            return obj.oid
        }
        if let layer = receiver as? CALayer,
           let hostView = layer.avs_hostView,
           let obj = AVS_ObjCRuntimeBridge.appviewObject(for: hostView) as? AVObject,
           obj.oid != 0 {
            return obj.oid
        }
        return fallback
    }

    private static func layer(for receiver: NSObject) -> CALayer? {
        if let calayer = receiver as? CALayer { return calayer }
        if let view = receiver as? UIView { return view.layer }
        return nil
    }

    private static func fillVisibilityFields(in detail: inout AppViewDisplayItemDetail, layer: CALayer) {
        if let hostView = layer.avs_hostView {
            detail.hiddenValue = NSNumber(value: hostView.isHidden)
            detail.alphaValue = NSNumber(value: hostView.alpha)
        } else {
            detail.hiddenValue = NSNumber(value: layer.isHidden)
            detail.alphaValue = NSNumber(value: layer.opacity)
        }
    }

    private static func makeVisibilityDetail(
        for modification: AppViewAttributeModification,
        receiver: NSObject
    ) -> AppViewDisplayItemDetail? {
        guard let layer = layer(for: receiver) else { return nil }
        var detail = AppViewDisplayItemDetail()
        detail.displayItemOid = preferredDisplayItemOid(for: receiver, fallback: modification.targetOid)
        fillVisibilityFields(in: &detail, layer: layer)
        return detail
    }

    private static func applyVisibilityModification(_ modification: AppViewAttributeModification, to receiver: NSObject) -> NSError? {
        let sel = NSStringFromSelector(modification.setterSelector)
        if sel == "setHidden:" || modification.setterSelector == setHiddenSelector {
            guard case .bool(let hidden) = modification.value else { return appviewInnerError() }
            do {
                try AppViewObjCExceptionBridge.tryExecute {
                    if let layer = receiver as? CALayer {
                        if let hostView = layer.avs_hostView {
                            hostView.isHidden = hidden
                        } else {
                            layer.isHidden = hidden
                        }
                    } else if let view = receiver as? UIView {
                        view.isHidden = hidden
                    }
                }
                return nil
            } catch {
                return appviewExceptionError(recoverySuggestion: (error as NSError).localizedDescription)
            }
        }
        if sel == "setOpacity:" || modification.setterSelector == setOpacitySelector {
            let opacity: Float
            switch modification.value {
            case .float(let v): opacity = v
            case .double(let v): opacity = Float(v)
            default: return appviewInnerError()
            }
            do {
                try AppViewObjCExceptionBridge.tryExecute {
                    if let layer = receiver as? CALayer {
                        if let hostView = layer.avs_hostView {
                            hostView.alpha = CGFloat(opacity)
                        } else {
                            layer.opacity = opacity
                        }
                    } else if let view = receiver as? UIView {
                        view.alpha = CGFloat(opacity)
                    }
                }
                return nil
            } catch {
                return appviewExceptionError(recoverySuggestion: (error as NSError).localizedDescription)
            }
        }
        return appviewInnerError()
    }

    public static func handlePatch(with tasks: [AppViewStaticAsyncUpdateTask]) -> AsyncStream<AppViewDisplayItemDetail> {
        AsyncStream { continuation in
            Task { @MainActor in
                for task in tasks {
                    var itemDetail = AppViewDisplayItemDetail()
                    itemDetail.displayItemOid = task.oid

                    if let object = NSObject.avs_object(withOid: task.oid) as? CALayer {
                        switch task.taskType {
                        case .soloScreenshot:
                            itemDetail.soloScreenshot = object.avs_soloScreenshot(withLowQuality: false)
                        case .groupScreenshot:
                            itemDetail.groupScreenshot = object.avs_groupScreenshot(withLowQuality: false)
                        default:
                            break
                        }
                    }
                    continuation.yield(itemDetail)
                }
                continuation.finish()
            }
        }
    }

    public static func methodNameList(for aClass: AnyClass, hasArg: Bool) -> [String] {
        let prefixesToVoid: Set<String> = [
            "_", "CA_", "cpl", "mf_", "vs_", "pep_", "isNS", "avkit_", "PG_", "px_", "pl_", "nsli_", "pu_", "pxg_",
        ]
        var array: [String] = []

        var currentClass: AnyClass? = aClass
        while currentClass != nil {
            guard let klass = currentClass else { break }
            let className = NSStringFromClass(klass)
            let isSystemClass = className.hasPrefix("UI") || className.hasPrefix("CA") || className.hasPrefix("NS")

            var methodCount: UInt32 = 0
            if let methods = class_copyMethodList(klass, &methodCount) {
                defer { free(methods) }
                for index in 0..<Int(methodCount) {
                    let selName = NSStringFromSelector(method_getName(methods[index]))
                    if !hasArg, selName.contains(":") { continue }

                    if isSystemClass {
                        let invalid = (prefixesToVoid as NSSet).appview_any { prefix in
                            (prefix as? String).map { selName.hasPrefix($0) } ?? false
                        }
                        if invalid { continue }
                    }

                    if !selName.isEmpty, !array.contains(selName) {
                        array.append(selName)
                    }
                }
            }
            currentClass = class_getSuperclass(klass)
        }

        return (array as NSArray).appview_sortedArrayByStringLength() as? [String] ?? array
    }

    public static func handleInvoke(
        with obj: NSObject,
        selector: Selector,
        resultDescription: AutoreleasingUnsafeMutablePointer<NSString?>?,
        resultObject: AutoreleasingUnsafeMutablePointer<AppViewObject?>?,
        error: AutoreleasingUnsafeMutablePointer<NSError?>?
    ) {
        AVS_InvocationRuntimeHelper.handleInvoke(
            with: obj,
            selector: selector,
            resultDescription: resultDescription,
            resultObject: resultObject,
            error: error
        )
    }
}

#endif
