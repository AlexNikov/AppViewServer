import Foundation

public enum AppViewEventHandlerType: Int {
    case targetAction = 0
    case gesture = 1
}

public struct AppViewEventHandler {
    public var handlerType: AppViewEventHandlerType = .targetAction
    public var eventName: String?
    public var targetActions: [AppViewStringTwoTuple]?
    public var inheritedRecognizerName: String?
    public var gestureRecognizerIsEnabled: Bool = false
    public var gestureRecognizerDelegator: String?
    public var recognizerIvarTraces: [String]?
    public var recognizerOid: UInt64 = 0

    public init() {}
}
