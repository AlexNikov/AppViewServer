import Foundation
#if canImport(UIKit)
import UIKit
#if canImport(AppViewShared)
import AppViewShared
#endif
#endif

#if os(iOS) || os(tvOS) || os(visionOS)

extension AppViewObject {
    @objc(instanceWithObject:)
    public class func instance(with object: NSObject) -> AppViewObject {
        let appviewObj = AppViewObject()
        appviewObj.oid = object.avs_registerOid()
        appviewObj.memoryAddress = String(format: "%p", object)
        appviewObj.classChainList = object.avs_classChainList()
        appviewObj.specialTrace = object.avs_specialTrace
        appviewObj.ivarTraces = object.avs_ivarTraces
        return appviewObj
    }
}

#endif
