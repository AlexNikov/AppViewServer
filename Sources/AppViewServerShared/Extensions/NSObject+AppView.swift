import Foundation
import ObjectiveC
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

private final class AppViewWeakBox: NSObject {
    weak var object: AnyObject?
}

extension NSObject {
    private static var bindObjectsKey: UInt8 = 0

    private var appview_allBindObjects: NSMutableDictionary {
        if let dict = objc_getAssociatedObject(self, &Self.bindObjectsKey) as? NSMutableDictionary {
            return dict
        }
        let dict = NSMutableDictionary()
        objc_setAssociatedObject(self, &Self.bindObjectsKey, dict, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return dict
    }

    @objc(appview_bindObject:forKey:)
    public func appview_bindObject(_ object: Any?, forKey key: String) {
        guard !key.isEmpty else { return }
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        if let object {
            appview_allBindObjects[key] = object
        } else {
            appview_allBindObjects.removeObject(forKey: key)
        }
    }

    @objc(appview_bindObjectWeakly:forKey:)
    public func appview_bindObjectWeakly(_ object: AnyObject?, forKey key: String) {
        guard !key.isEmpty else { return }
        if let object {
            let box = AppViewWeakBox()
            box.object = object
            appview_bindObject(box, forKey: key)
        } else {
            appview_bindObject(nil, forKey: key)
        }
    }

    @objc(appview_getBindObjectForKey:)
    public func appview_getBindObject(forKey key: String) -> Any? {
        guard !key.isEmpty else { return nil }
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        let stored = appview_allBindObjects[key]
        if let box = stored as? AppViewWeakBox {
            return box.object
        }
        return stored
    }

    @objc(appview_clearBindForKey:)
    public func appview_clearBind(forKey key: String) {
        appview_bindObject(nil, forKey: key)
    }

    @objc(appview_bindDouble:forKey:)
    public func appview_bindDouble(_ doubleValue: Double, forKey key: String) {
        appview_bindObject(NSNumber(value: doubleValue), forKey: key)
    }

    @objc(appview_getBindDoubleForKey:)
    public func appview_getBindDouble(forKey key: String) -> Double {
        (appview_getBindObject(forKey: key) as? NSNumber)?.doubleValue ?? 0
    }

    @objc(appview_bindBOOL:forKey:)
    public func appview_bindBOOL(_ boolValue: Bool, forKey key: String) {
        appview_bindObject(NSNumber(value: boolValue), forKey: key)
    }

    @objc(appview_getBindBOOLForKey:)
    public func appview_getBindBOOL(forKey key: String) -> Bool {
        (appview_getBindObject(forKey: key) as? NSNumber)?.boolValue ?? false
    }

    @objc(appview_bindLong:forKey:)
    public func appview_bindLong(_ longValue: Int, forKey key: String) {
        appview_bindObject(NSNumber(value: longValue), forKey: key)
    }

    @objc(appview_getBindLongForKey:)
    public func appview_getBindLong(forKey key: String) -> Int {
        (appview_getBindObject(forKey: key) as? NSNumber)?.intValue ?? 0
    }

    @objc(appview_bindPoint:forKey:)
    public func appview_bindPoint(_ pointValue: CGPoint, forKey key: String) {
        appview_bindObject(AppViewGeometryCoding.nsValue(from: pointValue), forKey: key)
    }

    @objc(appview_getBindPointForKey:)
    public func appview_getBindPoint(forKey key: String) -> CGPoint {
        guard let value = appview_getBindObject(forKey: key) as? NSValue else { return .zero }
        return AppViewGeometryCoding.point(from: value)
    }

    public func appview_encodedObject(with type: AppViewCodingValueType) -> Any? {
        switch type {
        case .color:
            guard let color = self as? AppViewColor else { return nil }
            return color.appview_rgbaComponents
        case .image:
            if let image = self as? AppViewImage {
                return image.appview_pngData()
            }
            return nil
        default:
            return self
        }
    }

    public func appview_decodedObject(with type: AppViewCodingValueType) -> Any? {
        switch type {
        case .color:
            if let rgba = self as? [NSNumber] {
                return AppViewColor.appview_color(fromRGBAComponents: rgba)
            }
            return nil
        case .image:
            if let data = self as? Data {
                return AppViewImage.appview_image(with: data)
            }
            return nil
        default:
            return self
        }
    }
}
