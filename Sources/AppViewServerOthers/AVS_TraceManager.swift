#if canImport(AppViewShared)
import AppViewShared
#endif
#if SHOULD_COMPILE_APPVIEW_SERVER

import Foundation
import UIKit

@objc(AVS_TraceManager)
public final class AVS_TraceManager: NSObject {

    @objc public class func sharedInstance() -> AVS_TraceManager {
        SharedStorage.instance
    }

    private var searchTargets: [AppViewWeakContainer]?

    private override init() {
        super.init()
    }

    @objc public func addSearchTarger(_ target: Any?) {
        guard let target else { return }
        if searchTargets == nil {
            searchTargets = []
        }
        searchTargets?.append(AppViewWeakContainer.container(with: target))
    }

    @objc public func reload() {
        NSObject.avs_clearAllObjectsTraces()

        searchTargets?.forEach { container in
            guard let object = container.object as? NSObject else { return }
            markIVarsInAllClassLevels(of: object)
        }

        AVS_MultiplatformAdapter.allWindows().forEach { window in
            addTraceForLayersRooted(by: window.layer)
        }
    }

    private func addTraceForLayersRooted(by layer: CALayer) {
        let view = layer.avs_hostView

        if let superview = view?.superview, superview.avs_isChildrenViewOfTabBar {
            view?.avs_isChildrenViewOfTabBar = true
        } else if view is UITabBar {
            view?.avs_isChildrenViewOfTabBar = true
        }

        if let view {
            markIVarsInAllClassLevels(of: view)
            if let viewController = view.avs_findHostViewController() {
                markIVarsInAllClassLevels(of: viewController)
            }
            buildSpecialTrace(for: view)
        } else {
            markIVarsInAllClassLevels(of: layer as NSObject)
        }

        (layer.sublayers ?? []).forEach { sublayer in
            addTraceForLayersRooted(by: sublayer)
        }
    }

    private func buildSpecialTrace(for view: UIView) {
        if let viewController = view.avs_findHostViewController() {
            view.avs_specialTrace = "\(NSStringFromClass(type(of: viewController))).view"
        } else if let window = view as? UIWindow {
            let currentWindowLevel = window.windowLevel
            if window.isKeyWindow {
                view.avs_specialTrace = "KeyWindow ( Level: \(currentWindowLevel) )"
            } else {
                view.avs_specialTrace = "WindowLevel: \(currentWindowLevel)"
            }
        } else if let cell = view as? UITableViewCell {
            cell.backgroundView?.avs_specialTrace = "cell.backgroundView"
            cell.accessoryView?.avs_specialTrace = "cell.accessoryView"
        } else if let tableView = view as? UITableView {
            var relatedSectionIdx: [Int] = []
            tableView.visibleCells.forEach { cell in
                guard let indexPath = tableView.indexPath(for: cell) else { return }
                cell.avs_specialTrace = "{ sec:\(indexPath.section), row:\(indexPath.row) }"
                if !relatedSectionIdx.contains(indexPath.section) {
                    relatedSectionIdx.append(indexPath.section)
                }
            }
            relatedSectionIdx.forEach { secIdx in
                tableView.headerView(forSection: secIdx)?.avs_specialTrace = "sectionHeader { sec: \(secIdx) }"
                tableView.footerView(forSection: secIdx)?.avs_specialTrace = "sectionFooter { sec: \(secIdx) }"
            }
        } else if let collectionView = view as? UICollectionView {
            collectionView.backgroundView?.avs_specialTrace = "collectionView.backgroundView"

            collectionView.indexPathsForVisibleSupplementaryElements(
                ofKind: UICollectionView.elementKindSectionHeader
            ).forEach { indexPath in
                collectionView.supplementaryView(
                    forElementKind: UICollectionView.elementKindSectionHeader,
                    at: indexPath
                )?.avs_specialTrace = "sectionHeader { sec:\(indexPath.section) }"
            }
            collectionView.indexPathsForVisibleSupplementaryElements(
                ofKind: UICollectionView.elementKindSectionFooter
            ).forEach { indexPath in
                collectionView.supplementaryView(
                    forElementKind: UICollectionView.elementKindSectionFooter,
                    at: indexPath
                )?.avs_specialTrace = "sectionFooter { sec:\(indexPath.section) }"
            }
            collectionView.visibleCells.forEach { cell in
                guard let indexPath = collectionView.indexPath(for: cell) else { return }
                cell.avs_specialTrace = "{ item:\(indexPath.item), sec:\(indexPath.section) }"
            }
        } else if let headerFooterView = view as? UITableViewHeaderFooterView {
            headerFooterView.textLabel?.avs_specialTrace = "sectionHeaderFooter.textLabel"
            headerFooterView.detailTextLabel?.avs_specialTrace = "sectionHeaderFooter.detailTextLabel"
        }
    }

