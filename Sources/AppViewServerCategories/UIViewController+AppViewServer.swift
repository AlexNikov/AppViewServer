#if canImport(AppViewShared)
import AppViewShared
#endif
#if SHOULD_COMPILE_APPVIEW_SERVER

import UIKit

extension UIViewController {
    @objc(avs_visibleViewController)
    public static func avs_visibleViewController() -> UIViewController? {
        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else {
            return nil
        }
        return rootViewController.avs_visibleViewControllerIfExist()
    }

    @objc(avs_visibleViewControllerIfExist)
    public func avs_visibleViewControllerIfExist() -> UIViewController? {
        if let presentedViewController {
            return presentedViewController.avs_visibleViewControllerIfExist()
        }

        if let navigationController = self as? UINavigationController {
            return navigationController.visibleViewController?.avs_visibleViewControllerIfExist()
        }

        if let tabBarController = self as? UITabBarController {
            return tabBarController.selectedViewController?.avs_visibleViewControllerIfExist()
        }

        if isViewLoaded, !view.isHidden, view.alpha > 0.01 {
            return self
        }
        return nil
    }
}

#endif
