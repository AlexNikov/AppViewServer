#if canImport(AppViewShared)
import AppViewShared
#endif
#if SHOULD_COMPILE_APPVIEW_SERVER

import UIKit

extension UIView {
    @objc(avs_findHostViewController)
    public func avs_findHostViewController() -> UIViewController? {
        guard let responder = next, let viewController = responder as? UIViewController else { return nil }
        guard viewController.view === self else { return nil }
        return viewController
    }

    @objc(avs_subviewAtPoint:preferredClasses:)
    public func avs_subview(at point: CGPoint, preferredClasses: [AnyClass]) -> UIView {
        let isPreferredClassForSelf = (preferredClasses as NSArray).appview_any { obj in
            guard let cls = obj as? AnyClass else { return false }
            return isKind(of: cls)
        }
        if isPreferredClassForSelf {
            return self
        }

        var targetView = (subviews as NSArray).appview_lastFiltered { obj in
            guard let view = obj as? UIView else { return false }
            if view.isHidden || view.alpha <= 0.01 { return false }
            return view.frame.contains(point)
        } as? UIView

        if targetView == nil {
            return self
        }

        let newPoint = targetView!.convert(point, from: self)
        targetView = targetView!.avs_subview(at: newPoint, preferredClasses: preferredClasses)
        return targetView!
    }

    @objc(avs_bestSize)
    public func avs_bestSize() -> CGSize {
        sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
    }

    @objc(avs_bestWidth)
    public func avs_bestWidth() -> CGFloat {
        avs_bestSize().width
    }

    @objc(avs_bestHeight)
    public func avs_bestHeight() -> CGFloat {
        avs_bestSize().height
    }

    @objc public var avs_isChildrenViewOfTabBar: Bool {
        get { appview_getBindBOOL(forKey: "avs_isChildrenViewOfTabBar") }
        set { appview_bindBOOL(newValue, forKey: "avs_isChildrenViewOfTabBar") }
    }

    /// Returns false when any clipsToBounds ancestor clips this view out of its visible bounds
    /// (e.g. a UIScrollView cell that is outside the current contentOffset viewport).
    /// CALayer.render(in:) should be used instead of drawHierarchy in that case.
    var avs_isVisibleInClipHierarchy: Bool {
        var current: UIView = self
        while let superview = current.superview {
            if superview.clipsToBounds || superview is UIScrollView {
                let frameInSuperview = current.convert(current.bounds, to: superview)
                if !superview.bounds.intersects(frameInSuperview) {
                    return false
                }
            }
            current = superview
        }
        return true
    }

    @objc var avs_verticalContentHuggingPriority: Float {
        get { contentHuggingPriority(for: .vertical).rawValue }
        set { setContentHuggingPriority(UILayoutPriority(rawValue: newValue), for: .vertical) }
    }

    @objc var avs_horizontalContentHuggingPriority: Float {
        get { contentHuggingPriority(for: .horizontal).rawValue }
        set { setContentHuggingPriority(UILayoutPriority(rawValue: newValue), for: .horizontal) }
    }

    @objc var avs_verticalContentCompressionResistancePriority: Float {
        get { contentCompressionResistancePriority(for: .vertical).rawValue }
        set { setContentCompressionResistancePriority(UILayoutPriority(rawValue: newValue), for: .vertical) }
    }

    @objc var avs_horizontalContentCompressionResistancePriority: Float {
        get { contentCompressionResistancePriority(for: .horizontal).rawValue }
        set { setContentCompressionResistancePriority(UILayoutPriority(rawValue: newValue), for: .horizontal) }
    }

    /// True when `constraint` may become an `al_c_c` row of `view`: active, not an encapsulated system wrapper,
    /// and the view is its first or second item.
    static func avs_isConstraintRow(_ constraint: NSLayoutConstraint, for view: UIView) -> Bool {
        guard constraint.isActive, !AVS_LayoutConflictRecorder.isEncapsulated(constraint) else { return false }
        return (constraint.firstItem as AnyObject?) === view || (constraint.secondItem as AnyObject?) === view
    }

    /// Active constraints that name this view as first or second item. An active constraint is installed on one
    /// of its items or on their closest common ancestor, so this view and its ancestors hold all of them.
    /// Root first, matching the order of the old window-wide index.
    func avs_involvedConstraints() -> [NSLayoutConstraint] {
        var holders: [UIView] = []
        var current: UIView? = self
        while let view = current {
            holders.append(view)
            current = view.superview
        }
        var result: [NSLayoutConstraint] = []
        for holder in holders.reversed() {
            for constraint in holder.constraints where UIView.avs_isConstraintRow(constraint, for: self) {
                result.append(constraint)
            }
        }
        return result
    }

