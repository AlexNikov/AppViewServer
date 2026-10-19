#if canImport(AppViewShared)
import AppViewShared
#endif
#if SHOULD_COMPILE_APPVIEW_SERVER

import Foundation

extension NSObject {
    public func avs_registerOid() -> UInt {
        if avs_oid == 0 {
            let oid = AVS_ObjectRegistry.sharedInstance.addObject(self)
            avs_oid = oid
        }
        return avs_oid
    }

    var avs_oid: UInt {
        get {
            let number = appview_getBindObject(forKey: "avs_oid") as? NSNumber
            return number?.uintValue ?? 0
        }
        set {
            appview_bindObject(NSNumber(value: newValue), forKey: "avs_oid")
        }
    }

    public static func avs_object(withOid oid: UInt) -> NSObject? {
        AVS_ObjectRegistry.sharedInstance.objectWithOid(oid)
    }

    public var avs_ivarTraces: [AppViewIvarTrace]? {
        get { appview_getBindObject(forKey: "avs_ivarTraces") as? [AppViewIvarTrace] }
        set {
            appview_bindObject(newValue, forKey: "avs_ivarTraces")
            if newValue != nil {
                Self.allObjectsWithTraces().addPointer(Unmanaged.passUnretained(self).toOpaque())
            }
        }
    }

    public var avs_specialTrace: String? {
        get { appview_getBindObject(forKey: "avs_specialTrace") as? String }
        set {
            appview_bindObject(newValue, forKey: "avs_specialTrace")
            if newValue != nil {
                Self.allObjectsWithTraces().addPointer(Unmanaged.passUnretained(self).toOpaque())
            }
        }
    }

    public static func avs_clearAllObjectsTraces() {
        for case let obj as NSObject in allObjectsWithTraces().allObjects {
            obj.avs_ivarTraces = nil
            obj.avs_specialTrace = nil
        }
        allObjectsWithTraces().compact()
    }

    private static func allObjectsWithTraces() -> NSPointerArray {
        enum Storage {
            static let array: NSPointerArray = {
                NSPointerArray.weakObjects()
            }()
        }
        return Storage.array
    }

    public func avs_classChainList() -> [String] {
        var classChainList: [String] = []
        var currentClass: AnyClass? = type(of: self)
        while let cls = currentClass {
            classChainList.append(NSStringFromClass(cls))
            currentClass = class_getSuperclass(cls)
        }
        return classChainList
    }
}

#endif
