#if canImport(AppViewShared)
import AppViewShared
#endif
#if SHOULD_COMPILE_APPVIEW_SERVER

import UIKit

extension UITextField {
    @objc var avs_fontSize: CGFloat {
        get { font?.pointSize ?? 0 }
        set {
            guard let currentFont = font else { return }
            font = currentFont.withSize(newValue)
        }
    }

    @objc(avs_fontName)
    public func avs_fontName() -> String? {
        font?.fontName
    }
}

#endif
