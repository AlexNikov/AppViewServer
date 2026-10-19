#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#if !defined(APPVIEW_SERVER_SHARED_MODULE) && TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#import <dlfcn.h>

/// Same role as Lookin `LKS_ConnectionManager +load`: the pod image starts the server
/// before `main`, with no call from the host app. Swift is invoked on the next main-queue
/// turn so the Swift runtime is already initialized.
static void AVS_InvokeServerBootstrap(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            void (*start)(void) = dlsym(RTLD_DEFAULT, "appview_server_bootstrap");
            if (start != NULL) {
                start();
            }
        });
    });
}

/// The Auto Layout engine reports a conflict once, on the layout pass that breaks it. That pass can run before
/// the deferred server bootstrap, so the engine callback is hooked here in `+load`. Recording goes to Swift
/// (`appview_server_record_layout_conflict`), resolved on first use: by then the Swift runtime is up.
static IMP AVS_OriginalWillBreakConstraintIMP = NULL;
static void (*AVS_RecordLayoutConflict)(id, id) = NULL;
static bool AVS_LayoutConflictHookInstalled = false;

static void AVS_WillBreakConstraint(id receiver, SEL cmd, id engine, id broken, id others) {
    if (AVS_RecordLayoutConflict == NULL) {
        AVS_RecordLayoutConflict = (void (*)(id, id))dlsym(RTLD_DEFAULT, "appview_server_record_layout_conflict");
    }
    if (AVS_RecordLayoutConflict != NULL && broken != nil) {
        AVS_RecordLayoutConflict(broken, others);
    }
    if (AVS_OriginalWillBreakConstraintIMP != NULL) {
        ((void (*)(id, SEL, id, id, id))AVS_OriginalWillBreakConstraintIMP)(receiver, cmd, engine, broken, others);
    }
}

static void AVS_InstallLayoutConflictHook(void) {
    SEL selector = NSSelectorFromString(@"engine:willBreakConstraint:dueToMutuallyExclusiveConstraints:");
    Method method = class_getInstanceMethod([UIView class], selector);
    if (method == NULL || method_getNumberOfArguments(method) != 5) {
        return;
    }
    char returnType[2] = {0};
    method_getReturnType(method, returnType, sizeof(returnType));
    if (returnType[0] != 'v') {
        return;
    }
    AVS_OriginalWillBreakConstraintIMP = method_setImplementation(method, (IMP)AVS_WillBreakConstraint);
    AVS_LayoutConflictHookInstalled = true;
}

bool AppViewLayoutConflictHookInstalled(void) {
    return AVS_LayoutConflictHookInstalled;
}

@interface AVS_ConnectionLoadHook : NSObject
@end

@implementation AVS_ConnectionLoadHook

+ (void)load {
    AVS_InstallLayoutConflictHook();
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserverForName:UIApplicationDidBecomeActiveNotification
                        object:nil
                         queue:nil
                    usingBlock:^(__unused NSNotification *note) {
        AVS_InvokeServerBootstrap();
    }];
    if (@available(iOS 13.0, tvOS 13.0, *)) {
        [center addObserverForName:UISceneDidActivateNotification
                            object:nil
                             queue:nil
                        usingBlock:^(__unused NSNotification *note) {
            AVS_InvokeServerBootstrap();
        }];
    }
    AVS_InvokeServerBootstrap();
}

@end
#endif

void AppViewCatchObjCException(void (NS_NOESCAPE ^ _Nullable tryBlock)(void),
                              NSException * _Nullable * _Nullable exceptionOut) {
    @try {
        if (tryBlock) {
            tryBlock();
        }
        if (exceptionOut) {
            *exceptionOut = nil;
        }
    } @catch (NSException *exception) {
        if (exceptionOut) {
            *exceptionOut = exception;
        }
    }
}

const char *AppViewObjectGetIvarSELName(id object, Ivar ivar) {
    SEL action = ((SEL (*)(id, Ivar))object_getIvar)(object, ivar);
    if (action == NULL) {
        return NULL;
    }
    return sel_getName(action);
}
