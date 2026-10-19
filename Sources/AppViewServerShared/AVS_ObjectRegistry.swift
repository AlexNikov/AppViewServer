import Foundation

@objc(AVS_ObjectRegistry)
public final class AVS_ObjectRegistry: NSObject {
    @objc public static let sharedInstance: AVS_ObjectRegistry = AVS_ObjectRegistry()

    private let data: NSPointerArray

    private override init() {
        data = NSPointerArray.weakObjects()
        super.init()
        data.count = 1
    }

    @objc public func addObject(_ object: NSObject?) -> UInt {
        guard let object = object else { return 0 }
        data.addPointer(Unmanaged.passUnretained(object).toOpaque())
        return UInt(data.count - 1)
    }

    @objc public func objectWithOid(_ oid: UInt) -> NSObject? {
        guard data.count > Int(oid) else { return nil }
        guard let pointer = data.pointer(at: Int(oid)) else { return nil }
        return Unmanaged<NSObject>.fromOpaque(pointer).takeUnretainedValue()
    }
}
