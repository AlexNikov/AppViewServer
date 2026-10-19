//
//  AppViewDemoObjCBorder.m
//  AppViewDemo
//

#import "AppViewDemoObjCBorder.h"
#import <objc/runtime.h>

void AppViewDemoApplyObjCRootViewGreenBorder(UIView *view) {
    if (!view) {
        return;
    }
    view.layer.borderWidth = 4;
}

static UIViewController *AppViewDemoVisibleRootViewController(UIWindow *window) {
    UIViewController *vc = window.rootViewController;
    while (vc.presentedViewController) {
        vc = vc.presentedViewController;
    }
    if ([vc isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nav = (UINavigationController *)vc;
        return nav.visibleViewController ?: nav;
    }
    if ([vc isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tab = (UITabBarController *)vc;
        vc = tab.selectedViewController;
        if ([vc isKindOfClass:[UINavigationController class]]) {
            UINavigationController *nav = (UINavigationController *)vc;
            return nav.visibleViewController ?: nav;
        }
        return vc;
    }
    return vc;
}

@implementation UIViewController (AppViewDemoObjCBorder)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class cls = [UIViewController class];
        SEL originalSEL = @selector(viewDidAppear:);
        SEL swizzledSEL = @selector(appview_demoObjCBorder_viewDidAppear:);
        Method originalMethod = class_getInstanceMethod(cls, originalSEL);
        Method swizzledMethod = class_getInstanceMethod(cls, swizzledSEL);
        if (originalMethod && swizzledMethod) {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

- (void)appview_demoObjCBorder_viewDidAppear:(BOOL)animated {
    [self appview_demoObjCBorder_viewDidAppear:animated];
    UIWindow *window = self.viewIfLoaded.window;
    if (!window) {
        return;
    }
    if (AppViewDemoVisibleRootViewController(window) != self) {
        return;
    }
    AppViewDemoApplyObjCRootViewGreenBorder(self.view);
}

@end
