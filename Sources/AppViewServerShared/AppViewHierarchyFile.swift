import Foundation

public struct AppViewHierarchyFile {
    public var serverVersion: Int32 = 0
    public var hierarchyInfo: AppViewHierarchyInfo?
    public var soloScreenshots: [NSNumber: Data]?
    public var groupScreenshots: [NSNumber: Data]?

    public init() {}

    public static func verify(_ hierarchyFile: AppViewHierarchyFile?) -> NSError? {
        guard let hierarchyFile else {
            return appviewInnerError()
        }

        if hierarchyFile.serverVersion < appviewSupportedServerMin {
            let fileVersion = hierarchyFile.serverVersion != 0 ? hierarchyFile.serverVersion : 6
            let detail = String(
                format: NSLocalizedString(
                    "The document was created by a AppView app with too old version. Current AppView app version is %@, but the document version is %@.",
                    comment: ""
                ),
                NSNumber(value: appviewClientVersion),
                NSNumber(value: fileVersion)
            )
            return NSError(
                domain: appviewErrorDomain,
                code: AppViewSharedErrCode.serverVersionTooLow.rawValue,
                userInfo: [
                    NSLocalizedDescriptionKey: NSLocalizedString("Failed to open the document.", comment: ""),
                    NSLocalizedRecoverySuggestionErrorKey: detail,
                ]
            )
        }

        if hierarchyFile.serverVersion > appviewSupportedServerMax {
            let detail = String(
                format: NSLocalizedString(
                    "Current AppView app is too old to open this document. Current AppView app version is %@, but the document version is %@.",
                    comment: ""
                ),
                NSNumber(value: appviewClientVersion),
                NSNumber(value: hierarchyFile.serverVersion)
            )
            return NSError(
                domain: appviewErrorDomain,
                code: AppViewSharedErrCode.serverVersionTooHigh.rawValue,
                userInfo: [
                    NSLocalizedDescriptionKey: NSLocalizedString("Failed to open the document.", comment: ""),
                    NSLocalizedRecoverySuggestionErrorKey: detail,
                ]
            )
        }

        return nil
    }
}
