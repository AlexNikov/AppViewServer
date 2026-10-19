import XCTest
@testable import AppViewServer
@testable import AppViewShared

/// Wire v2 + MCP JSON for the two Auto Layout attributes (`al_c_c`, `al_l`) and `layoutIssueCount`.
final class AppViewLayoutIssueWireTests: XCTestCase {

    private func makeConstraint(id: String, effective: Bool, firstOid: UInt = 11) -> AppViewAutoLayoutConstraint {
        let first = AppViewObject()
        first.oid = firstOid
        first.memoryAddress = "0xA"
        first.classChainList = ["UILabel", "UIView"]
        let constraint = AppViewAutoLayoutConstraint()
        constraint.snapshotID = id
        constraint.effective = effective
        constraint.active = effective
        constraint.firstItem = first
        constraint.firstItemType = .self
        constraint.firstAttribute = NSLayoutConstraint.Attribute.width.rawValue
        constraint.relation = .greaterThanOrEqual
        constraint.secondItemType = .nil
        constraint.secondAttribute = 0
        constraint.multiplier = 1
        constraint.constant = 120
        constraint.priority = 750
        constraint.identifier = "labelWidth"
        return constraint
    }

    private func jsonRoundTrip(_ attribute: AppViewAttribute) throws -> AppViewAttribute {
        let wire = WireAttributeMapper.wireAttribute(from: attribute)
        let data = try AVWireCodecV2.encodeJSON(wire)
        let decoded = try AVWireCodecV2.decodeJSON(WireAttribute.self, from: data)
        return WireAttributeMapper.appviewAttribute(from: decoded)
    }

    func testConstraintsAndIssuesRoundTripWithMatchingIDs() throws {
        let effective = makeConstraint(id: "0x600001", effective: true)
        let broken = makeConstraint(id: "0x600002", effective: false, firstOid: 12)

        let constraintsAttr = AppViewAttribute()
        constraintsAttr.identifier = AppViewAttr_AutoLayout_Constraints_Constraints
        constraintsAttr.attrType = .customObj
        constraintsAttr.value = .customObject([effective, broken])

        let issuesAttr = AppViewAttribute()
        issuesAttr.identifier = AppViewAttr_AutoLayout_Issues_Issues
        issuesAttr.attrType = .customObj
        issuesAttr.value = .customObject([
            AppViewLayoutIssue(kind: .ambiguous, title: "Ambiguous layout", constraintIDs: ["0x600001"]),
            AppViewLayoutIssue(kind: .conflict, title: "Conflicting constraints", constraintIDs: ["0x600002", "0x600001"]),
        ])

        // Wire: structured values, never String(describing:).
        guard case .autoLayoutConstraints? = WireAttributeMapper.wireAttribute(from: constraintsAttr).value,
              case .layoutIssues? = WireAttributeMapper.wireAttribute(from: issuesAttr).value else {
            XCTFail("expected structured wire values")
            return
        }

        let restoredConstraints = try jsonRoundTrip(constraintsAttr)
        let restoredIssues = try jsonRoundTrip(issuesAttr)

        guard case .customObject(let rawConstraints)? = restoredConstraints.value,
              let rows = rawConstraints as? [AppViewAutoLayoutConstraint],
              case .customObject(let rawIssues)? = restoredIssues.value,
              let issues = rawIssues as? [AppViewLayoutIssue] else {
            XCTFail("expected models after decode")
            return
        }
        XCTAssertEqual(rows.map(\.snapshotID), ["0x600001", "0x600002"])
        XCTAssertEqual(rows[1].effective, false)
        XCTAssertEqual(rows[0].firstItem?.oid, 11)
        XCTAssertEqual(rows[0].firstItem?.rawClassName(), "UILabel")
        XCTAssertEqual(rows[0].relation, .greaterThanOrEqual)
        XCTAssertEqual(rows[0].constant, 120)
        XCTAssertEqual(rows[0].identifier, "labelWidth")
        XCTAssertEqual(issues.map(\.kind), [.ambiguous, .conflict])
        XCTAssertEqual(issues[1].constraintIDs, ["0x600002", "0x600001"])

        // Every issue id matches a constraint row.
        let rowIDs = Set(rows.compactMap(\.snapshotID))
        for issue in issues {
            XCTAssertTrue(Set(issue.constraintIDs).isSubset(of: rowIDs))
        }
    }

