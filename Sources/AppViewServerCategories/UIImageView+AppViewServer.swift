#if canImport(AppViewShared)
import AppViewShared
#endif
#if SHOULD_COMPILE_APPVIEW_SERVER

import UIKit

extension UIImageView {
    @objc(avs_imageSourceName)
    public func avs_imageSourceName() -> String? {
        image?.avs_imageSourceName
    }

    @objc(avs_imageViewOidIfHasImage)
    public func avs_imageViewOidIfHasImage() -> NSNumber? {
        guard image != nil else { return nil }
        return NSNumber(value: avs_registerOid())
    }
}

#endif
