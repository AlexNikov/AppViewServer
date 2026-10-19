#if canImport(AppViewShared)
import AppViewShared
#endif
#if SHOULD_COMPILE_APPVIEW_SERVER

import Foundation

public enum AVS_InbuiltAttrModificationHandler {

    public static func handleModification(
        _ modification: AppViewAttributeModification?
    ) async throws -> AppViewDisplayItemDetail {
        guard let modification else {
            throw AppViewConnectionErrors.inner
        }
        return try await AVS_ConnectionRuntimeBridge.handleInbuiltAttrModification(modification)
    }
}

#endif
