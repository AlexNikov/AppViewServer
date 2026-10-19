#if canImport(AppViewShared)
import AppViewShared
#endif
#if SHOULD_COMPILE_APPVIEW_SERVER

import Foundation
import ObjectiveC
import UIKit

@_silgen_name("AppViewObjectGetIvarSELName")
private func appviewObjectGetIvarSELName(_ object: AnyObject, _ ivar: Ivar) -> UnsafePointer<CChar>?

@objc(AVS_GestureTargetActionsSearcher)
public final class AVS_GestureTargetActionsSearcher: NSObject {

    public static func getTargetActions(from recognizer: UIGestureRecognizer?) -> [AppViewTwoTuple] {
        guard let recognizer else { return [] }

        var result: [AppViewTwoTuple] = []
        let exception = AppViewObjCExceptionBridge.catchException {
            guard let targetsList = recognizer.value(forKey: "_targets") as? [AnyObject],
                  !targetsList.isEmpty else {
                return
            }

            result = targetsList.appview_map { _, targetBox in
                guard let targetObj = targetBox.value(forKey: "_target") else {
                    return nil
                }

                let actionString: String
                if let actionIvar = class_getInstanceVariable(object_getClass(targetBox), "_action"),
                   let actionNamePtr = appviewObjectGetIvarSELName(targetBox, actionIvar) {
                    let actionName = String(cString: actionNamePtr)
                    actionString = actionName.isEmpty ? "NULL" : actionName
                } else {
                    actionString = "NULL"
                }

                let tuple = AppViewTwoTuple()
                tuple.first = AppViewWeakContainer.container(with: targetObj)
                tuple.second = actionString as NSString
                return tuple
            }
        }

        if exception != nil {
            return []
        }
        return result
    }
}

#endif
