import Foundation
import CoreGraphics

public enum AppViewStaticAsyncUpdateTaskType: Int {
    case noScreenshot = 0
    case soloScreenshot = 1
    case groupScreenshot = 2
}

public enum AppViewDetailUpdateTaskAttrRequest: Int {
    case automatic = 0
    case need = 1
    case notNeed = 2
}

public struct AppViewStaticAsyncUpdateTask: Hashable {
    public var oid: UInt = 0
    public var taskType: AppViewStaticAsyncUpdateTaskType = .noScreenshot
    public var attrRequest: AppViewDetailUpdateTaskAttrRequest = .automatic
    public var needBasisVisualInfo: Bool = false
    public var needSubitems: Bool = false
    public var clientReadableVersion: String?
    public var frameSize: CGSize = .zero

    public init() {}

    public func hash(into hasher: inout Hasher) {
        hasher.combine(oid)
        hasher.combine(taskType.rawValue)
        hasher.combine(attrRequest.rawValue)
        hasher.combine(needBasisVisualInfo)
        hasher.combine(needSubitems)
    }

    public static func == (lhs: AppViewStaticAsyncUpdateTask, rhs: AppViewStaticAsyncUpdateTask) -> Bool {
        lhs.oid == rhs.oid
            && lhs.taskType == rhs.taskType
            && lhs.attrRequest == rhs.attrRequest
            && lhs.needBasisVisualInfo == rhs.needBasisVisualInfo
            && lhs.needSubitems == rhs.needSubitems
    }
}

public struct AppViewStaticAsyncUpdateTasksPackage {
    public var tasks: [AppViewStaticAsyncUpdateTask]?

    public init() {}
}
