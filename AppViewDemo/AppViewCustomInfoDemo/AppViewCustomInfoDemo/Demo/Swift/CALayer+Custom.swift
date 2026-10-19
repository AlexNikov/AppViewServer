//
//  CALayer+Custom.swift
//  AppViewCustomInfoDemo
//
//  Maintained by Cursor Agent.
//

import UIKit

extension CALayer {
    /// Implement this method to expose custom properties in AppView
    /// Check whether a parent, child, or category already implements this method. To avoid conflicts, rename it to appview_customDebugInfos_0 (the trailing 0 may be 0–5).
    /// AppView calls this on every refresh; keep it fast to avoid slowing down inspection.
    ///
    /// Implement this method to display custom properties in AppView.
    /// Please note if this method has already been implemented by the superclass, subclass, or category. If so, to avoid conflicts, you can rename this method to appview_customDebugInfos_0 (the trailing number 0 can be replaced with any number from 0 to 5).
    /// This method is called every time AppView refreshes, so if this method takes a long time to execute, it will slow down the refresh speed.
    ///
    @objc func appview_customDebugInfos_1() -> [String:Any]? {
        let ret: [String:Any] = [
            "properties": self.cusotm_makeCustomProperties()
        ]
        return ret
    }
    
    private func cusotm_makeCustomProperties() -> [Any] {
        let stringProperty: [String:Any] = [
            "section": "Life Style",
            "title": "Hobby",
            "value": "Bike",
            "valueType": "string"
        ]
        
        return [stringProperty]
    }
}
