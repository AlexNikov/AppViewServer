#if SHOULD_COMPILE_APPVIEW_SERVER

import Darwin
import Dispatch
import Foundation

enum AppViewPTByteOrder {
    static func htonl(_ value: UInt32) -> UInt32 { value.bigEndian }
    static func htons(_ value: UInt16) -> UInt16 { value.bigEndian }
}

extension DispatchData {
    func appviewCopyBytes() -> Data {
        Data(self)
    }

    var appviewDispatchDataRef: dispatch_data_t {
        self as __DispatchData
    }
}

func appviewDispatchData(from ref: dispatch_data_t?) -> DispatchData? {
    guard let ref else { return nil }
    return ref as DispatchData
}

#endif /* SHOULD_COMPILE_APPVIEW_SERVER */
