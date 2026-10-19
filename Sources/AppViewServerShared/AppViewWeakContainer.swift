import Foundation

public final class AppViewWeakContainer {
    public weak var object: AnyObject?

    public static func container(with object: Any?) -> AppViewWeakContainer {
        let container = AppViewWeakContainer()
        container.object = object as AnyObject?
        return container
    }

    public init() {}

    public var hash: Int {
        object?.hash ?? 0
    }

    public func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? AppViewWeakContainer else { return false }
        if self === other { return true }
        if let lhs = self.object, let rhs = other.object {
            return lhs.isEqual(rhs)
        }
        return self.object == nil && other.object == nil
    }
}
