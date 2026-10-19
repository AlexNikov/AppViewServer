#if SHOULD_COMPILE_APPVIEW_SERVER

import Dispatch
import Foundation

final class AppViewPTDispatchData: NSObject {
    let dispatchData: DispatchData

    init(dispatchData: DispatchData) {
        self.dispatchData = dispatchData
        super.init()
    }
}

#endif /* SHOULD_COMPILE_APPVIEW_SERVER */
