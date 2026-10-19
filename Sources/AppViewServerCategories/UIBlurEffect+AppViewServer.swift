#if canImport(AppViewShared)
import AppViewShared
#endif
#if SHOULD_COMPILE_APPVIEW_SERVER

import ObjectiveC
import UIKit

extension UIBlurEffect {
#if APPVIEW_SERVER_DISABLE_HOOK
    @objc var avs_effectStyleNumber: NSNumber? {
        get { nil }
        set { }
    }
#else
    @objc(avs_effectWithStyle:)
    public class func avs_effect(withStyle style: UIBlurEffect.Style) -> UIBlurEffect {
        let effect = avs_effect(withStyle: style)
        effect.avs_effectStyleNumber = NSNumber(value: style.rawValue)
        return effect
    }

    @objc var avs_effectStyleNumber: NSNumber? {
        get { appview_getBindObject(forKey: "avs_effectStyleNumber") as? NSNumber }
        set { appview_bindObject(newValue, forKey: "avs_effectStyleNumber") }
    }

#endif
}

#if !APPVIEW_SERVER_DISABLE_HOOK
private enum AppViewUIBlurEffectSwizzleBootstrap {
    static let run: Void = {
        let original = class_getClassMethod(UIBlurEffect.self, Selector(("effectWithStyle:")))
        let swizzled = class_getClassMethod(UIBlurEffect.self, Selector(("avs_effectWithStyle:")))
        if let original, let swizzled {
            method_exchangeImplementations(original, swizzled)
        }
        return ()
    }()
}

private let _appviewUIBlurEffectBootstrap = AppViewUIBlurEffectSwizzleBootstrap.run
#endif

#endif
