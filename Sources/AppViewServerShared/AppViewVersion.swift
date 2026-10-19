import Foundation

public let appviewServerVersion = 7
public let appviewServerReadableVersion = "1.2.8"
public let appviewClientVersion = 7
public let appviewSupportedServerMin = 7
public let appviewSupportedServerMax = 7
public let appviewServerVersionInt32: Int32 = 7
public let appviewStringFlagVoidReturn = "APPVIEW_TAG_RETURN_VALUE_VOID"

public let appviewErrorDomain = "AppViewError"

@objc public enum AppViewSharedErrCode: Int {
    case `default` = -400
    case inner = -401
    case peerTalk = -402
    case noConnect = -403
    case pingFailForTimeout = -404
    case timeout = -405
    case discard = -406
    case pingFailForBackgroundState = -407
    case objectNotFound = -500
    case modifyValueTypeInvalid = -501
    case exception = -502
    case serverVersionTooHigh = -600
    case serverVersionTooLow = -601
    case unsupportedFileType = -700
}

public func appviewInnerError() -> NSError {
    NSError(
        domain: appviewErrorDomain,
        code: AppViewSharedErrCode.inner.rawValue,
        userInfo: [
            NSLocalizedDescriptionKey: NSLocalizedString(
                "The operation failed due to an inner error.",
                comment: ""
            ),
        ]
    )
}

public func appviewErrObjNotFound() -> NSError {
    NSError(
        domain: appviewErrorDomain,
        code: AppViewSharedErrCode.objectNotFound.rawValue,
        userInfo: [
            NSLocalizedDescriptionKey: NSLocalizedString(
                "Failed to get target object in iOS app",
                comment: ""
            ),
            NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(
                "Perhaps the related object was deallocated. You can reload AppView to get newest data.",
                comment: ""
            ),
        ]
    )
}

public func appviewErrorMake(title: String, detail: String = "") -> NSError {
    NSError(
        domain: appviewErrorDomain,
        code: AppViewSharedErrCode.default.rawValue,
        userInfo: [
            NSLocalizedDescriptionKey: title,
            NSLocalizedRecoverySuggestionErrorKey: detail,
        ]
    )
}

public func appviewExceptionError(recoverySuggestion: String) -> NSError {
    NSError(
        domain: appviewErrorDomain,
        code: AppViewSharedErrCode.exception.rawValue,
        userInfo: [
            NSLocalizedDescriptionKey: NSLocalizedString("The modification may failed.", comment: ""),
            NSLocalizedRecoverySuggestionErrorKey: recoverySuggestion,
        ]
    )
}
