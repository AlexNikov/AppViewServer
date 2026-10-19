#if canImport(AppViewShared)
import AppViewShared
#endif
#if SHOULD_COMPILE_APPVIEW_SERVER

import Foundation
import ObjectiveC
import UIKit

@_silgen_name("AppViewLayoutConflictHookInstalled")
private func appviewLayoutConflictHookInstalled() -> Bool

/// Called by the `+load` engine hook for every constraint the Auto Layout engine breaks.
@_cdecl("appview_server_record_layout_conflict")
public func appview_server_recordLayoutConflict(_ broken: NSLayoutConstraint?, _ others: NSArray?) {
    guard let broken else { return }
    AVS_LayoutConflictRecorder.shared.record(
        brokenConstraint: broken,
        conflictingWith: others as? [NSLayoutConstraint] ?? []
    )
}

/// Weak liveness probe for one constraint. Holds the id (pointer address at record time) but never retains.
private struct WeakConstraintRef {
    let id: String
    weak var constraint: NSLayoutConstraint?
    var isAlive: Bool { constraint != nil }
    var isActive: Bool { constraint?.isActive == true }
}

/// One recorded Auto Layout conflict. Values for JSON plus weak refs used only to test liveness.
public struct AVS_LayoutConflictRecord {
    /// Oids of every participating view (a guide maps to its owning view).
    public let participantOids: [UInt]
    /// Values of the broken constraint per participant, `effective == false`, item types relative to that view.
    fileprivate let snapshotsByOid: [UInt: AppViewAutoLayoutConstraint]
    fileprivate let broken: WeakConstraintRef
    fileprivate let peers: [WeakConstraintRef]

    fileprivate init(
        participantOids: [UInt],
        snapshotsByOid: [UInt: AppViewAutoLayoutConstraint],
        broken: WeakConstraintRef,
        peers: [WeakConstraintRef]
    ) {
        self.participantOids = participantOids
        self.snapshotsByOid = snapshotsByOid
        self.broken = broken
        self.peers = peers
    }

    /// A conflict is shown only while the broken `NSLayoutConstraint` is alive: ids are pointer addresses and
    /// must never light up an unrelated constraint that reuses one.
    public var isAlive: Bool { broken.isAlive }

    /// The engine reports a conflict once, so a record stays until the app resolves it: the broken constraint is
    /// freed or deactivated, or every mutually exclusive constraint it was reported with is gone or inactive.
    public var isUnresolved: Bool {
        guard broken.isActive else { return false }
        return peers.isEmpty || peers.contains(where: \.isActive)
    }

    public var brokenConstraintID: String { broken.id }

    /// Broken constraint id followed by the still-alive mutually exclusive ones.
    public var constraintIDs: [String] {
        [broken.id] + peers.filter(\.isAlive).map(\.id)
    }

    public func makeConstraint(forOid oid: UInt) -> AppViewAutoLayoutConstraint? {
        snapshotsByOid[oid]?.copyValues()
    }
}

/// Collects constraints the Auto Layout engine breaks. Swizzles
/// `engine:willBreakConstraint:dueToMutuallyExclusiveConstraints:` only when that selector exists.
public final class AVS_LayoutConflictRecorder: NSObject {

    public static let shared = AVS_LayoutConflictRecorder()

    public static let encapsulatedLayoutIdentifier = "UIView-Encapsulated-Layout"
    public static let conflictTitle = "Conflicting constraints"
    public static let defaultBufferLimit = 48
    static let engineSelectorName = "engine:willBreakConstraint:dueToMutuallyExclusiveConstraints:"

    private let lock = NSLock()
    private var records: [AVS_LayoutConflictRecord] = []
    private var installedKeys = Set<String>()
    private let bufferLimit: Int

    public init(bufferLimit: Int = AVS_LayoutConflictRecorder.defaultBufferLimit) {
        self.bufferLimit = max(1, bufferLimit)
        super.init()
    }

    // MARK: - Install

    /// The engine callback is normally hooked in `AVS_ConnectionLoadHook +load`, before the first layout pass.
    /// Falls back to swizzling here when that hook is missing. Returns `false` when no class implements it.
    @discardableResult
    public func installIfAvailable() -> Bool {
        if appviewLayoutConflictHookInstalled() { return true }
        return install(classNames: ["NSISEngine", "UIView"], selectorName: Self.engineSelectorName)
    }

