#if canImport(AppViewShared)
import AppViewShared
#endif
#if SHOULD_COMPILE_APPVIEW_SERVER

import UIKit

extension UILabel {
    @objc var avs_fontSize: CGFloat {
        get { font.pointSize }
        set { font = font.withSize(newValue) }
    }

    @objc(avs_fontName)
    public func avs_fontName() -> String {
        font.fontName
    }
}

#endif
