#if SHOULD_COMPILE_APPVIEW_SERVER

import Dispatch
import Foundation

@objc(AppView_PTData)
public class AppViewPTData: NSObject {
    @objc public private(set) var dispatchData: dispatch_data_t?
    @objc public private(set) var data: UnsafeMutableRawPointer?
    @objc public private(set) var length: Int = 0
    /// Stable copy of frame bytes (Peertalk buffer pointer is only valid during the read callback).
    private var retainedBytes: Data?

    @objc(initWithMappedDispatchData:data:length:)
    public init(mappedDispatchData: dispatch_data_t?, data: UnsafeMutableRawPointer?, length: Int) {
        dispatchData = mappedDispatchData
        self.data = data
        self.length = length
        if let mappedDispatchData, let dispatchData = appviewDispatchData(from: mappedDispatchData) {
            retainedBytes = dispatchData.appviewCopyBytes()
        } else if length > 0, let data {
            retainedBytes = Data(bytes: data, count: length)
        }
        super.init()
    }

    /// Bytes received for this Peertalk frame.
    @objc public func appviewPayloadBytes() -> Data {
        if let retainedBytes, !retainedBytes.isEmpty {
            return retainedBytes
        }
        if let dispatchData, let dispatchData = appviewDispatchData(from: dispatchData) {
            return dispatchData.appviewCopyBytes()
        }
        if length > 0, let data {
            return Data(bytes: data, count: length)
        }
        return Data()
    }

    public override var description: String {
        String(format: "<AppView_PTData: %p (%zu bytes)>", self, length)
    }
}

#endif /* SHOULD_COMPILE_APPVIEW_SERVER */