    private func markIVarsInAllClassLevels(of object: NSObject) {
        markIVars(of: object, targetClass: type(of: object))
        AVS_SwiftTraceManager.swiftMarkIVars(ofObject: object)
    }

    private static let terminationPrefixes = ["NSObject", "UIResponder", "UIButton", "UIButtonLabel"]

    private func markIVars(of hostObject: NSObject, targetClass: AnyClass?) {
        guard let targetClass else { return }

        let targetClassName = NSStringFromClass(targetClass)
        if Self.terminationPrefixes.contains(where: { targetClassName.hasPrefix($0) }) {
            return
        }

        var count: UInt32 = 0
        guard let ivars = class_copyIvarList(targetClass, &count) else { return }
        defer { free(ivars) }

        let hostDisplayClassName = makeDisplayClassName(super: targetClass, child: type(of: hostObject))

        for index in 0..<Int(count) {
            let ivar = ivars[index]
            guard let typeEncoding = ivar_getTypeEncoding(ivar) else { continue }
            let ivarType = String(validatingUTF8: typeEncoding) ?? String(cString: typeEncoding)
            guard ivarType.hasPrefix("@"), ivarType.count > 3 else {
                continue
            }

            let start = ivarType.index(ivarType.startIndex, offsetBy: 2)
            let end = ivarType.index(ivarType.endIndex, offsetBy: -1)
            let ivarClassName = String(ivarType[start..<end])
            guard let ivarClass = NSClassFromString(ivarClassName) else { continue }

            let isSupportedIvarClass =
                ivarClass.isSubclass(of: UIView.self)
                || ivarClass.isSubclass(of: CALayer.self)
                || ivarClass.isSubclass(of: UIViewController.self)
                || ivarClass.isSubclass(of: UIGestureRecognizer.self)
            if !isSupportedIvarClass {
                continue
            }

            guard let ivarNameChar = ivar_getName(ivar) else { continue }
            let ivarName = String(validatingUTF8: ivarNameChar) ?? String(cString: ivarNameChar)

            guard let ivarObject = object_getIvar(hostObject, ivar) as? NSObject else {
                continue
            }

            var ivarTrace = AppViewIvarTrace()
            ivarTrace.hostClassName = hostDisplayClassName
            ivarTrace.ivarName = ivarName

            if hostObject === ivarObject {
                ivarTrace.relation = appviewIvarTraceRelationValueSelf
            } else if let hostView = hostObject as? UIView {
                var ivarLayer: CALayer?
                if let layer = ivarObject as? CALayer {
                    ivarLayer = layer
                } else if let view = ivarObject as? UIView {
                    ivarLayer = view.layer
                }
                if let ivarLayer, ivarLayer.superlayer === hostView.layer {
                    ivarTrace.relation = "superview"
                }
            }

            if Self.invalidIvarTraces.contains(ivarTrace) {
                continue
            }

            var traces = ivarObject.avs_ivarTraces ?? []
            if !traces.contains(ivarTrace) {
                traces.append(ivarTrace)
                ivarObject.avs_ivarTraces = traces
            }
        }

        if let superClass = class_getSuperclass(targetClass) {
            markIVars(of: hostObject, targetClass: superClass)
        }
    }

    private func makeDisplayClassName(super superClass: AnyClass, child childClass: AnyClass) -> String {
        let superName = NSStringFromClass(superClass)
        let childName = NSStringFromClass(childClass)
        if childName == superName {
            return superName
        }
        return "\(childName) : \(superName)"
    }

    private static let invalidIvarTraces: [AppViewIvarTrace] = {
        func trace(hostClassName: String, ivarName: String) -> AppViewIvarTrace {
            var item = AppViewIvarTrace()
            item.hostClassName = hostClassName
            item.ivarName = ivarName
            return item
        }
        return [
            trace(hostClassName: "UIView", ivarName: "_window"),
            trace(hostClassName: "UIViewController", ivarName: "_view"),
            trace(hostClassName: "UIView", ivarName: "_viewDelegate"),
            trace(hostClassName: "UIViewController", ivarName: "_parentViewController"),
        ]
    }()

    private enum SharedStorage {
        static let instance = AVS_TraceManager()
    }
}

#endif
