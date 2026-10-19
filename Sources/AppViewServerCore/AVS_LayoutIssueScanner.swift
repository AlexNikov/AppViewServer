#if canImport(AppViewShared)
import AppViewShared
#endif
#if SHOULD_COMPILE_APPVIEW_SERVER

import Foundation
import UIKit

/// Ambiguous-layout scan with a per-view cache. The scan runs only when a hierarchy request asks for it
/// (first connect, toolbar Reload). Hierarchy snapshots and detail requests only read the cache.
public final class AVS_LayoutIssueScanner: NSObject {

    public static let shared = AVS_LayoutIssueScanner()

    static let ambiguousTitle = "Ambiguous layout"

    /// Replaceable in tests; production uses the public `hasAmbiguousLayout`.
    var ambiguityProbe: (UIView) -> Bool = { $0.hasAmbiguousLayout }
    /// Number of `ambiguityProbe` calls since process start (tests assert cached paths do not probe).
    private(set) var probeCallCount = 0

    private let lock = NSLock()
    private var ambiguousByOid: [UInt: [AppViewLayoutIssue]] = [:]

    /// Results of one scan. Filled on the main thread, then `commit(_:)` replaces the cache.
    final class Pass {
        fileprivate var issuesByOid: [UInt: [AppViewLayoutIssue]] = [:]
        fileprivate var probeCount = 0

        func ambiguousCount(forOid oid: UInt) -> Int {
            issuesByOid[oid]?.count ?? 0
        }
    }

    // MARK: - Cache reads (no layout engine access)

    public func ambiguousIssues(forOid oid: UInt) -> [AppViewLayoutIssue] {
        lock.lock()
        defer { lock.unlock() }
        return (ambiguousByOid[oid] ?? []).map {
            AppViewLayoutIssue(kind: $0.kind, title: $0.title, constraintIDs: $0.constraintIDs)
        }
    }

    public func ambiguousCount(forOid oid: UInt) -> Int {
        lock.lock()
        defer { lock.unlock() }
        return ambiguousByOid[oid]?.count ?? 0
    }

    /// Cached ambiguous issues plus recorded conflicts. Does not call the layout engine.
    public func layoutIssueCount(forOid oid: UInt) -> Int {
        ambiguousCount(forOid: oid) + AVS_LayoutConflictRecorder.shared.conflictCount(forOid: oid)
    }

    func ambiguousCountsByOid() -> [UInt: Int] {
        lock.lock()
        defer { lock.unlock() }
        return ambiguousByOid.mapValues(\.count)
    }

    public func clearCache() {
        lock.lock()
        defer { lock.unlock() }
        ambiguousByOid.removeAll()
    }

    // MARK: - Scan

    /// Views outside a window and views still on autoresizing masks are not asked.
    static func shouldProbe(_ view: UIView) -> Bool {
        view.window != nil && !view.translatesAutoresizingMaskIntoConstraints
    }

    /// Walks every window and replaces the cache. Main thread only.
    public func scan() {
        scan(roots: AVS_MultiplatformAdapter.allWindows() as? [UIView] ?? [])
    }

    func scan(roots: [UIView]) {
        let pass = Pass()
        for root in roots {
            collect(from: root, into: pass)
        }
        commit(pass)
    }

    /// Asks the engine about one view and records an issue when it is ambiguous. Main thread only.
    func probe(_ view: UIView, oid: UInt, in pass: Pass) {
        guard Self.shouldProbe(view) else { return }
        pass.probeCount += 1
        guard ambiguityProbe(view) else { return }
        pass.issuesByOid[oid] = [AppViewLayoutIssue(
            kind: .ambiguous,
            title: Self.ambiguousTitle,
            constraintIDs: Self.constraintIDsAffectingLayout(of: view)
        )]
    }

    func commit(_ pass: Pass) {
        lock.lock()
        ambiguousByOid = pass.issuesByOid
        probeCallCount += pass.probeCount
        lock.unlock()
    }

    private func collect(from view: UIView, into pass: Pass) {
        if Self.shouldProbe(view) {
            probe(view, oid: view.avs_registerOid(), in: pass)
        }
        for subview in view.subviews {
            collect(from: subview, into: pass)
        }
    }

    /// Horizontal + vertical affecting constraints, one id per constraint. Only constraints that become `al_c_c`
    /// rows of this view are cited (active, non-encapsulated, view is first or second item): ancestor or
    /// sibling constraints cannot be highlighted on the card.
    static func constraintIDsAffectingLayout(of view: UIView) -> [String] {
        var seen = Set<ObjectIdentifier>()
        var ids: [String] = []
        let combined = view.constraintsAffectingLayout(for: .horizontal) + view.constraintsAffectingLayout(for: .vertical)
        for constraint in combined where seen.insert(ObjectIdentifier(constraint)).inserted {
            guard UIView.avs_isConstraintRow(constraint, for: view) else { continue }
            ids.append(AppViewAutoLayoutConstraint.snapshotID(for: constraint))
        }
        return ids
    }
}

/// Layout issue counts for one hierarchy build. Conflict and cached ambiguous counts are read once up front;
/// with `scanning`, each view is probed during the same walk that builds the display items.
final class AVS_LayoutIssueCounter {
    private let scanner: AVS_LayoutIssueScanner
    private let conflictCounts: [UInt: Int]
    private let cachedAmbiguousCounts: [UInt: Int]
    private let pass: AVS_LayoutIssueScanner.Pass?

    init(scanning: Bool, scanner: AVS_LayoutIssueScanner = .shared, recorder: AVS_LayoutConflictRecorder = .shared) {
        self.scanner = scanner
        conflictCounts = recorder.conflictCountsByOid()
        pass = scanning ? AVS_LayoutIssueScanner.Pass() : nil
        cachedAmbiguousCounts = scanning ? [:] : scanner.ambiguousCountsByOid()
    }

    func count(for view: UIView, oid: UInt) -> Int {
        let ambiguous: Int
        if let pass {
            scanner.probe(view, oid: oid, in: pass)
            ambiguous = pass.ambiguousCount(forOid: oid)
        } else {
            ambiguous = cachedAmbiguousCounts[oid] ?? 0
        }
        return ambiguous + (conflictCounts[oid] ?? 0)
    }

    /// Replaces the ambiguous cache with what this walk found. No-op without `scanning`.
    func finish() {
        if let pass { scanner.commit(pass) }
    }
}

#endif
