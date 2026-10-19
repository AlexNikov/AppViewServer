#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit
#if canImport(AppViewShared)
import AppViewShared
#endif

extension AppViewAutoLayoutConstraint {
    @objc(instanceFromNSConstraint:isEffective:firstItemType:secondItemType:)
    public class func instance(
        fromNSConstraint constraint: NSLayoutConstraint,
        isEffective: Bool,
        firstItemType: AppViewConstraintItemType,
        secondItemType: AppViewConstraintItemType
    ) -> AppViewAutoLayoutConstraint {
        let instance = AppViewAutoLayoutConstraint()
        instance.effective = isEffective
        instance.active = constraint.isActive
        instance.shouldBeArchived = constraint.shouldBeArchived
        if let firstObject = constraint.firstItem as? NSObject {
            instance.firstItem = AppViewObject.instance(with: firstObject)
        }
        instance.firstItemType = firstItemType
        instance.firstAttribute = constraint.firstAttribute.rawValue
        instance.relation = constraint.relation
        if let secondObject = constraint.secondItem as? NSObject {
            instance.secondItem = AppViewObject.instance(with: secondObject)
        }
        instance.secondItemType = secondItemType
        instance.secondAttribute = constraint.secondAttribute.rawValue
        instance.multiplier = constraint.multiplier
        instance.constant = constraint.constant
        instance.priority = CGFloat(constraint.priority.rawValue)
        instance.identifier = constraint.identifier
        instance.snapshotID = snapshotID(for: constraint)
        return instance
    }

    /// Stable id for one snapshot: the constraint's pointer address (same format as `AppViewObject.memoryAddress`).
    public class func snapshotID(for constraint: NSLayoutConstraint) -> String {
        String(format: "%p", constraint)
    }

    /// Classifies a constraint participant relative to the view that lists it. Never asserts.
    public class func itemType(for item: Any?, relativeTo view: UIView?) -> AppViewConstraintItemType {
        guard let item else { return .nil }
        if let view, (item as AnyObject) === view { return .self }
        if let superview = view?.superview, (item as AnyObject) === superview { return .super }
        if item is UILayoutGuide { return .layoutGuide }
        if NSStringFromClass(type(of: item as AnyObject)).hasSuffix("_UILayoutGuide") { return .layoutGuide }
        if item is UIView { return .view }
        return .unknown
    }
}
#endif
