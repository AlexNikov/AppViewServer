import Foundation

/// Wire protocol v3 — JSON metadata + binary screenshot blobs (Peertalk multiplex).
public enum AppViewWireFormat {
    public static let version = 4

    public static func isSupportedWireVersion(_ version: Int) -> Bool {
        version == Self.version
    }

    @discardableResult
    public static func validateWireVersion(_ version: Int, context: String) -> Bool {
        guard isSupportedWireVersion(version) else {
            NSLog(
                "AppViewWire - rejected %@: wireVersion=%d expected=%d",
                context,
                version,
                Self.version
            )
            return false
        }
        return true
    }

    /// JSON UTF-8 payload (`WireResponseEnvelope` or `WireCommand`).
    public static let frameTypeJSON: UInt32 = 0x41564A53 // "AVJS"

    /// Binary screenshot: 16-byte header + PNG/JPEG bytes.
    public static let frameTypeScreenshot: UInt32 = 0x41565047 // "AVPG"

    public static let screenshotHeaderLength = 16
}

public enum WireScreenshotKind: UInt8, Codable {
    case solo = 1
    case group = 2
}

public enum WireImageFormat: UInt8, Codable {
    case png = 1
    case jpeg = 2
}
