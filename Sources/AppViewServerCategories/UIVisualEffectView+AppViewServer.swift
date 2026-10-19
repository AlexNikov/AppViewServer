#if canImport(AppViewShared)
import AppViewShared
#endif
#if SHOULD_COMPILE_APPVIEW_SERVER

import UIKit

extension UIVisualEffectView {
    @objc var avs_blurEffectStyleNumber: NSNumber? {
        get {
            guard let blurEffect = effect as? UIBlurEffect else { return nil }
            return blurEffect.avs_effectStyleNumber
        }
        set {
            guard let styleNumber = newValue else { return }
            let style = UIBlurEffect.Style(rawValue: styleNumber.intValue) ?? .regular
            effect = UIBlurEffect(style: style)
        }
    }
}

#endif
