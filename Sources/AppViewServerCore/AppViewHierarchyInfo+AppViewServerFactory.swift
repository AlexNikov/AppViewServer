import Foundation
#if canImport(AppViewShared)
import AppViewShared
#endif

#if os(iOS) || os(tvOS) || os(visionOS)

extension AVHierarchyInfo {
    @objc(staticInfoWithAppViewVersion:)
    public class func staticInfo(withAppViewVersion version: String?) -> AVHierarchyInfo {
        staticInfo(withAppViewVersion: version, scanLayoutIssues: false)
    }

    /// `scanLayoutIssues` runs the ambiguous-layout scan first (first connect, Reload). Otherwise the previous
    /// scan cache is reused and `hasAmbiguousLayout` is not called.
    public class func staticInfo(withAppViewVersion version: String?, scanLayoutIssues: Bool) -> AVHierarchyInfo {
        var readCustomInfo = false
        if let version, version.appview_numbericOSVersion() >= 10004 {
            readCustomInfo = true
        }

        AVS_CustomAttrSetterManager.sharedInstance().removeAll()

        let info = AVHierarchyInfo()
        info.serverVersion = appviewServerVersionInt32
        // With `scanLayoutIssues` the ambiguous-layout probe runs inside this walk, not as a separate pass.
        info.displayItems = AVS_HierarchyDisplayItemsMaker.items(
            withScreenshots: false,
            attrList: false,
            lowImageQuality: false,
            readCustomInfo: readCustomInfo,
            saveCustomSetter: true,
            scanLayoutIssues: scanLayoutIssues
        )
        info.appInfo = AVAppInfo.currentInfo(withScreenshot: false, icon: true, localIdentifiers: nil)
        info.collapsedClassList = AVSConfigManager.collapsedClassList()
        info.colorAlias = AVSConfigManager.colorAlias() as? [String: Any]
        return info
    }

    @objc(exportedInfo)
    public class func exportedInfo() -> AVHierarchyInfo {
        let info = AVHierarchyInfo()
        info.serverVersion = appviewServerVersionInt32
        info.displayItems = AVS_HierarchyDisplayItemsMaker.items(
            withScreenshots: true,
            attrList: true,
            lowImageQuality: true,
            readCustomInfo: true,
            saveCustomSetter: false
        )
        info.appInfo = AVAppInfo.currentInfo(withScreenshot: false, icon: true, localIdentifiers: nil)
        info.collapsedClassList = AVSConfigManager.collapsedClassList()
        info.colorAlias = AVSConfigManager.colorAlias() as? [String: Any]
        return info
    }
}

#endif
