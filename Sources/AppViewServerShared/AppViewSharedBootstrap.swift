import Foundation

/// Placeholder for shared-module load side effects (wire v2 needs no ObjC class registration).
private enum AppViewSharedBootstrap {
    static let activated: Void = ()

    static func activate() {
        _ = activated
    }
}

private let _appviewSharedWireBootstrapToken: Void = AppViewSharedBootstrap.activate()
