#if os(macOS)

import AppKit

extension NSImage {
    @objc(appview_data)
    public func appview_data() -> Data? {
        tiffRepresentation
    }
}

#endif
