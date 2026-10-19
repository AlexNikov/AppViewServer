import Foundation

@_silgen_name("AppViewCatchObjCException")
private func appviewCatchObjCException(
    _ tryBlock: (@convention(block) () -> Void)?,
    _ exceptionOut: UnsafeMutablePointer<NSException?>?
)

/// Swift API for ObjC `@try/@catch` around inspect paths that may raise `NSException`.
public enum AppViewObjCExceptionBridge {

    /// Runs `body` and returns a caught `NSException`, if any.
    public static func catchException(_ body: @escaping () -> Void) -> NSException? {
        var exception: NSException?
        appviewCatchObjCException(body, &exception)
        return exception
    }

    /// Runs `body`; on `NSException` throws `NSError` in `AppViewErrorDomain` with code -502.
    public static func tryExecute(_ body: @escaping () -> Void) throws {
        guard let exception = catchException(body) else { return }
        throw appviewObjCExceptionError(reason: exception.reason)
    }

    private static func appviewObjCExceptionError(reason: String?) -> NSError {
        NSError(
            domain: AppViewErrorDomain,
            code: AppViewSharedErrCode.exception.rawValue,
            userInfo: [
                NSLocalizedDescriptionKey: NSLocalizedString("The modification may failed.", comment: ""),
                NSLocalizedRecoverySuggestionErrorKey: reason ?? "",
            ]
        )
    }
}
