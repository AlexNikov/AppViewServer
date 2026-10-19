import Foundation

extension String {
    static func appview_string(from doubleValue: Double, decimal: UInt) -> String {
        var string = String(format: "%.\(decimal)f", doubleValue)
        for _ in 0..<decimal {
            if string.hasSuffix("0") {
                string.removeLast()
            }
        }
        if string.hasSuffix(".") {
            string.removeLast()
        }
        return string
    }

    static func appview_string(from rect: CGRect) -> String {
        "{\(appview_string(from: rect.origin.x, decimal: 2)), \(appview_string(from: rect.origin.y, decimal: 2)), \(appview_string(from: rect.size.width, decimal: 2)), \(appview_string(from: rect.size.height, decimal: 2))}"
    }

    static func appview_string(from size: CGSize) -> String {
        "{\(appview_string(from: size.width, decimal: 2)), \(appview_string(from: size.height, decimal: 2))}"
    }

    static func appview_string(from point: CGPoint) -> String {
        "{\(appview_string(from: point.x, decimal: 2)), \(appview_string(from: point.y, decimal: 2))}"
    }

    static func appview_string(from insets: AppViewInsets) -> String {
        "{\(appview_string(from: insets.top, decimal: 2)), \(appview_string(from: insets.left, decimal: 2)), \(appview_string(from: insets.bottom, decimal: 2)), \(appview_string(from: insets.right, decimal: 2))}"
    }

    func appview_numbericOSVersion() -> Int {
        let parts = split(separator: ".")
        guard parts.count == 3 else { return 0 }
        var numeric = 0
        for (index, part) in parts.prefix(3).enumerated() {
            guard let value = Int(part) else { return 0 }
            numeric += value * Int(pow(10, Double(4 - index * 2)))
        }
        return numeric
    }
}

extension NSString {
    @objc(appview_stringFromDouble:decimal:)
    public static func appview_string(from doubleValue: Double, decimal: UInt) -> String {
        String.appview_string(from: doubleValue, decimal: decimal)
    }

    @objc(appview_stringFromRect:)
    public static func appview_string(from rect: CGRect) -> String {
        String.appview_string(from: rect)
    }

    @objc(appview_stringFromSize:)
    public static func appview_string(from size: CGSize) -> String {
        String.appview_string(from: size)
    }

    @objc(appview_stringFromPoint:)
    public static func appview_string(from point: CGPoint) -> String {
        String.appview_string(from: point)
    }

    @objc(appview_stringFromInset:)
    public static func appview_string(from insets: AppViewInsets) -> String {
        String.appview_string(from: insets)
    }

    @objc(appview_numbericOSVersion)
    public func appview_numbericOSVersion() -> Int {
        (self as String).appview_numbericOSVersion()
    }

    @objc(appview_safeInitWithUTF8String:)
    public func appview_safeInitWithUTF8String(_ string: UnsafePointer<CChar>?) -> String? {
        guard let string else { return nil }
        return String(cString: string)
    }

    @objc(appview_rgbaStringFromColor:)
    public static func appview_rgbaString(from color: AppViewColor?) -> String {
        guard let color else { return "nil" }
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        if a >= 1 {
            return String(format: "(%.0f, %.0f, %.0f)", r * 255, g * 255, b * 255)
        }
        return String(format: "(%.0f, %.0f, %.0f, %@)", r * 255, g * 255, b * 255, appview_string(from: a, decimal: 2))
    }
}
