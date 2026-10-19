#if canImport(AppViewShared)
import AppViewShared
#endif
#if SHOULD_COMPILE_APPVIEW_SERVER

import Foundation

extension Notification.Name {
    static let appview2D = Notification.Name("AppView_2D")
    static let appview3D = Notification.Name("AppView_3D")
    static let appviewExport = Notification.Name("AppView_Export")
    static let appviewRelationSearch = Notification.Name("AppView_RelationSearch")
    static let getAppViewInfo = Notification.Name("GetAppViewInfo")
    static let appviewWillExport = Notification.Name("AppView_WillExport")
    static let appviewDidFinishExport = Notification.Name("AppView_DidFinishExport")
}

#endif
