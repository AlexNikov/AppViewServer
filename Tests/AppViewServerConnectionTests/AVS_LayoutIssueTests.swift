#if SHOULD_COMPILE_APPVIEW_SERVER

import ObjectiveC
import UIKit
import XCTest
@testable import AppViewServer
@testable import AppViewShared

/// Test double for the engine delegate callback the recorder swizzles.
@objc(AVSLayoutConflictDummyEngine)
private final class DummyEngine: NSObject {
    var originalCalls = 0

    @objc(engine:willBreakConstraint:dueToMutuallyExclusiveConstraints:)
    func engine(_ engine: AnyObject?, willBreak constraint: AnyObject?, dueToMutuallyExclusiveConstraints others: AnyObject?) {
        originalCalls += 1
    }
}

@MainActor
final class AVS_LayoutIssueTests: XCTestCase {

    private let selectorName = AVS_LayoutConflictRecorder.engineSelectorName

    override func setUp() {
        super.setUp()
        AVS_LayoutConflictRecorder.shared.clear()
        AVS_LayoutIssueScanner.shared.clearCache()
    }

    override func tearDown() {
        AVS_LayoutConflictRecorder.shared.clear()
        AVS_LayoutIssueScanner.shared.clearCache()
        AVS_LayoutIssueScanner.shared.ambiguityProbe = { $0.hasAmbiguousLayout }
        super.tearDown()
    }

    private func makePair() -> (parent: UIView, child: UIView) {
        let parent = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        let child = UIView()
        child.translatesAutoresizingMaskIntoConstraints = false
        parent.addSubview(child)
        return (parent, child)
    }

    // MARK: Recorder

    func testConflictShownUntilTheAppDeactivatesTheBrokenConstraint() throws {
        let (parent, child) = makePair()
        let oid = child.avs_registerOid()
        let constraint = child.widthAnchor.constraint(equalToConstant: 50)
        constraint.identifier = "width50"
        constraint.isActive = true
        let constraintID = AppViewAutoLayoutConstraint.snapshotID(for: constraint)
        XCTAssertTrue(AVS_LayoutConflictRecorder.shared.record(brokenConstraint: constraint))

        let rows = try XCTUnwrap(child.avs_constraints())
        XCTAssertEqual(rows.filter { $0.snapshotID == constraintID }.count, 1, "one row, no duplicate from the recorder")
        XCTAssertEqual(rows.first { $0.snapshotID == constraintID }?.identifier, "width50")
        let issues = try XCTUnwrap(child.avs_layoutIssues())
        XCTAssertEqual(issues.first?.kind, .conflict)
        XCTAssertEqual(issues.flatMap(\.constraintIDs), [constraintID])
        XCTAssertEqual(AVS_LayoutConflictRecorder.shared.conflictCount(forOid: oid), 1)

        // The app fixes the layout by deactivating it: the conflict is resolved.
        constraint.isActive = false
        XCTAssertEqual(AVS_LayoutConflictRecorder.shared.conflictCount(forOid: oid), 0)
        XCTAssertNil(child.avs_layoutIssues())
        withExtendedLifetime((parent, constraint)) {}
    }

    func testConflictResolvedWhenEveryMutuallyExclusivePeerIsInactive() throws {
        let (parent, child) = makePair()
        let oid = child.avs_registerOid()
        let narrow = child.widthAnchor.constraint(equalToConstant: 80)
        let wide = child.widthAnchor.constraint(equalToConstant: 160)
        NSLayoutConstraint.activate([narrow, wide])
        XCTAssertTrue(AVS_LayoutConflictRecorder.shared.record(brokenConstraint: wide, conflictingWith: [narrow, wide]))
        XCTAssertEqual(AVS_LayoutConflictRecorder.shared.conflictCount(forOid: oid), 1)

        narrow.isActive = false
        XCTAssertEqual(AVS_LayoutConflictRecorder.shared.conflictCount(forOid: oid), 0, "nothing left to conflict with")
        withExtendedLifetime((parent, narrow, wide)) {}
    }

