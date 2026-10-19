#if canImport(AppViewShared)
import AppViewShared
#endif
#if SHOULD_COMPILE_APPVIEW_SERVER

import UIKit

extension UIColor {
    @objc(avs_rgbaComponents)
    public func avs_rgbaComponents() -> [NSNumber] {
        let cgColor = cgColor
        let components = cgColor.components ?? []
        let count = cgColor.numberOfComponents
        let r: CGFloat
        let g: CGFloat
        let b: CGFloat
        let a: CGFloat
        switch count {
        case 4:
            r = components[0]
            g = components[1]
            b = components[2]
            a = components[3]
        case 2:
            r = components[0]
            g = components[0]
            b = components[0]
            a = components[1]
        case 1:
            r = components[0]
            g = components[0]
            b = components[0]
            a = components[0]
        default:
            assertionFailure()
            r = 0
            g = 0
            b = 0
            a = 0
        }
        return [NSNumber(value: Double(r)), NSNumber(value: Double(g)), NSNumber(value: Double(b)), NSNumber(value: Double(a))]
    }

    @objc(avs_colorFromRGBAComponents:)
    public static func avs_color(fromRGBAComponents components: [NSNumber]?) -> UIColor? {
        guard let components, components.count == 4 else {
            if components != nil { assertionFailure() }
            return nil
        }
        return UIColor(
            red: components[0].doubleValue,
            green: components[1].doubleValue,
            blue: components[2].doubleValue,
            alpha: components[3].doubleValue
        )
    }

    @objc(avs_rgbaString)
    public func avs_rgbaString() -> String {
        let rgba = avs_rgbaComponents().map { CGFloat($0.doubleValue) }
        let r = rgba[0] * 255
        let g = rgba[1] * 255
        let b = rgba[2] * 255
        let a = rgba[3]
        if a >= 1 {
            return String(format: "(%.0f, %.0f, %.0f)", r, g, b)
        }
        return String(format: "(%.0f, %.0f, %.0f, %.2f)", r, g, b, a)
    }

    @objc(avs_hexString)
    public func avs_hexString() -> String {
        let rgba = avs_rgbaComponents().map { CGFloat($0.doubleValue) }
        let red = Int(rgba[0] * 255)
        let green = Int(rgba[1] * 255)
        let blue = Int(rgba[2] * 255)
        let alpha = Int(rgba[3] * 255)
        let hex = String(
            format: "#%@%@%@%@",
            Self.alignColorHexStringLength(Self.hexString(with: alpha)),
            Self.alignColorHexStringLength(Self.hexString(with: red)),
            Self.alignColorHexStringLength(Self.hexString(with: green)),
            Self.alignColorHexStringLength(Self.hexString(with: blue))
        )
        return hex.lowercased()
    }

    @objc(avs_colorWithCGColor:)
    public static func avs_colorWithCGColor(_ cgColor: CGColor?) -> UIColor? {
        guard let cgColor else { return nil }
        guard CFGetTypeID(cgColor) == CGColor.typeID else { return nil }
        return UIColor(cgColor: cgColor)
    }

    private static func alignColorHexStringLength(_ hexString: String) -> String {
        hexString.count < 2 ? "0" + hexString : hexString
    }

    private static func hexString(with integer: Int) -> String {
        var value = integer
        var hexString = ""
        for _ in 0..<9 {
            let remainder = value % 16
            value /= 16
            hexString = hexLetter(with: remainder) + hexString
            if value == 0 { break }
        }
        return hexString
    }

    private static func hexLetter(with integer: Int) -> String {
        assert(integer < 16)
        switch integer {
        case 10: return "A"
        case 11: return "B"
        case 12: return "C"
        case 13: return "D"
        case 14: return "E"
        case 15: return "F"
        default: return String(integer)
        }
    }
}

#endif
