import Foundation

public struct AppViewConnectionResponseAttachment {
    public var dataType: AppViewCodingValueType = .unknown
    public var data: Any?
    public var appviewServerVersion: Int32 = appviewServerVersionInt32
    public var error: NSError?
    public var appIsInBackground: Bool = false
    public var dataTotalCount: UInt = 0
    public var currentDataCount: UInt = 0

    public init() {}

    public static func attachment(with error: NSError?) -> AppViewConnectionResponseAttachment {
        var attachment = AppViewConnectionResponseAttachment()
        attachment.error = error
        return attachment
    }
}