    func testConflictDroppedOnceConstraintIsFreedAndNeverMatchesUnrelatedConstraint() throws {
        let (parent, child) = makePair()
        let oid = child.avs_registerOid()
        weak var weakConstraint: NSLayoutConstraint?
        var staleID = ""

        autoreleasepool {
            let constraint = child.widthAnchor.constraint(equalToConstant: 50)
            constraint.isActive = true
            weakConstraint = constraint
            staleID = AppViewAutoLayoutConstraint.snapshotID(for: constraint)
            XCTAssertTrue(AVS_LayoutConflictRecorder.shared.record(brokenConstraint: constraint))
            constraint.isActive = false
        }

        // Recording must not keep the constraint alive; once it is gone the conflict is gone too.
        XCTAssertNil(weakConstraint)
        XCTAssertEqual(AVS_LayoutConflictRecorder.shared.conflictCount(forOid: oid), 0)
        XCTAssertEqual(AVS_LayoutConflictRecorder.shared.recordCount, 0)
        XCTAssertNil(child.avs_layoutIssues())

        // A new constraint (possibly at the freed address) must not be reported or highlighted.
        let unrelated = child.heightAnchor.constraint(equalToConstant: 10)
        unrelated.isActive = true
        let rows = try XCTUnwrap(child.avs_constraints())
        XCTAssertNil(child.avs_layoutIssues())
        XCTAssertFalse(rows.contains { $0.snapshotID == staleID && !$0.effective && $0.active == false })
        withExtendedLifetime(unrelated) {}
    }

    func testBrokenConstraintAttachesToEveryParticipatingView() throws {
        let parent = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        let first = UIView()
        let second = UIView()
        [first, second].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; parent.addSubview($0) }
        let guide = UILayoutGuide()
        second.addLayoutGuide(guide)

        let between = first.leadingAnchor.constraint(equalTo: second.trailingAnchor)
        between.isActive = true
        let guideConstraint = guide.widthAnchor.constraint(equalTo: first.widthAnchor)
        guideConstraint.isActive = true
        XCTAssertTrue(AVS_LayoutConflictRecorder.shared.record(brokenConstraint: between))
        XCTAssertTrue(AVS_LayoutConflictRecorder.shared.record(brokenConstraint: guideConstraint))

