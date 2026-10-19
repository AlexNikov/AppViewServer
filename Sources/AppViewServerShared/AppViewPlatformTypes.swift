import CoreGraphics
import Foundation

#if canImport(UIKit)
import UIKit

public typealias AppViewColor = UIColor
public typealias AppViewInsets = UIEdgeInsets
public typealias AppViewImage = UIImage
#elseif canImport(AppKit)
import AppKit

public typealias AppViewColor = NSColor
public typealias AppViewInsets = NSEdgeInsets
public typealias AppViewImage = NSImage
#endif

extension AppViewColor {
    @objc(appview_colorFromRGBAComponents:)
    public static func appview_color(fromRGBAComponents rgba: [NSNumber]) -> AppViewColor? {
        guard rgba.count >= 4 else { return nil }
        return AppViewColor(
            red: rgba[0].doubleValue,
            green: rgba[1].doubleValue,
            blue: rgba[2].doubleValue,
            alpha: rgba[3].doubleValue
        )
    }

    @objc(appview_rgbaComponents)
    public var appview_rgbaComponents: [NSNumber] {
        #if canImport(UIKit)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        var white: CGFloat = 0
        if getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return [NSNumber(value: red), NSNumber(value: green), NSNumber(value: blue), NSNumber(value: alpha)]
        }
        if getWhite(&white, alpha: &alpha) {
            return [NSNumber(value: white), NSNumber(value: white), NSNumber(value: white), NSNumber(value: alpha)]
        }
        return []
        #elseif canImport(AppKit)
        let rgbColor = usingColorSpace(.sRGB) ?? self
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        rgbColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return [NSNumber(value: red), NSNumber(value: green), NSNumber(value: blue), NSNumber(value: alpha)]
        #else
        return []
        #endif
    }
}

extension AppViewImage {
    func appview_pngData() -> Data? {
        #if canImport(UIKit)
        return (self as UIImage).pngData()
        #elseif canImport(AppKit)
        guard let tiff = tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
        #else
        return nil
        #endif
    }

    static func appview_image(with data: Data) -> AppViewImage? {
        #if canImport(UIKit)
        return UIImage(data: data)
        #elseif canImport(AppKit)
        return NSImage(data: data)
        #else
        return nil
        #endif
    }
}

// APPVIEW_MAC_CLIENT: Cross-platform CGRect on the wire (iOS server → mac AppViewShared decode).
// Keep encode/decode symmetric; see MacAppViewClientCompatibility.md.
enum AppViewGeometryCoding {
    static func nsValue(from point: CGPoint) -> NSValue {
        #if canImport(UIKit)
        return NSValue(cgPoint: point)
        #else
        return NSValue(point: point)
        #endif
    }

    static func point(from value: NSValue) -> CGPoint {
        #if canImport(UIKit)
        return value.cgPointValue
        #else
        return value.pointValue
        #endif
    }

    static func nsValue(from rect: CGRect) -> NSValue {
        #if canImport(UIKit)
        return NSValue(cgRect: rect)
        #else
        return NSValue(rect: rect)
        #endif
    }

    static func rect(from value: NSValue) -> CGRect {
        #if canImport(UIKit)
        return value.cgRectValue
        #else
        return value.rectValue
        #endif
    }

    /// APPVIEW_MAC_CLIENT / QMUI ObjC: iOS uses keyed `encode(CGRect)` (same as QMUI `encodeCGRect:forKey:`).
    /// Decode still accepts NSValue and platform CGRect/Rect fallbacks.
    static func encodeCGRect(_ rect: CGRect, coder: NSCoder, forKey key: String) {
        #if canImport(UIKit)
        coder.encode(rect, forKey: key)
        #else
        coder.encode(nsValue(from: rect), forKey: key)
        #endif
    }

    /// APPVIEW_MAC_CLIENT: Accept NSValue (preferred), then platform `CGRect`/`Rect` keyed encoding.
    static func decodeCGRect(_ coder: NSCoder, forKey key: String) -> CGRect {
        if let value = coder.decodeObject(of: NSValue.self, forKey: key) {
            return rect(from: value)
        }
        #if canImport(UIKit)
        if coder.containsValue(forKey: key) {
            return coder.decodeCGRect(forKey: key)
        }
        #else
        if coder.containsValue(forKey: key) {
            return coder.decodeRect(forKey: key)
        }
        #endif
        return .zero
    }
}
