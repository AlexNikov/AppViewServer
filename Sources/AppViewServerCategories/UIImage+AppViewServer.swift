#if canImport(AppViewShared)
import AppViewShared
#endif
#if SHOULD_COMPILE_APPVIEW_SERVER

import ObjectiveC
import UIKit

extension UIImage {
#if APPVIEW_SERVER_DISABLE_HOOK
    @objc var avs_imageSourceName: String? {
        get { nil }
        set { }
    }
#else
    @objc(avs_imageNamed:inBundle:withConfiguration:)
    public class func avs_imageNamed(
        _ name: String,
        in bundle: Bundle?,
        with configuration: UIImage.Configuration?
    ) -> UIImage? {
        let image = avs_imageNamed(name, in: bundle, with: configuration)
        image?.avs_imageSourceName = name
        return image
    }

    @objc(avs_imageNamed:inBundle:compatibleWithTraitCollection:)
    public class func avs_imageNamed(
        _ name: String,
        in bundle: Bundle?,
        compatibleWith traitCollection: UITraitCollection?
    ) -> UIImage? {
        let image = avs_imageNamed(name, in: bundle, compatibleWith: traitCollection)
        image?.avs_imageSourceName = name
        return image
    }

    @objc(avs_imageNamed:)
    public class func avs_imageNamed(_ name: String) -> UIImage? {
        let image = avs_imageNamed(name)
        image?.avs_imageSourceName = name
        return image
    }

    @objc(avs_imageWithContentsOfFile:)
    public class func avs_imageWithContentsOfFile(_ path: String) -> UIImage? {
        let image = avs_imageWithContentsOfFile(path)
        let fileName = path.split(separator: "/").last?
            .split(separator: ".")
            .first
            .map(String.init)
        image?.avs_imageSourceName = fileName
        return image
    }

    @objc var avs_imageSourceName: String? {
        get { appview_getBindObject(forKey: "avs_imageSourceName") as? String }
        set { appview_bindObject(newValue?.copy() as? String, forKey: "avs_imageSourceName") }
    }

#endif

    @objc(appview_data)
    public func appview_data() -> Data? {
        pngData()
    }
}

#if !APPVIEW_SERVER_DISABLE_HOOK
private enum AppViewUIImageSwizzleBootstrap {
    static let run: Void = {
        exchangeClassMethod(Selector(("imageNamed:")), Selector(("avs_imageNamed:")))
        exchangeClassMethod(Selector(("imageWithContentsOfFile:")), Selector(("avs_imageWithContentsOfFile:")))
        exchangeClassMethod(
            Selector(("imageNamed:inBundle:compatibleWithTraitCollection:")),
            Selector(("avs_imageNamed:inBundle:compatibleWithTraitCollection:"))
        )
        exchangeClassMethod(
            Selector(("imageNamed:inBundle:withConfiguration:")),
            Selector(("avs_imageNamed:inBundle:withConfiguration:"))
        )
        return ()
    }()

    private static func exchangeClassMethod(_ original: Selector, _ swizzled: Selector) {
        guard let originalMethod = class_getClassMethod(UIImage.self, original),
              let swizzledMethod = class_getClassMethod(UIImage.self, swizzled) else { return }
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}

private let _appviewUIImageBootstrap = AppViewUIImageSwizzleBootstrap.run
#endif

#endif
