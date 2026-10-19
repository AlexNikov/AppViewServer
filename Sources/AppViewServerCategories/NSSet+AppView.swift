#if SHOULD_COMPILE_APPVIEW_SERVER

import Foundation

extension NSSet {
    @objc(appview_map:)
    public func appview_map(_ block: (Any) -> Any?) -> NSSet {
        let newSet = NSMutableSet(capacity: count)
        for obj in self {
            if let mapped = block(obj) {
                newSet.add(mapped)
            }
        }
        return newSet.copy() as! NSSet
    }

    @objc(appview_firstFiltered:)
    public func appview_firstFiltered(_ block: (Any) -> Bool) -> Any? {
        for obj in self {
            if block(obj) {
                return obj
            }
        }
        return nil
    }

    @objc(appview_filter:)
    public func appview_filter(_ block: (Any) -> Bool) -> NSSet {
        let result = NSMutableSet()
        for obj in self {
            if block(obj) {
                result.add(obj)
            }
        }
        return result.copy() as! NSSet
    }

    @objc(appview_any:)
    public func appview_any(_ block: (Any) -> Bool) -> Bool {
        for obj in self {
            if block(obj) {
                return true
            }
        }
        return false
    }
}

#endif
