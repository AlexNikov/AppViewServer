import Foundation

public class AppViewObject: NSObject, NSCopying {
    public var oid: UInt = 0
    public var memoryAddress: String?
    public var classChainList: [String]?
    public var specialTrace: String?
    public var ivarTraces: [AppViewIvarTrace]?

    public override init() {
        super.init()
    }

    public func rawClassName() -> String? {
        classChainList?.first
    }

    public func duplicate() -> AppViewObject {
        let copy = AppViewObject()
        copy.oid = oid
        copy.memoryAddress = memoryAddress
        copy.classChainList = classChainList
        copy.specialTrace = specialTrace
        copy.ivarTraces = ivarTraces
        return copy
    }

    // MARK: - NSCopying

    public func copy(with zone: NSZone? = nil) -> Any {
        duplicate()
    }

}