        let firstOid = first.avs_registerOid()
        let secondOid = second.avs_registerOid()
        XCTAssertEqual(AVS_LayoutConflictRecorder.shared.conflictCount(forOid: firstOid), 2)
        XCTAssertEqual(AVS_LayoutConflictRecorder.shared.conflictCount(forOid: secondOid), 2, "guide maps to its owning view")
        // Item types are relative to each participant.
        let record = try XCTUnwrap(AVS_LayoutConflictRecorder.shared.records(forOid: secondOid).first)
        XCTAssertEqual(record.makeConstraint(forOid: firstOid)?.firstItemType, .self)
        XCTAssertEqual(record.makeConstraint(forOid: secondOid)?.firstItemType, .view)
        withExtendedLifetime((between, guideConstraint)) {}
    }

    func testUnresolvedConflictSurvivesEveryHierarchyReadAndReload() throws {
        let (parent, child) = makePair()
        let oid = child.avs_registerOid()
        let first = child.widthAnchor.constraint(equalToConstant: 10)
        first.isActive = true
        AVS_LayoutConflictRecorder.shared.record(brokenConstraint: first)
        let second = child.heightAnchor.constraint(equalToConstant: 10)
        second.isActive = true
        AVS_LayoutConflictRecorder.shared.record(brokenConstraint: second)

        // The engine reports a conflict once: MCP reads, plain snapshots and repeated Reloads keep it.
        AVS_LayoutIssueScanner.shared.ambiguityProbe = { _ in false }
        for _ in 0..<3 {
            _ = AVHierarchyInfo.staticInfo(withAppViewVersion: nil)
            _ = AVHierarchyInfo.staticInfo(withAppViewVersion: nil, scanLayoutIssues: true)
        }
        XCTAssertEqual(AVS_LayoutConflictRecorder.shared.conflictCount(forOid: oid), 2)

        first.isActive = false
        _ = AVHierarchyInfo.staticInfo(withAppViewVersion: nil, scanLayoutIssues: true)
        let remaining = AVS_LayoutConflictRecorder.shared.records(forOid: oid)
        XCTAssertEqual(remaining.map(\.brokenConstraintID), [AppViewAutoLayoutConstraint.snapshotID(for: second)])
        withExtendedLifetime((first, second, parent)) {}
    }

    func testConstraintRowsComeFromTheViewAndItsAncestorsRootFirst() throws {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        let middle = UIView()
        middle.translatesAutoresizingMaskIntoConstraints = false
        let child = UIView()
        child.translatesAutoresizingMaskIntoConstraints = false
        let sibling = UIView()
        sibling.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(middle)
        middle.addSubview(child)
        root.addSubview(sibling)

        let onRoot = child.leadingAnchor.constraint(equalTo: sibling.leadingAnchor)
        let onMiddle = child.topAnchor.constraint(equalTo: middle.topAnchor)
        let onSelf = child.widthAnchor.constraint(equalToConstant: 40)
        let unrelated = sibling.heightAnchor.constraint(equalToConstant: 10)
        NSLayoutConstraint.activate([onSelf, onMiddle, onRoot, unrelated])

        // No window-wide index: the rows come straight from the view and its ancestors.
        let ids = try XCTUnwrap(child.avs_constraints()).compactMap(\.snapshotID)
        XCTAssertEqual(ids, [onRoot, onMiddle, onSelf].map { AppViewAutoLayoutConstraint.snapshotID(for: $0) })
        XCTAssertFalse(ids.contains(AppViewAutoLayoutConstraint.snapshotID(for: unrelated)))

        onMiddle.isActive = false
        XCTAssertFalse(try XCTUnwrap(child.avs_constraints()).contains {
            $0.snapshotID == AppViewAutoLayoutConstraint.snapshotID(for: onMiddle)
        })
        withExtendedLifetime([onRoot, onMiddle, onSelf, unrelated]) {}
    }

    func testReloadProbesDuringTheHierarchyWalkAndCountsTheNewResult() throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        window.addSubview(view)
        let width = view.widthAnchor.constraint(equalToConstant: 20)
        width.isActive = true
        let oid = view.avs_registerOid()

        let scanner = AVS_LayoutIssueScanner.shared
        scanner.ambiguityProbe = { $0 === view }
        let probesBefore = scanner.probeCallCount
        let items = AVS_HierarchyDisplayItemsMaker.subitems(of: window.layer)
        XCTAssertEqual(scanner.probeCallCount, probesBefore, "lazy subitems never probe")
        XCTAssertNil(items.first { $0.viewObject?.oid == oid }?.layoutIssueCount)

        let counter = AVS_LayoutIssueCounter(scanning: true)
        XCTAssertEqual(counter.count(for: view, oid: oid), 1, "the probe result counts in the same walk")
        XCTAssertEqual(scanner.ambiguousCount(forOid: oid), 0, "cache is replaced only on finish")
        counter.finish()
        XCTAssertEqual(scanner.ambiguousCount(forOid: oid), 1)
        XCTAssertEqual(scanner.probeCallCount - probesBefore, 1)
        XCTAssertEqual(view.avs_layoutIssues()?.first?.constraintIDs, [AppViewAutoLayoutConstraint.snapshotID(for: width)])

        let cached = AVS_LayoutIssueCounter(scanning: false)
        XCTAssertEqual(cached.count(for: view, oid: oid), 1)
        cached.finish()
        XCTAssertEqual(scanner.probeCallCount - probesBefore, 1, "a counter without scanning only reads the cache")
        withExtendedLifetime(width) {}
    }

    func testAmbiguousIssueCitesOnlyRowsOfTheView() throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        let parent = UIView()
        parent.translatesAutoresizingMaskIntoConstraints = false
        let child = UIView()
        child.translatesAutoresizingMaskIntoConstraints = false
        window.addSubview(parent)
        parent.addSubview(child)
        let ancestorOnly = parent.heightAnchor.constraint(equalToConstant: 100)
        let own = child.widthAnchor.constraint(equalToConstant: 20)
        let pinned = child.topAnchor.constraint(equalTo: parent.topAnchor)
        let sibling = parent.widthAnchor.constraint(equalToConstant: 100)
        NSLayoutConstraint.activate([ancestorOnly, own, pinned, sibling])
        window.layoutIfNeeded()

        AVS_LayoutIssueScanner.shared.ambiguityProbe = { $0 === child }
        AVS_LayoutIssueScanner.shared.scan(roots: [window])

        let rowIDs = Set(try XCTUnwrap(child.avs_constraints()).compactMap(\.snapshotID))
        let issue = try XCTUnwrap(child.avs_layoutIssues()?.first)
        XCTAssertEqual(issue.kind, .ambiguous)
        XCTAssertFalse(issue.constraintIDs.isEmpty)
        XCTAssertTrue(Set(issue.constraintIDs).isSubset(of: rowIDs), "every cited id is a row of this view")
        XCTAssertFalse(issue.constraintIDs.contains(AppViewAutoLayoutConstraint.snapshotID(for: ancestorOnly)))
        XCTAssertFalse(issue.constraintIDs.contains(AppViewAutoLayoutConstraint.snapshotID(for: sibling)))
        withExtendedLifetime([ancestorOnly, own, pinned, sibling]) {}
    }

    func testEncapsulatedConstraintsNeverReachRowsOrIssues() throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        let parent = UIView()
        let child = UIView()
        child.translatesAutoresizingMaskIntoConstraints = false
        window.addSubview(parent)
        parent.addSubview(child)
        let wrapper = child.widthAnchor.constraint(equalToConstant: 10)
        wrapper.identifier = "UIView-Encapsulated-Layout-Width"
        let real = child.heightAnchor.constraint(equalToConstant: 10)
        real.identifier = "real"
        NSLayoutConstraint.activate([wrapper, real])

        AVS_LayoutIssueScanner.shared.ambiguityProbe = { $0 === child }
        AVS_LayoutIssueScanner.shared.scan(roots: [window])

        // Attribute payload (al_c_c / al_l) as the wire and MCP emit it.
        let constraintsJSON = try XCTUnwrap(
            WireAttributeMapper.mcpJSONObject(from: .customObject(try XCTUnwrap(child.avs_constraints()))) as? [[String: Any]]
        )
        XCTAssertEqual(constraintsJSON.compactMap { $0["identifier"] as? String }, ["real"])
        XCTAssertFalse(constraintsJSON.contains { ($0["identifier"] as? String)?.contains("Encapsulated") == true })
        let issuesJSON = try XCTUnwrap(
            WireAttributeMapper.mcpJSONObject(from: .customObject(try XCTUnwrap(child.avs_layoutIssues()))) as? [[String: Any]]
        )
        let wrapperID = AppViewAutoLayoutConstraint.snapshotID(for: wrapper)
        XCTAssertFalse(constraintsJSON.contains { $0["id"] as? String == wrapperID })
        XCTAssertFalse(issuesJSON.flatMap { $0["constraintIds"] as? [String] ?? [] }.contains(wrapperID))
        withExtendedLifetime((wrapper, real)) {}
    }

    func testEncapsulatedLayoutConstraintIsNotRecorded() {
        let (parent, child) = makePair()
        let constraint = child.widthAnchor.constraint(equalToConstant: 10)
        constraint.identifier = "UIView-Encapsulated-Layout-Width"
        constraint.isActive = true
        let sibling = child.heightAnchor.constraint(equalToConstant: 10)
        sibling.identifier = "UIView-Encapsulated-Layout-Height"
        sibling.isActive = true

        XCTAssertFalse(AVS_LayoutConflictRecorder.shared.record(brokenConstraint: constraint))
        XCTAssertEqual(AVS_LayoutConflictRecorder.shared.recordCount, 0)

        // A real conflict never lists an encapsulated peer.
        let real = child.widthAnchor.constraint(equalToConstant: 20)
        real.isActive = true
        XCTAssertTrue(AVS_LayoutConflictRecorder.shared.record(brokenConstraint: real, conflictingWith: [constraint]))
        let ids = AVS_LayoutConflictRecorder.shared.records(forOid: child.avs_registerOid()).flatMap(\.constraintIDs)
        XCTAssertEqual(ids, [AppViewAutoLayoutConstraint.snapshotID(for: real)])
        XCTAssertNil(UIView().avs_layoutIssues())
        _ = parent
    }

    func testBufferIsCappedToTheNewestConflicts() {
        let recorder = AVS_LayoutConflictRecorder(bufferLimit: 3)
        let (parent, child) = makePair()
        var keep: [NSLayoutConstraint] = []
        for width in 1...5 {
            let constraint = child.widthAnchor.constraint(equalToConstant: CGFloat(width))
            constraint.isActive = true
            keep.append(constraint)
            recorder.record(brokenConstraint: constraint)
        }
        XCTAssertEqual(recorder.recordCount, 3)
        XCTAssertEqual(
            recorder.records(forOid: child.avs_registerOid()).map(\.brokenConstraintID),
            keep.suffix(3).map { AppViewAutoLayoutConstraint.snapshotID(for: $0) }
        )
        _ = (parent, keep)
    }

    func testInstalledConstraintsListsConstraintsBetweenOtherItemsOnly() throws {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        let label = UILabel()
        let box = UIView()
        [label, box].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; root.addSubview($0) }
        let between = box.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 8)
        between.identifier = "between"
        let guideToChild = box.leadingAnchor.constraint(equalTo: root.layoutMarginsGuide.leadingAnchor)
        guideToChild.identifier = "guideToChild"
        let ownWidth = root.widthAnchor.constraint(equalToConstant: 300)
        let childToRoot = label.topAnchor.constraint(equalTo: root.topAnchor)
        let wrapper = box.widthAnchor.constraint(equalTo: label.widthAnchor)
        wrapper.identifier = "UIView-Encapsulated-Layout-Width"
        NSLayoutConstraint.activate([between, guideToChild, ownWidth, childToRoot, wrapper])

        let rows = try XCTUnwrap(root.avs_installedConstraints())
        XCTAssertEqual(Set(rows.compactMap(\.identifier)), ["between", "guideToChild"])
        let betweenRow = try XCTUnwrap(rows.first { $0.identifier == "between" })
        XCTAssertEqual(betweenRow.firstItem?.oid, box.avs_registerOid())
        XCTAssertEqual(betweenRow.secondItem?.oid, label.avs_registerOid())
        XCTAssertEqual(betweenRow.firstItemType, .view)
        XCTAssertNil(label.avs_installedConstraints(), "nothing is stored on a leaf")

        let json = try XCTUnwrap(WireAttributeMapper.mcpJSONObject(from: .customObject(rows)) as? [[String: Any]])
        XCTAssertEqual(json.count, 2)
        withExtendedLifetime([between, guideToChild, ownWidth, childToRoot, wrapper]) {}
    }

    func testRealEngineConflictIsRecorded() throws {
        XCTAssertTrue(AVS_LayoutConflictRecorder.shared.installIfAvailable(), "engine callback must be swizzled")
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        let box = UIView()
        box.translatesAutoresizingMaskIntoConstraints = false
        window.addSubview(box)
        let narrow = box.widthAnchor.constraint(equalToConstant: 80)
        let wide = box.widthAnchor.constraint(equalToConstant: 160)
        NSLayoutConstraint.activate([
            box.leadingAnchor.constraint(equalTo: window.leadingAnchor),
            box.topAnchor.constraint(equalTo: window.topAnchor),
            box.heightAnchor.constraint(equalToConstant: 40),
            narrow,
            wide,
        ])
        window.layoutIfNeeded()

        let oid = box.avs_registerOid()
        XCTAssertEqual(AVS_LayoutConflictRecorder.shared.conflictCount(forOid: oid), 1)
        let ids = Set(try XCTUnwrap(box.avs_layoutIssues()?.first(where: { $0.kind == .conflict })).constraintIDs)
        XCTAssertTrue(ids.isSuperset(of: [narrow, wide].map { AppViewAutoLayoutConstraint.snapshotID(for: $0) }))
        withExtendedLifetime(window) {}
    }

    func testRealEngineConflictActivatedBeforeTheViewJoinsAWindowIsRecorded() throws {
        XCTAssertTrue(AVS_LayoutConflictRecorder.shared.installIfAvailable())
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        let box = UIView()
        box.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(box)
        let narrow = box.widthAnchor.constraint(equalToConstant: 80)
        let wide = box.widthAnchor.constraint(equalToConstant: 160)
        NSLayoutConstraint.activate([
            box.leadingAnchor.constraint(equalTo: root.layoutMarginsGuide.leadingAnchor),
            box.topAnchor.constraint(equalTo: root.topAnchor),
            box.heightAnchor.constraint(equalToConstant: 40),
            narrow,
            wide,
        ])
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        let controller = UIViewController()
        controller.view = root
        window.rootViewController = controller
        window.makeKeyAndVisible()
        window.layoutIfNeeded()

        XCTAssertEqual(AVS_LayoutConflictRecorder.shared.conflictCount(forOid: box.avs_registerOid()), 1)
        withExtendedLifetime((window, narrow, wide)) {}
    }

    func testInstallIsNoOpWhenSelectorMissing() {
        let recorder = AVS_LayoutConflictRecorder()
        XCTAssertFalse(recorder.install(classNames: ["AVSNoSuchEngineClass"], selectorName: selectorName))
        XCTAssertFalse(recorder.install(classNames: ["NSObject"], selectorName: selectorName))
    }

    func testInstalledSwizzleRecordsAndCallsOriginal() throws {
        let recorder = AVS_LayoutConflictRecorder()
        XCTAssertTrue(recorder.install(classNames: ["AVSLayoutConflictDummyEngine"], selectorName: selectorName))
        // Idempotent: a second install does not stack another wrapper.
        XCTAssertTrue(recorder.install(classNames: ["AVSLayoutConflictDummyEngine"], selectorName: selectorName))

        let (parent, child) = makePair()
        let constraint = child.widthAnchor.constraint(equalToConstant: 40)
        constraint.isActive = true
        let engine = DummyEngine()
        // Message through the ObjC runtime: a direct Swift call would bypass the swizzled IMP.
        let selector = NSSelectorFromString(selectorName)
        let imp = try XCTUnwrap(class_getMethodImplementation(DummyEngine.self, selector))
        typealias Fn = @convention(c) (AnyObject, Selector, AnyObject?, AnyObject?, AnyObject?) -> Void
        unsafeBitCast(imp, to: Fn.self)(engine, selector, nil, constraint, [] as NSArray)

        XCTAssertEqual(engine.originalCalls, 1)
        XCTAssertEqual(recorder.conflictCount(forOid: child.avs_registerOid()), 1)
        _ = parent
    }

    // MARK: Ambiguous scan cache

    func testScanSkipsViewsOutsideWindowAndAutoresizingMaskViews() throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        let qualifying = UIView()
        qualifying.translatesAutoresizingMaskIntoConstraints = false
        let maskView = UIView()   // translatesAutoresizingMaskIntoConstraints defaults to true
        window.addSubview(qualifying)
        window.addSubview(maskView)
        let detached = UIView()
        detached.translatesAutoresizingMaskIntoConstraints = false

        XCTAssertTrue(AVS_LayoutIssueScanner.shouldProbe(qualifying))
        XCTAssertFalse(AVS_LayoutIssueScanner.shouldProbe(maskView))
        XCTAssertFalse(AVS_LayoutIssueScanner.shouldProbe(detached))

        let scanner = AVS_LayoutIssueScanner.shared
        var probed: [ObjectIdentifier] = []
        let probesBefore = scanner.probeCallCount
        scanner.ambiguityProbe = { view in
            probed.append(ObjectIdentifier(view))
            return view === qualifying
        }
        scanner.scan(roots: [window, detached])

        XCTAssertEqual(probed, [ObjectIdentifier(qualifying)], "one probe per qualifying view")
        XCTAssertEqual(scanner.probeCallCount - probesBefore, 1)
        let oid = qualifying.avs_registerOid()
        XCTAssertEqual(scanner.ambiguousCount(forOid: oid), 1)
        XCTAssertEqual(scanner.ambiguousIssues(forOid: oid).first?.title, "Ambiguous layout")
        XCTAssertEqual(scanner.layoutIssueCount(forOid: oid), 1)
    }

    func testHierarchyWithoutScanFlagDoesNotProbeAndKeepsPreviousCache() throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        window.addSubview(view)

        let scanner = AVS_LayoutIssueScanner.shared
        scanner.ambiguityProbe = { _ in true }
        let probesBefore = scanner.probeCallCount
        scanner.scan(roots: [window])
        XCTAssertEqual(scanner.probeCallCount - probesBefore, 1)
        let oid = view.avs_registerOid()
        XCTAssertEqual(scanner.ambiguousCount(forOid: oid), 1)

        // Request without the flag (later snapshots, detail): cache only.
        _ = AVHierarchyInfo.staticInfo(withAppViewVersion: nil, scanLayoutIssues: false)
        _ = AVHierarchyInfo.staticInfo(withAppViewVersion: nil)
        _ = view.avs_layoutIssues()
        _ = view.avs_constraints()
        XCTAssertEqual(scanner.probeCallCount - probesBefore, 1, "hasAmbiguousLayout must not run without the scan flag")
        XCTAssertEqual(scanner.ambiguousCount(forOid: oid), 1, "previous cache survives")
        XCTAssertEqual(view.avs_layoutIssues()?.first?.kind, .ambiguous)
        XCTAssertEqual(scanner.layoutIssueCount(forOid: oid), 1)
    }
}

#endif
