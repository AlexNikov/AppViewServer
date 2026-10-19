#if canImport(AppViewShared)
import AppViewShared
#endif
#if SHOULD_COMPILE_APPVIEW_SERVER

import Foundation
import UIKit

public final class AVS_CustomAttrGroupsMaker: NSObject {
    private var sectionAndAttrs: [String: [AVAttribute]] = [:]
    private var resolvedCustomDisplayTitle: String?
    private var resolvedDanceUISource: String?
    private var resolvedGroups: [AVAttributesGroup]?
    private weak var layer: CALayer?

    public init(layer: CALayer) {
        self.layer = layer
        super.init()
    }

    @objc public func execute() {
        guard let layer else {
            assertionFailure()
            return
        }

        for name in AVS_CustomDebugInfoSelectors.selectorNames {
            makeAttrs(for: layer, selectorName: name)
            if let view = layer.avs_hostView {
                makeAttrs(for: view, selectorName: name)
            }
        }

        guard !sectionAndAttrs.isEmpty else { return }

        var groups: [AVAttributesGroup] = []
        for (groupTitle, attrs) in sectionAndAttrs {
            var group = AVAttributesGroup()
            group.userCustomTitle = groupTitle
            group.identifier = AppViewSharedAttrID.groupUserCustom

            let sections = attrs.map { attr -> AVAttributesSection in
                var sec = AVAttributesSection()
                sec.identifier = AppViewSharedAttrID.secUserCustom
                sec.attributes = [attr]
                return sec
            }
            group.attrSections = sections
            groups.append(group)
        }

        groups.sort { ($0.userCustomTitle ?? "") < ($1.userCustomTitle ?? "") }
        resolvedGroups = groups
    }

    private func makeAttrs(for viewOrLayer: AnyObject, selectorName: String) {
        guard let rawData = AVS_ObjCRuntimeBridge.invokeNoArgMethod(on: viewOrLayer, selectorName: selectorName) as? [String: Any] else {
            return
        }

        if let customTitle = rawData["title"] as? String, !customTitle.isEmpty {
            resolvedCustomDisplayTitle = customTitle
        }
        if let danceSource = rawData["appview_source"] as? String, !danceSource.isEmpty {
            resolvedDanceUISource = danceSource
        }

        if let rawProperties = rawData["properties"] as? [[String: Any]] {
            makeAttrs(fromRawProperties: rawProperties)
        }
    }

    private func makeAttrs(fromRawProperties rawProperties: [[String: Any]]) {
        for dict in rawProperties {
            var groupTitle: NSString? = "Custom"
            guard let attr = AVS_ObjCRuntimeBridge.customAttribute(fromRawDictionary: dict, saveCustomSetter: true, groupTitle: &groupTitle) as! AVAttribute? else {
                continue
            }
            let key = (groupTitle as String?) ?? "Custom"
            sectionAndAttrs[key, default: []].append(attr)
        }
    }

    public func getGroups() -> [AVAttributesGroup]? { resolvedGroups }
    @objc public func getCustomDisplayTitle() -> String? { resolvedCustomDisplayTitle }
    @objc public func getDanceUISource() -> String? { resolvedDanceUISource }

    public static func makeGroups(fromRawProperties rawProperties: [[String: Any]]?, saveCustomSetter: Bool) -> [AVAttributesGroup]? {
        guard let rawProperties else { return nil }

        var groupTitleAndAttrs: [String: [AVAttribute]] = [:]
        for dict in rawProperties {
            var groupTitle: NSString? = "Custom"
            guard let attr = AVS_ObjCRuntimeBridge.customAttribute(fromRawDictionary: dict, saveCustomSetter: saveCustomSetter, groupTitle: &groupTitle) as! AVAttribute? else {
                continue
            }
            let key = (groupTitle as String?) ?? "Custom"
            groupTitleAndAttrs[key, default: []].append(attr)
        }

        guard !groupTitleAndAttrs.isEmpty else { return nil }

        var groups: [AVAttributesGroup] = []
        for (groupTitle, attrs) in groupTitleAndAttrs {
            var group = AVAttributesGroup()
            group.userCustomTitle = groupTitle
            group.identifier = AppViewSharedAttrID.groupUserCustom

            let sections = attrs.map { attr -> AVAttributesSection in
                var sec = AVAttributesSection()
                sec.identifier = AppViewSharedAttrID.secUserCustom
                sec.attributes = [attr]
                return sec
            }
            group.attrSections = sections
            groups.append(group)
        }

        groups.sort { ($0.userCustomTitle ?? "") < ($1.userCustomTitle ?? "") }
        return groups
    }
}

#endif
