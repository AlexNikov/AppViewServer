#if canImport(AppViewShared)
import AppViewShared
#endif
#if SHOULD_COMPILE_APPVIEW_SERVER

import Foundation
import UIKit

public final class AVS_AttrGroupsMaker: NSObject {

    public static func attrGroups(for layer: CALayer?) -> [AVAttributesGroup]? {
        guard let layer else {
            assertionFailure()
            return nil
        }

        let groupIDs = AppViewDashboardBlueprint.groupIDs()
        let groups: [AVAttributesGroup] = groupIDs.compactMap { groupID in
            var group = AVAttributesGroup()
            group.identifier = groupID

            let secIDs = AppViewDashboardBlueprint.sectionIDs(forGroupID: groupID)
            let sections: [AVAttributesSection] = secIDs.compactMap { secID in
                var sec = AVAttributesSection()
                sec.identifier = secID

                let attrIDs = AppViewDashboardBlueprint.attrIDs(forSectionID: secID)
                let attributes: [AVAttribute] = attrIDs.compactMap { attrID in
                    let minVersion = AppViewDashboardBlueprint.minAvailableOSVersion(withAttrID: attrID)
                    if minVersion > 0,
                       ProcessInfo.processInfo.operatingSystemVersion.majorVersion < minVersion {
                        return nil
                    }

                    let targetObj: AnyObject?
                    if AppViewDashboardBlueprint.isUIViewProperty(withAttrID: attrID) {
                        targetObj = layer.avs_hostView
                    } else {
                        targetObj = layer
                    }
                    guard let targetObj else { return nil }

                    if let className = AppViewDashboardBlueprint.className(withAttrID: attrID),
                       let targetClass = NSClassFromString(className),
                       !targetObj.isKind(of: targetClass) {
                        return nil
                    }

                    return AVS_ObjCRuntimeBridge.attribute(withIdentifier: attrID, targetObject: targetObj)
                }

                guard !attributes.isEmpty else { return nil }
                sec.attributes = attributes
                return sec
            }

            if groupID == AppViewSharedAttrID.groupAutoLayout {
                let hasConstraints = sections.contains {
                    $0.identifier == AppViewSharedAttrID.secAutoLayoutConstraints
                        || $0.identifier == AppViewAttrSec_AutoLayout_Issues
                        || $0.identifier == AppViewAttrSec_AutoLayout_InstalledConstraints
                }
                if !hasConstraints { return nil }
            }

            guard !sections.isEmpty else { return nil }
            group.attrSections = sections
            return group
        }

        return groups
    }
}

#endif