    @objc(avs_constraints)
    public func avs_constraints() -> [AppViewAutoLayoutConstraint]? {
        var effective = Set<ObjectIdentifier>()
        for constraint in constraintsAffectingLayout(for: .horizontal) { effective.insert(ObjectIdentifier(constraint)) }
        for constraint in constraintsAffectingLayout(for: .vertical) { effective.insert(ObjectIdentifier(constraint)) }

        var rows: [AppViewAutoLayoutConstraint] = []
        for constraint in avs_involvedConstraints() {
            rows.append(AppViewAutoLayoutConstraint.instance(
                fromNSConstraint: constraint,
                isEffective: effective.contains(ObjectIdentifier(constraint)),
                firstItemType: avs_constraintItemType(for: constraint.firstItem),
                secondItemType: avs_constraintItemType(for: constraint.secondItem)
            ))
        }

        // A broken constraint may already be inactive: keep its recorded values while it is still alive so
        // `al_l.constraintIDs` match a row. Dead ones are dropped by the recorder (ids are pointer addresses).
        var knownIDs = Set(rows.compactMap(\.snapshotID))
        let oid = avs_registerOid()
        for record in AVS_LayoutConflictRecorder.shared.records(forOid: oid) {
            guard let snapshot = record.makeConstraint(forOid: oid),
                  let id = snapshot.snapshotID, knownIDs.insert(id).inserted else { continue }
            rows.append(snapshot)
        }
        return rows.isEmpty ? nil : rows
    }

    /// `al_c_i`: active constraints stored on this view that relate other items, such as two subviews or one
    /// of this view's layout guides and a subview. Constraints naming this view are already `al_c_c` rows.
    @objc(avs_installedConstraints)
    public func avs_installedConstraints() -> [AppViewAutoLayoutConstraint]? {
        var rows: [AppViewAutoLayoutConstraint] = []
        for constraint in constraints {
            guard constraint.isActive, !AVS_LayoutConflictRecorder.isEncapsulated(constraint),
                  (constraint.firstItem as AnyObject?) !== self,
                  (constraint.secondItem as AnyObject?) !== self else { continue }
            rows.append(AppViewAutoLayoutConstraint.instance(
                fromNSConstraint: constraint,
                isEffective: true,
                firstItemType: avs_constraintItemType(for: constraint.firstItem),
                secondItemType: avs_constraintItemType(for: constraint.secondItem)
            ))
        }
        return rows.isEmpty ? nil : rows
    }

    /// Layout problems for `al_l`: cached ambiguous scan plus live recorded conflicts. Never calls
    /// `hasAmbiguousLayout`. Cited ids are limited to this view's `al_c_c` rows.
    @objc(avs_layoutIssues)
    public func avs_layoutIssues() -> [AppViewLayoutIssue]? {
        let oid = avs_registerOid()
        let records = AVS_LayoutConflictRecorder.shared.records(forOid: oid)
        var issues = AVS_LayoutIssueScanner.shared.ambiguousIssues(forOid: oid)
        for record in records {
            issues.append(AppViewLayoutIssue(
                kind: .conflict,
                title: AVS_LayoutConflictRecorder.conflictTitle,
                constraintIDs: record.constraintIDs
            ))
        }
        guard !issues.isEmpty else { return nil }

        // Same ids as `avs_constraints()` rows, without building the row models.
        var rowIDs = Set(avs_involvedConstraints().map { AppViewAutoLayoutConstraint.snapshotID(for: $0) })
        for record in records { rowIDs.insert(record.brokenConstraintID) }
        for issue in issues {
            issue.constraintIDs = issue.constraintIDs.filter { rowIDs.contains($0) }
        }
        return issues
    }

    private func avs_constraintItemType(for item: Any?) -> AppViewConstraintItemType {
        let type = AppViewAutoLayoutConstraint.itemType(for: item, relativeTo: self)
        if type == .unknown { assertionFailure() }
        return type
    }

    @objc(avs_accessibilityTraitsDescription)
    public func avs_accessibilityTraitsDescription() -> String? {
        let traits = accessibilityTraits
        if traits.isEmpty { return nil }

        var names: [String] = []
        let mapping: [(UIAccessibilityTraits, String)] = [
            (.button, "button"),
            (.link, "link"),
            (.image, "image"),
            (.selected, "selected"),
            (.playsSound, "playsSound"),
            (.keyboardKey, "keyboardKey"),
            (.staticText, "staticText"),
            (.summaryElement, "summaryElement"),
            (.notEnabled, "notEnabled"),
            (.updatesFrequently, "updatesFrequently"),
            (.searchField, "searchField"),
            (.startsMediaSession, "startsMediaSession"),
            (.adjustable, "adjustable"),
            (.allowsDirectInteraction, "allowsDirectInteraction"),
            (.causesPageTurn, "causesPageTurn"),
            (.header, "header"),
            (.tabBar, "tabBar"),
        ]
        for (trait, name) in mapping where traits.contains(trait) {
            names.append(name)
        }
        return names.isEmpty ? nil : names.joined(separator: ", ")
    }
}

#endif
