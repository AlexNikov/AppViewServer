//
//  HorseLayer.swift
//  AppViewCustomInfoDemo
//
//  Maintained by Cursor Agent.
//

import UIKit

class HorseLayer: CALayer {
    /// Implement this method to expose custom properties in AppView
    /// Check whether a parent, child, or category already implements this method. To avoid conflicts, rename it to appview_customDebugInfos_0 (the trailing 0 may be 0–5).
    /// AppView calls this on every refresh; keep it fast to avoid slowing down inspection.
    ///
    /// Implement this method to display custom properties in AppView.
    /// Please note if this method has already been implemented by the superclass, subclass, or category. If so, to avoid conflicts, you can rename this method to appview_customDebugInfos_0 (the trailing number 0 can be replaced with any number from 0 to 5).
    /// This method is called every time AppView refreshes, so if this method takes a long time to execute, it will slow down the refresh speed.
    ///
    @objc func appview_customDebugInfos() -> [String:Any]? {
        let ret: [String:Any] = [
            // Optional. Shown in AppView's right-hand attribute panel.
            // Optional. These details will be displayed in the right-hand property panel of AppView.
            "properties": self.makeCustomProperties(),
            // Optional. Shown in AppView's left hierarchy panel.
            // Optional. This information will be displayed in the layer structure on the left side of AppView.
            "subviews": self.makeCustomSubviews(),
            // Optional. Display name for this view in the hierarchy tree.
            // Optional. The name of the view instance in the hierarchy panel on the left side of AppView.
            "title": "CustomHorseLayer"
        ]
        return ret
    }
    
    private func makeCustomProperties() -> [Any] {
        // See BirdView.swift for more property type examples.
        // See BirdView.swift for more examples
        var numberProperty: [String:Any] = [
            "section": "HorseInfo",
            "title": "Age",
            "value": 4.53,
            "valueType": "number"
        ]
        let numberSetter: @convention(block)(NSNumber) -> Void = { newNumber in
            print("Try to modify by AppView. \(newNumber.doubleValue)")
        }
        numberProperty["retainedSetter"] = unsafeBitCast(numberSetter, to: AnyObject.self)

        return [numberProperty]
    }
    
    func makeCustomSubviews() -> [Any] {
        let subview0: [String:Any] = [
            // Required. Element title shown in AppView.
            // Required. The name of the element displayed in AppView.
            "title": "Fake Horse Subview",
            // Optional. Element subtitle shown in AppView.
            // Optional. The subtitle of the element displayed in AppView.
            "subtitle": "GoodMorning",
            // Optional. When set, AppView draws an outline in the preview. Rect is window-relative, not parent-relative.
            // Optional. If this item is included, AppView will display a wireframe in the middle image area. The Rect here is relative to the current Window (not relative to the parent element).
            "frameInWindow": NSValue.init(cgRect: CGRect(x: 0, y: 0, width: 300, height: 500)),
            // Optional. Shown in the right panel; field format matches makeCustomProperties above.
            // Optional. This information will be displayed in the right-hand panel of AppView, with field formatting as described in the makeCustomProperties method above.
            "properties": [
                ["section":"Animal Info", "title":"Name", "value":"Mary", "valueType":"string"],
                ["section":"Animal Info", "title":"Age", "value":3.2, "valueType":"number"]
            ]
        ]
        
        let subview1: [String:Any] = [
            "title": "Horse ViewModel",
            // Optional. Recursively add virtual subviews.
            // Optional. You can recursively add your virtual subview.
            "subviews": [
                ["title": "ViewModel1"],
                ["title": "ViewModel2"]
            ]
        ]
        
        return [subview0, subview1]
    }
}
