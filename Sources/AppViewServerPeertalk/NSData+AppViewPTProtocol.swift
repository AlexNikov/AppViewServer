#if SHOULD_COMPILE_APPVIEW_SERVER

import Dispatch
import Foundation
import ObjectiveC

private var appviewPTDispatchDataRefKey: UInt8 = 0

extension NSData {
    @objc(createReferencingDispatchData)
    public func createReferencingDispatchData() -> dispatch_data_t {
        DispatchData(bytes: UnsafeRawBufferPointer(start: bytes, count: length)).appviewDispatchDataRef
    }
}

extension NSData {
    @objc(dataWithContentsOfDispatchData:)
    public static func data(withContentsOf dispatchDataRef: dispatch_data_t?) -> NSData? {
        guard let dispatchData = appviewDispatchData(from: dispatchDataRef) else { return nil }

        let copied = dispatchData.appviewCopyBytes()
        let ref = AppViewPTDispatchData(dispatchData: dispatchData)
        let newData = NSData(data: copied)
        objc_setAssociatedObject(newData, &appviewPTDispatchDataRefKey, ref, .OBJC_ASSOCIATION_RETAIN)
        return newData
    }
}

#endif /* SHOULD_COMPILE_APPVIEW_SERVER */
