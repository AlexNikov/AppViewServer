#if canImport(AppViewShared)
import AppViewShared
#endif
#if SHOULD_COMPILE_APPVIEW_SERVER

import Foundation
import UIKit

public final class AVS_AttrModificationPatchHandler: NSObject {

    public static func handleLayerOids(
        _ oids: [NSNumber],
        lowImageQuality: Bool,
        block: @escaping (AppViewDisplayItemDetail?, UInt, Error?) -> Void
    ) {
        guard Optional(block) != nil else {
            assertionFailure()
            return
        }
        guard oids is NSArray else {
            block(nil, 1, AppViewConnectionErrors.inner)
            return
        }

        for (idx, obj) in oids.enumerated() {
            let oid = obj.uintValue
            var detail = AppViewDisplayItemDetail()
            detail.displayItemOid = oid

            guard let layer = NSObject.avs_object(withOid: oid) as? CALayer else {
                block(nil, UInt(idx + 1), AppViewConnectionErrors.objectNotFound)
                return
            }

            if idx == 0 {
                detail.soloScreenshot = layer.avs_soloScreenshot(withLowQuality: lowImageQuality)
                detail.groupScreenshot = layer.avs_groupScreenshot(withLowQuality: lowImageQuality)
            } else {
                detail.groupScreenshot = layer.avs_groupScreenshot(withLowQuality: lowImageQuality)
            }
            block(detail, UInt(oids.count), nil)
        }
    }
}

#endif