    func testEmptyStringArraysStayStringLists() {
        // An empty array casts to every element type; it must not turn into a constraints payload.
        XCTAssertEqual(WireAttributeMapper.wireValue(from: .customObject([String]())), .strings([]))
        XCTAssertEqual(WireAttributeMapper.wireValue(from: .customObject(NSArray())), .strings([]))
        XCTAssertEqual(WireAttributeMapper.wireValue(from: .customObject([String]())).map { WireAttributeMapper.mcpJSONObject(from: $0) as? [String] }, [])
        XCTAssertEqual(WireAttributeMapper.wireValue(from: .customObject(["a"])), .strings(["a"]))
    }

    func testMCPJSONObjectIsArrayOfObjectsNotString() throws {
        let broken = makeConstraint(id: "0x600002", effective: false)
        let constraintsJSON = WireAttributeMapper.mcpJSONObject(from: .customObject([broken]))
        let rows = try XCTUnwrap(constraintsJSON as? [[String: Any]])
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0]["id"] as? String, "0x600002")
        XCTAssertEqual(rows[0]["effective"] as? Bool, false)
        XCTAssertEqual((rows[0]["firstItem"] as? [String: Any])?["oid"] as? UInt, 11)

        let issue = AppViewLayoutIssue(kind: .conflict, title: "Conflicting constraints", constraintIDs: ["0x600002"])
        let issuesJSON = WireAttributeMapper.mcpJSONObject(from: .customObject([issue]))
        let issueRows = try XCTUnwrap(issuesJSON as? [[String: Any]])
        XCTAssertEqual(issueRows[0]["kind"] as? String, "conflict")
        XCTAssertEqual(issueRows[0]["title"] as? String, "Conflicting constraints")
        XCTAssertEqual(issueRows[0]["constraintIds"] as? [String], ["0x600002"])
        XCTAssertNil(issueRows[0]["axis"])

        // Same ids across both payloads, and the payloads are valid JSON.
        XCTAssertTrue(JSONSerialization.isValidJSONObject(constraintsJSON))
        XCTAssertTrue(JSONSerialization.isValidJSONObject(issuesJSON))
        let ids = Set(rows.compactMap { $0["id"] as? String })
        XCTAssertTrue(Set(issueRows.flatMap { $0["constraintIds"] as? [String] ?? [] }).isSubset(of: ids))
    }

    func testLayoutIssueCountSurvivesHierarchyWireRoundTrip() throws {
        let item = AppViewDisplayItem()
        item.frame = CGRect(x: 0, y: 0, width: 10, height: 10)
        item.bounds = item.frame
        item.layoutIssueCount = 3
        let quiet = AppViewDisplayItem()
        quiet.layoutIssueCount = 0
        item.subitems = [quiet]

        let wire = WireHierarchyMapper.wireItem(from: item)
        XCTAssertEqual(wire.layoutIssueCount, 3)
        XCTAssertNil(wire.subitems?.first?.layoutIssueCount, "zero is omitted from the wire")

        let data = try AVWireCodecV2.encodeJSON(wire)
        let restored = WireHierarchyMapper.appviewItem(from: try AVWireCodecV2.decodeJSON(WireDisplayItem.self, from: data))
        XCTAssertEqual(restored.layoutIssueCount, 3)
        XCTAssertNil(restored.subitems?.first?.layoutIssueCount)
    }

    func testOldHierarchyJSONWithoutLayoutIssueCountStillDecodes() throws {
        let wire = WireDisplayItem(
            oid: 5, frame: Rect(.zero), bounds: Rect(.zero), isHidden: false, alpha: 1, shouldCaptureImage: true
        )
        var object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: try AVWireCodecV2.encodeJSON(wire)) as? [String: Any]
        )
        object.removeValue(forKey: "layoutIssueCount")
        let data = try JSONSerialization.data(withJSONObject: object)
        let decoded = try AVWireCodecV2.decodeJSON(WireDisplayItem.self, from: data)
        XCTAssertNil(decoded.layoutIssueCount)
    }

    func testHierarchyRequestScanFlagRoundTrip() throws {
        let scanning = WireClientRequestPayload.hierarchy(
            WireHierarchyRequestParams(clientVersion: "1.0.0", scanLayoutIssues: true)
        ).envelope(requestType: UInt32(AppViewRequestTypeHierarchy), tag: 1)
        let decoded = try AVWireCodecV2.decodeJSON(WireRequestEnvelope.self, from: try AVWireCodecV2.encodeJSON(scanning))
        XCTAssertEqual(decoded.hierarchyParams?.scanLayoutIssues, true)
        let object = WireRequestResponseMapper.requestObject(from: decoded) as? [String: Any]
        XCTAssertEqual(object?["scanLayoutIssues"] as? Bool, true)

        let plain = WireClientRequestPayload.hierarchy(WireHierarchyRequestParams(clientVersion: "1.0.0"))
            .envelope(requestType: UInt32(AppViewRequestTypeHierarchy), tag: 2)
        let plainObject = WireRequestResponseMapper.requestObject(from: plain) as? [String: Any]
        XCTAssertNil(plainObject?["scanLayoutIssues"], "no flag means no scan")
    }

    func testIssueClickSelectsMatchingRowsAndSecondClickClears() {
        let ambiguous = AppViewLayoutIssue(kind: .ambiguous, title: "Ambiguous layout", constraintIDs: ["0x1", "0x2"])
        let conflict = AppViewLayoutIssue(kind: .conflict, title: "Conflicting constraints", constraintIDs: ["0x2"])
        var highlight = AppViewLayoutIssueHighlight()

        XCTAssertTrue(highlight.toggle(ambiguous))
        XCTAssertEqual(highlight.issueKey, "ambiguous:0x1,0x2")
        XCTAssertTrue(highlight.highlights(snapshotID: "0x1"))
        XCTAssertTrue(highlight.highlights(snapshotID: "0x2"))
        XCTAssertFalse(highlight.highlights(snapshotID: "0x3"))
        XCTAssertFalse(highlight.highlights(snapshotID: nil))

        XCTAssertFalse(highlight.toggle(ambiguous), "the same ambiguous issue clears only the click")
        XCTAssertFalse(highlight.highlights(snapshotID: "0x1"))
        XCTAssertFalse(highlight.highlights(snapshotID: "0x2"))

        highlight.setConflictIDs(["0x2"])
        XCTAssertFalse(highlight.toggle(conflict), "a conflict click does not clear the conflict rows")
        XCTAssertTrue(highlight.highlights(snapshotID: "0x2"))
        XCTAssertFalse(highlight.toggle(conflict))
        highlight.clearClick()
        XCTAssertTrue(highlight.highlights(snapshotID: "0x2"), "the conflict row stays highlighted")

        highlight.clear()
        XCTAssertNil(highlight.issueKey)
        XCTAssertFalse(highlight.highlights(snapshotID: "0x2"))
    }

    func testConflictRowsAreHighlightedImmediatelyAndSurviveAClickClear() {
        var group = AppViewAttributesGroup()
        group.identifier = AppViewAttrGroup_AutoLayout
        var section = AppViewAttributesSection()
        section.identifier = AppViewAttrSec_AutoLayout_Issues
        let attribute = AppViewAttribute()
        attribute.identifier = AppViewAttr_AutoLayout_Issues_Issues
        attribute.value = .customObject([
            AppViewLayoutIssue(kind: .conflict, title: "Conflicting constraints", constraintIDs: ["0xA", "0xB"]),
            AppViewLayoutIssue(kind: .ambiguous, title: "Ambiguous layout", constraintIDs: ["0xC"]),
        ])
        section.attributes = [attribute]
        group.attrSections = [section]

        var highlight = AppViewLayoutIssueHighlight()
        highlight.setConflictIDs(AppViewLayoutIssueHighlight.conflictIDs(in: [group]))
        XCTAssertEqual(highlight.constraintIDs, ["0xA", "0xB"])
        XCTAssertFalse(highlight.highlights(snapshotID: "0xC"))

        highlight.clearClick()
        XCTAssertEqual(highlight.constraintIDs, ["0xA", "0xB"])
    }
}