    @discardableResult
    func install(classNames: [String], selectorName: String) -> Bool {
        let selector = NSSelectorFromString(selectorName)
        lock.lock()
        defer { lock.unlock() }
        for className in classNames {
            guard let cls = NSClassFromString(className),
                  let method = class_getInstanceMethod(cls, selector) else { continue }
            let key = "\(className).\(selectorName)"
            if installedKeys.contains(key) { return true }
            guard method_getNumberOfArguments(method) == 5, Self.returnsVoid(method) else { continue }

            typealias OriginalFn = @convention(c) (AnyObject, Selector, AnyObject?, AnyObject?, AnyObject?) -> Void
            let originalFn = unsafeBitCast(method_getImplementation(method), to: OriginalFn.self)
            // The block only captures the original IMP and the recorder; never the constraint.
            let block: @convention(block) (AnyObject, AnyObject?, AnyObject?, AnyObject?) -> Void = {
                [weak self] receiver, engine, broken, others in
                if let constraint = broken as? NSLayoutConstraint {
                    self?.record(brokenConstraint: constraint, conflictingWith: others as? [NSLayoutConstraint] ?? [])
                }
                originalFn(receiver, selector, engine, broken, others)
            }
            method_setImplementation(method, imp_implementationWithBlock(block))
            installedKeys.insert(key)
            return true
        }
        return false
    }

    private static func returnsVoid(_ method: Method) -> Bool {
        let encoding = method_copyReturnType(method)
        defer { free(encoding) }
        return String(cString: encoding) == "v"
    }

    // MARK: - Record

    /// Copies the values the wire needs and keeps only weak refs to the constraints (liveness checks).
    /// Returns `false` when skipped.
    @discardableResult
    public func record(brokenConstraint: NSLayoutConstraint, conflictingWith others: [NSLayoutConstraint] = []) -> Bool {
        // Cell/system wrappers: filter before any copy.
        guard !Self.isEncapsulated(brokenConstraint) else { return false }
        let participants = Self.participantViews(of: brokenConstraint)
        guard !participants.isEmpty else { return false }

        let brokenID = AppViewAutoLayoutConstraint.snapshotID(for: brokenConstraint)
        var snapshots: [UInt: AppViewAutoLayoutConstraint] = [:]
        var oids: [UInt] = []
        for view in participants {
            let oid = view.avs_registerOid()
            guard snapshots[oid] == nil else { continue }
            snapshots[oid] = AppViewAutoLayoutConstraint.instance(
                fromNSConstraint: brokenConstraint,
                isEffective: false,
                firstItemType: AppViewAutoLayoutConstraint.itemType(for: brokenConstraint.firstItem, relativeTo: view),
                secondItemType: AppViewAutoLayoutConstraint.itemType(for: brokenConstraint.secondItem, relativeTo: view)
            )
            oids.append(oid)
        }
        var peerRefs: [WeakConstraintRef] = []
        for other in others where !Self.isEncapsulated(other) {
            let id = AppViewAutoLayoutConstraint.snapshotID(for: other)
            if id != brokenID, !peerRefs.contains(where: { $0.id == id }) {
                peerRefs.append(WeakConstraintRef(id: id, constraint: other))
            }
        }

        lock.lock()
        defer { lock.unlock() }
        pruneResolvedLocked()
        // The engine may report the same constraint every layout pass: keep one record, newest wins.
        records.removeAll { $0.broken.id == brokenID }
        records.append(AVS_LayoutConflictRecord(
            participantOids: oids,
            snapshotsByOid: snapshots,
            broken: WeakConstraintRef(id: brokenID, constraint: brokenConstraint),
            peers: peerRefs
        ))
        if records.count > bufferLimit {
            records.removeFirst(records.count - bufferLimit)
        }
        return true
    }

    public static func isEncapsulated(_ constraint: NSLayoutConstraint) -> Bool {
        constraint.identifier?.contains(encapsulatedLayoutIdentifier) == true
    }

    /// Every participating view, in order, without duplicates. A guide maps to its owning view.
    static func participantViews(of constraint: NSLayoutConstraint) -> [UIView] {
        var result: [UIView] = []
        for item in [constraint.firstItem, constraint.secondItem] {
            guard let view = view(for: item), !result.contains(where: { $0 === view }) else { continue }
            result.append(view)
        }
        return result
    }

    private static func view(for item: AnyObject?) -> UIView? {
        if let view = item as? UIView { return view }
        if let guide = item as? UILayoutGuide { return guide.owningView }
        return nil
    }

    // MARK: - Read

    /// Live records for one view, newest last.
    public func records(forOid oid: UInt) -> [AVS_LayoutConflictRecord] {
        lock.lock()
        defer { lock.unlock() }
        pruneResolvedLocked()
        return records.filter { $0.participantOids.contains(oid) }
    }

    public func conflictCount(forOid oid: UInt) -> Int {
        records(forOid: oid).count
    }

    /// Live conflict count per participating view, taken once per hierarchy build.
    public func conflictCountsByOid() -> [UInt: Int] {
        lock.lock()
        defer { lock.unlock() }
        pruneResolvedLocked()
        var counts: [UInt: Int] = [:]
        for record in records {
            for oid in record.participantOids {
                counts[oid, default: 0] += 1
            }
        }
        return counts
    }

    public var recordCount: Int {
        lock.lock()
        defer { lock.unlock() }
        pruneResolvedLocked()
        return records.count
    }

    // MARK: - Lifecycle

    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        records.removeAll()
    }

    /// Hierarchy snapshots and Reloads never drop a record: only resolution does.
    private func pruneResolvedLocked() {
        records.removeAll { !$0.isUnresolved }
    }
}

#endif
