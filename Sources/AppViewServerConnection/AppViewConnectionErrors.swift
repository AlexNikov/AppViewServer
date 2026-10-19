#if canImport(AppViewShared)
import AppViewShared
#endif
#if SHOULD_COMPILE_APPVIEW_SERVER

import Foundation

public enum AppViewConnectionError: Error {
    case inner
    case objectNotFound
    case custom(title: String, detail: String = "")
}

extension AppViewConnectionError {
    var nsError: NSError {
        switch self {
        case .inner:
            return NSError(
                domain: AppViewErrorDomain,
                code: Int(AppViewErrCode_Inner),
                userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("The operation failed due to an inner error.", comment: "")]
            )
        case .objectNotFound:
            return NSError(
                domain: AppViewErrorDomain,
                code: Int(AppViewErrCode_ObjectNotFound),
                userInfo: [
                    NSLocalizedDescriptionKey: NSLocalizedString("Failed to get target object in iOS app", comment: ""),
                    NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("Perhaps the related object was deallocated. You can reload AppView to get newest data.", comment: ""),
                ]
            )
        case .custom(let title, let detail):
            return NSError(
                domain: AppViewErrorDomain,
                code: Int(AppViewErrCode_Default),
                userInfo: [
                    NSLocalizedDescriptionKey: title,
                    NSLocalizedRecoverySuggestionErrorKey: detail,
                ]
            )
        }
    }
}

enum AppViewConnectionErrors {
    static var inner: NSError { AppViewConnectionError.inner.nsError }
    static var objectNotFound: NSError { AppViewConnectionError.objectNotFound.nsError }
    static func make(title: String, detail: String = "") -> NSError {
        AppViewConnectionError.custom(title: title, detail: detail).nsError
    }
}

#endif
