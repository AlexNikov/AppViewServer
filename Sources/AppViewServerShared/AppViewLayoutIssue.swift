import Foundation

public enum AppViewLayoutIssueKind: String {
    case ambiguous
    case conflict
}

/// One Auto Layout problem for a view. `constraintIDs` match `AppViewAutoLayoutConstraint.snapshotID` rows.
public final class AppViewLayoutIssue: NSObject {
    public var kind: AppViewLayoutIssueKind
    public var title: String
    public var constraintIDs: [String]

    public init(kind: AppViewLayoutIssueKind, title: String, constraintIDs: [String] = []) {
        self.kind = kind
        self.title = title
        self.constraintIDs = constraintIDs
        super.init()
    }
}

/// Which constraint rows a dashboard click should paint. The mac client stores one of these.
public struct AppViewLayoutIssueHighlight: Equatable {
    public var issueKey: String?
    /// Ids from the issue the user clicked. A second click on that issue clears only these.
    public var clickedIDs: Set<String>
    /// Ids from conflict issues. They stay highlighted while the issue is in the card.
    public var conflictIDs: Set<String>

    public var constraintIDs: Set<String> { clickedIDs.union(conflictIDs) }

    public init(issueKey: String? = nil, clickedIDs: Set<String> = [], conflictIDs: Set<String> = []) {
        self.issueKey = issueKey
        self.clickedIDs = clickedIDs
        self.conflictIDs = conflictIDs
    }

    public static func key(for issue: AppViewLayoutIssue) -> String {
        "\(issue.kind.rawValue):\(issue.constraintIDs.joined(separator: ","))"
    }

    public static func conflictIDs(in groups: [AppViewAttributesGroup]) -> Set<String> {
        var ids = Set<String>()
        for group in groups {
            for section in group.attrSections ?? [] {
                for attribute in section.attributes ?? [] where attribute.identifier == AppViewAttr_AutoLayout_Issues_Issues {
                    guard case .customObject(let raw)? = attribute.value,
                          let issues = raw as? [AppViewLayoutIssue] else { continue }
                    for issue in issues where issue.kind == .conflict {
                        ids.formUnion(issue.constraintIDs)
                    }
                }
            }
        }
        return ids
    }

    /// Keeps conflict rows highlighted. Replaces whatever the previous card reported.
    public mutating func setConflictIDs(_ ids: Set<String>) {
        conflictIDs = ids
    }

    /// First click selects an ambiguous issue. A second click on that issue clears only the click.
    /// A conflict issue is already highlighted and the click does not remove it.
    /// Returns true when the Constraints section should be revealed for a new ambiguous selection.
    @discardableResult
    public mutating func toggle(_ issue: AppViewLayoutIssue) -> Bool {
        if issue.kind == .conflict {
            conflictIDs.formUnion(issue.constraintIDs)
            issueKey = Self.key(for: issue)
            return false
        }
        let key = Self.key(for: issue)
        if issueKey == key {
            clearClick()
            return false
        }
        issueKey = key
        clickedIDs = Set(issue.constraintIDs)
        return true
    }

    public mutating func clearClick() {
        issueKey = nil
        clickedIDs = []
    }

    public mutating func clear() {
        clearClick()
        conflictIDs = []
    }

    public var isEmpty: Bool { clickedIDs.isEmpty && conflictIDs.isEmpty }

    public func highlights(snapshotID: String?) -> Bool {
        guard let snapshotID else { return false }
        return conflictIDs.contains(snapshotID) || clickedIDs.contains(snapshotID)
    }
}
