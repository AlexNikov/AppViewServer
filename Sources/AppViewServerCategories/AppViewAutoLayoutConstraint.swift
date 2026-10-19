import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@objc public enum AppViewConstraintItemType: Int {
    case unknown = 0
    case `nil` = 1
    case view = 2
    case `self` = 3
    case `super` = 4
    case layoutGuide = 5
}

@objc(AppViewAutoLayoutConstraint)
public class AppViewAutoLayoutConstraint: NSObject {
    @objc public var effective: Bool = false
    @objc public var active: Bool = false
    @objc public var shouldBeArchived: Bool = false
    @objc public var firstItem: AppViewObject?
    @objc public var firstItemType: AppViewConstraintItemType = .unknown
    @objc public var firstAttribute: Int = 0 {
        didSet { assertUnknownAttribute(firstAttribute) }
    }
    @objc public var relation: NSLayoutConstraint.Relation = .equal
    @objc public var secondItem: AppViewObject?
    @objc public var secondItemType: AppViewConstraintItemType = .unknown
    @objc public var secondAttribute: Int = 0 {
        didSet { assertUnknownAttribute(secondAttribute) }
    }
    @objc public var multiplier: CGFloat = 0
    @objc public var constant: CGFloat = 0
    @objc public var priority: CGFloat = 0
    @objc public var identifier: String?
    /// Pointer address of the source `NSLayoutConstraint` at snapshot time. Matches `AppViewLayoutIssue.constraintIDs`.
    public var snapshotID: String?

    public override init() {
        super.init()
    }

    /// Value copy for callers that mutate `effective` without touching a stored snapshot.
    public func copyValues() -> AppViewAutoLayoutConstraint {
        let copy = AppViewAutoLayoutConstraint()
        copy.effective = effective
        copy.active = active
        copy.shouldBeArchived = shouldBeArchived
        copy.firstItem = firstItem
        copy.firstItemType = firstItemType
        copy.firstAttribute = firstAttribute
        copy.relation = relation
        copy.secondItem = secondItem
        copy.secondItemType = secondItemType
        copy.secondAttribute = secondAttribute
        copy.multiplier = multiplier
        copy.constant = constant
        copy.priority = priority
        copy.identifier = identifier
        copy.snapshotID = snapshotID
        return copy
    }

    private func assertUnknownAttribute(_ attribute: Int) {
        if attribute > 20 && attribute < 32 {
            assertionFailure()
        }
        if attribute > 37 {
            assertionFailure()
        }
    }
}
