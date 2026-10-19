import XCTest
@testable import AppViewServer
@testable import AppViewShared

final class AppViewServerSharedTests: XCTestCase {
    /// `NSValue(cgRect:)` is UIKit-only; the macOS test target needs `NSValue(rect:)`.
    private static func rectValue(_ rect: CGRect) -> NSValue {
        #if os(macOS)
        return NSValue(rect: rect)
        #else
        return NSValue(cgRect: rect)
        #endif
    }

    func testObjCExceptionBridgeCatchesRaisedException() {
        let exception = AppViewObjCExceptionBridge.catchException {
            NSException(name: NSExceptionName.genericException, reason: "appview-test", userInfo: nil).raise()
        }
        XCTAssertNotNil(exception)
        XCTAssertEqual(exception?.reason, "appview-test")
    }

    func testObjCExceptionBridgeTryExecuteThrowsNSError() {
        XCTAssertThrowsError(try AppViewObjCExceptionBridge.tryExecute {
            NSException(name: NSExceptionName.genericException, reason: "setter-fail", userInfo: nil).raise()
        }) { error in
            let ns = error as NSError
            XCTAssertEqual(ns.domain, AppViewErrorDomain)
            XCTAssertEqual(ns.code, AppViewSharedErrCode.exception.rawValue)
            XCTAssertEqual(ns.localizedRecoverySuggestion, "setter-fail")
        }
    }

    func testAppViewAttrTypeMapping() {
        XCTAssertEqual(AppViewAttrTypeMapping.description(for: 14), "BOOL")
        XCTAssertEqual(AppViewAttrTypeMapping.description(for: 20), "CGRect")
        XCTAssertEqual(AppViewAttrType.description(for: 14), "BOOL")
        XCTAssertEqual(AppViewAttrType(rawValue: 20)?.typeDescription, "CGRect")
    }

    func testAppViewObjectWireRoundTrip() throws {
        let obj = AppViewObject()
        obj.oid = 42
        obj.memoryAddress = "0xdeadbeef"
        obj.classChainList = ["UILabel", "UIView"]

        let wire = WireRequestResponseMapper.wireObject(from: obj)
        let restored = WireRequestResponseMapper.appviewObject(from: wire)
        XCTAssertEqual(restored.oid, 42)
        XCTAssertEqual(restored.rawClassName(), "UILabel")
    }

    func testAppViewAttributeWireRoundTrip() throws {
        let attr = AppViewAttribute()
        attr.identifier = "test_id"
        attr.displayTitle = "Title"
        attr.attrType = .CGRect
        attr.value = .cgRect(CGRect(x: 1, y: 2, width: 3, height: 4))

        let wire = WireAttributeMapper.wireAttribute(from: attr)
        let decoded = WireAttributeMapper.appviewAttribute(from: wire)
        XCTAssertEqual(decoded.identifier, "test_id")
        XCTAssertEqual(decoded.attrType, .CGRect)
    }

    func testObjectRegistryAssignsOidAndResolvesObject() {
        let registry = AVS_ObjectRegistry.sharedInstance
        let object = NSObject()
        let oid = registry.addObject(object)
        XCTAssertGreaterThan(oid, 0)
        XCTAssertIdentical(registry.objectWithOid(oid), object)
    }

    func testObjectRegistryReturnsNilForInvalidOid() {
        let registry = AVS_ObjectRegistry.sharedInstance
        XCTAssertNil(registry.objectWithOid(999_999))
    }

    func testHierarchyResponseJSONRoundTrip() throws {
        let child = AppViewDisplayItem()
        child.frame = CGRect(x: 1, y: 2, width: 3, height: 4)
        child.bounds = CGRect(x: 0, y: 0, width: 3, height: 4)
        child.viewObject = {
            let object = AppViewObject()
            object.oid = 7
            object.memoryAddress = "0x1"
            object.classChainList = ["UIView", "UIResponder"]
            return object
        }()

        let root = AppViewDisplayItem()
        root.subitems = [child]
        root.frame = CGRect(x: 0, y: 0, width: 320, height: 568)
        root.bounds = root.frame
        root.viewObject = {
            let object = AppViewObject()
            object.oid = 1
            object.memoryAddress = "0x10"
            object.classChainList = ["UIWindow", "UIView"]
            return object
        }()

        let hierarchy = AppViewHierarchyInfo()
        hierarchy.serverVersion = appviewServerVersionInt32
        hierarchy.displayItems = [root]
        hierarchy.collapsedClassList = ["UITableViewCell"]
        hierarchy.colorAlias = ["systemBlue": NSNumber(value: 0x007AFF)]

        var attachment = AppViewConnectionResponseAttachment()
        attachment.data = hierarchy
        attachment.appviewServerVersion = appviewServerVersionInt32

        let envelope = try XCTUnwrap(
            WireRequestResponseMapper.responseEnvelope(
                from: attachment,
                requestType: UInt32(AppViewRequestTypeHierarchy),
                tag: 1
            )
        )
        let jsonData = try AVWireCodecV2.encodeJSON(envelope)
        let decodedEnvelope = try AVWireCodecV2.decodeJSON(WireResponseEnvelope.self, from: jsonData)
        var roundtrip = AppViewConnectionResponseAttachment()
        XCTAssertTrue(WireRequestResponseMapper.applyResponseEnvelope(decodedEnvelope, to: &roundtrip))

        let info = roundtrip.data as? AppViewHierarchyInfo
        XCTAssertNotNil(info)
        XCTAssertEqual(info?.displayItems?.count, 1)
        XCTAssertEqual(info?.displayItems?.first?.subitems?.count, 1)
        XCTAssertEqual(info?.displayItems?.first?.subitems?.first?.frame, child.frame)
        XCTAssertEqual(info?.displayItems?.first?.subitems?.first?.viewObject?.oid, 7)
        XCTAssertEqual(AppViewDisplayItem.flatItems(fromHierarchicalItems: info?.displayItems ?? []).count, 2)
    }

    func testWireAttributeMapperRoundTrip() throws {
        let attr = AppViewAttribute()
        attr.identifier = "frame"
        attr.displayTitle = "Frame"
        attr.attrType = .CGRect
        attr.value = .cgRect(CGRect(x: 1, y: 2, width: 3, height: 4))

        let wire = WireAttributeMapper.wireAttribute(from: attr)
        let decoded = WireAttributeMapper.appviewAttribute(from: wire)
        XCTAssertEqual(decoded.identifier, "frame")
        XCTAssertEqual(decoded.attrType, .CGRect)
        guard case .cgRect(let rect)? = decoded.value else {
            XCTFail("expected cgRect value")
            return
        }
        XCTAssertEqual(rect, CGRect(x: 1, y: 2, width: 3, height: 4))
    }

    func testWireDetailPayloadRoundTrip() throws {
        let attr = AppViewAttribute()
        attr.identifier = "hidden"
        attr.displayTitle = "Hidden"
        attr.attrType = .BOOL
        attr.value = .bool(true)

        var section = AppViewAttributesSection()
        section.identifier = "sec"
        section.attributes = [attr]

        var group = AppViewAttributesGroup()
        group.identifier = "group"
        group.attrSections = [section]

        var detail = AppViewDisplayItemDetail()
        detail.displayItemOid = 99
        detail.customDisplayTitle = "Title"
        detail.attributesGroupList = [group]
        detail.frameValue = Self.rectValue(CGRect(x: 0, y: 0, width: 10, height: 20))

        let payload = WireDetailMapper.wireDetail(from: detail)
        let data = try JSONEncoder().encode(
            WireResponseEnvelope(requestType: 203, tag: 1, detail: payload)
        )
        let envelope = try JSONDecoder().decode(WireResponseEnvelope.self, from: data)
        let restored = WireDetailMapper.appviewDetail(from: try XCTUnwrap(envelope.detail))

        XCTAssertEqual(restored.displayItemOid, 99)
        XCTAssertEqual(restored.customDisplayTitle, "Title")
        XCTAssertEqual(restored.attributesGroupList?.count, 1)
        XCTAssertEqual(restored.attributesGroupList?.first?.attrSections?.first?.attributes?.first?.identifier, "hidden")
        XCTAssertEqual(restored.frameValue?.appviewCGRectValue.width, 10)
    }

    func testWireAppInfoRoundTrip() throws {
        let app = AppViewAppInfo()
        app.appName = "Demo"
        app.serverVersion = 10004
        app.deviceType = .simulator
        app.screenWidth = 390
        app.screenHeight = 844

        let wire = WireRequestResponseMapper.wireAppInfo(from: app)
        let data = try JSONEncoder().encode(
            WireResponseEnvelope(requestType: 201, tag: 1, app: wire)
        )
        let envelope = try JSONDecoder().decode(WireResponseEnvelope.self, from: data)
        var attachment = AppViewConnectionResponseAttachment()
        XCTAssertTrue(WireRequestResponseMapper.applyResponseEnvelope(try XCTUnwrap(envelope), to: &attachment))
        let restored = attachment.data as? AppViewAppInfo
        XCTAssertEqual(restored?.appName, "Demo")
        XCTAssertEqual(restored?.deviceType, .simulator)
    }

    func testWirePingResponseRoundTrip() throws {
        var attachment = AppViewConnectionResponseAttachment()
        attachment.appIsInBackground = true
        let wire = try XCTUnwrap(
            WireRequestResponseMapper.responseEnvelope(from: attachment, requestType: 200, tag: 1)
        )
        XCTAssertEqual(wire.ping?.appIsInBackground, true)
        var decoded = AppViewConnectionResponseAttachment()
        XCTAssertTrue(WireRequestResponseMapper.applyResponseEnvelope(wire, to: &decoded))
        XCTAssertTrue(decoded.appIsInBackground)
    }

    func testWirePushEnvelopeRoundTrip() throws {
        let envelope = WirePushEnvelope(pushType: AppViewWirePushTypes.cancelHierarchyDetails)
        let data = try JSONEncoder().encode(envelope)
        let decoded = try JSONDecoder().decode(WirePushEnvelope.self, from: data)
        XCTAssertEqual(decoded.pushType, 304)
    }

    func testWireHierarchyPayloadPreservesAppInfo() throws {
        let app = AppViewAppInfo()
        app.screenWidth = 393
        app.screenHeight = 852
        app.screenScale = 3

        let info = AppViewHierarchyInfo()
        info.serverVersion = appviewServerVersionInt32
        info.appInfo = app
        info.displayItems = []

        let payload = WireHierarchyMapper.wirePayload(from: info)
        let restored = WireHierarchyMapper.appviewHierarchy(from: payload)
        XCTAssertEqual(restored.appInfo?.screenWidth, 393)
        XCTAssertEqual(restored.appInfo?.screenHeight, 852)
        XCTAssertEqual(restored.appInfo?.screenScale, 3)
    }

    func testWireAppViewFileRoundTrip() throws {
        let root = AppViewDisplayItem()
        root.frame = CGRect(x: 0, y: 0, width: 320, height: 568)
        root.bounds = root.frame
        root.viewObject = {
            let object = AppViewObject()
            object.oid = 1
            object.classChainList = ["UIWindow"]
            return object
        }()

        let info = AppViewHierarchyInfo()
        info.serverVersion = appviewServerVersionInt32
        info.displayItems = [root]
        let app = AppViewAppInfo()
        app.screenWidth = 320
        app.screenHeight = 568
        info.appInfo = app

        var file = AppViewHierarchyFile()
        file.serverVersion = info.serverVersion
        file.hierarchyInfo = info
        file.soloScreenshots = [NSNumber(value: 1): Data([0x01, 0x02])]

        let data = try WireAppViewFileCodec.data(from: file)
        XCTAssertTrue(WireAppViewFileCodec.isV2Format(data))
        let restored = try WireAppViewFileCodec.appviewHierarchyFile(from: data)
        XCTAssertEqual(restored.serverVersion, file.serverVersion)
        XCTAssertEqual(restored.soloScreenshots?[NSNumber(value: 1)], Data([0x01, 0x02]))
        XCTAssertEqual(restored.hierarchyInfo?.displayItems?.count, 1)
        XCTAssertEqual(restored.hierarchyInfo?.appInfo?.screenWidth, 320)
        XCTAssertEqual(restored.hierarchyInfo?.appInfo?.screenHeight, 568)
    }

    /// Full `.appview` export path used by mac client: `AVWireCodec.archive` → `loadHierarchyFile` + `verify`.
    func testAppViewDocumentExportRoundTrip() throws {
        let child = AppViewDisplayItem()
        child.frame = CGRect(x: 10, y: 20, width: 100, height: 40)
        child.bounds = child.frame
        child.layerObject = {
            let object = AppViewObject()
            object.oid = 42
            object.classChainList = ["CALayer"]
            return object
        }()
        child.viewObject = {
            let object = AppViewObject()
            object.oid = 43
            object.classChainList = ["UILabel"]
            return object
        }()

        let root = AppViewDisplayItem()
        root.frame = CGRect(x: 0, y: 0, width: 320, height: 568)
        root.bounds = root.frame
        root.representedAsKeyWindow = true
        root.layerObject = {
            let object = AppViewObject()
            object.oid = 7
            object.classChainList = ["UIWindow"]
            return object
        }()
        root.subitems = [child]
        var frameAttr = AppViewAttribute()
        frameAttr.identifier = "frame"
        frameAttr.displayTitle = "Frame"
        frameAttr.attrType = .CGRect
        frameAttr.value = .cgRect(CGRect(x: 0, y: 0, width: 320, height: 568))
        var frameSection = AppViewAttributesSection()
        frameSection.identifier = "frame_sec"
        frameSection.attributes = [frameAttr]
        var frameGroup = AppViewAttributesGroup()
        frameGroup.identifier = "layout"
        frameGroup.attrSections = [frameSection]
        root.attributesGroupList = [frameGroup]
        var customAttr = AppViewAttribute()
        customAttr.identifier = "custom"
        customAttr.displayTitle = "Note"
        customAttr.attrType = .NSString
        customAttr.value = .string("hello")
        var customSection = AppViewAttributesSection()
        customSection.identifier = "custom_sec"
        customSection.attributes = [customAttr]
        var customGroup = AppViewAttributesGroup()
        customGroup.identifier = "custom"
        customGroup.userCustomTitle = "Custom"
        customGroup.attrSections = [customSection]
        root.customAttrGroupList = [customGroup]

        let info = AppViewHierarchyInfo()
        info.serverVersion = appviewServerVersionInt32
        info.displayItems = [root]
        info.collapsedClassList = ["UILabel"]
        let app = AppViewAppInfo()
        app.appName = "ExportDemo"
        app.osDescription = "18.2"
        app.screenWidth = 320
        app.screenHeight = 568
        info.appInfo = app

        let soloBlob = Data(repeating: 0xAB, count: 16)
        let groupBlob = Data(repeating: 0xCD, count: 24)
        var file = AppViewHierarchyFile()
        file.serverVersion = info.serverVersion
        file.hierarchyInfo = info
        // Export keys screenshots by layer oid (fallback view oid) — same as AVExportManager.
        file.soloScreenshots = [
            NSNumber(value: 7): soloBlob,
            NSNumber(value: 42): Data([0x11, 0x22]),
        ]
        file.groupScreenshots = [
            NSNumber(value: 7): groupBlob,
            NSNumber(value: 42): Data([0x33, 0x44]),
        ]

        XCTAssertNil(AppViewHierarchyFile.verify(file))

        let archived = try AVWireCodec.archive(hierarchyFile: file)
        XCTAssertTrue(WireAppViewFileCodec.isV2Format(archived))
        XCTAssertGreaterThan(archived.count, 4)

        let restored = try AVWireCodec.loadHierarchyFile(from: archived)
        XCTAssertNil(AppViewHierarchyFile.verify(restored))
        XCTAssertEqual(restored.serverVersion, appviewServerVersionInt32)
        XCTAssertEqual(restored.hierarchyInfo?.appInfo?.appName, "ExportDemo")
        XCTAssertEqual(restored.hierarchyInfo?.appInfo?.osDescription, "18.2")
        XCTAssertEqual(restored.hierarchyInfo?.collapsedClassList, ["UILabel"])
        XCTAssertEqual(restored.hierarchyInfo?.displayItems?.count, 1)
        XCTAssertEqual(restored.hierarchyInfo?.displayItems?.first?.layerObject?.oid, 7)
        XCTAssertTrue(restored.hierarchyInfo?.displayItems?.first?.representedAsKeyWindow == true)
        XCTAssertEqual(restored.hierarchyInfo?.displayItems?.first?.subitems?.count, 1)
        XCTAssertEqual(restored.hierarchyInfo?.displayItems?.first?.subitems?.first?.layerObject?.oid, 42)
        XCTAssertEqual(restored.hierarchyInfo?.displayItems?.first?.subitems?.first?.viewObject?.oid, 43)
        XCTAssertEqual(restored.soloScreenshots?[NSNumber(value: 7)], soloBlob)
        XCTAssertEqual(restored.groupScreenshots?[NSNumber(value: 7)], groupBlob)
        XCTAssertEqual(restored.soloScreenshots?[NSNumber(value: 42)], Data([0x11, 0x22]))
        XCTAssertEqual(restored.groupScreenshots?[NSNumber(value: 42)], Data([0x33, 0x44]))
        let restoredRoot = try XCTUnwrap(restored.hierarchyInfo?.displayItems?.first)
        XCTAssertEqual(restoredRoot.attributesGroupList?.count, 1)
        XCTAssertEqual(restoredRoot.attributesGroupList?.first?.identifier, "layout")
        XCTAssertEqual(
            restoredRoot.attributesGroupList?.first?.attrSections?.first?.attributes?.first?.displayTitle,
            "Frame"
        )
        XCTAssertEqual(restoredRoot.customAttrGroupList?.first?.userCustomTitle, "Custom")
        XCTAssertEqual(
            restoredRoot.customAttrGroupList?.first?.attrSections?.first?.attributes?.first?.displayTitle,
            "Note"
        )
    }

    func testAppViewHierarchyFileVerifyRejectsLegacyVersion() {
        var file = AppViewHierarchyFile()
        file.serverVersion = 6
        file.hierarchyInfo = AppViewHierarchyInfo()
        let error = AppViewHierarchyFile.verify(file)
        XCTAssertNotNil(error)
        XCTAssertEqual(error?.code, AppViewSharedErrCode.serverVersionTooLow.rawValue)
    }

    func testAppViewDocumentRejectsLegacyMagic() {
        let legacy = Data("LK01".utf8) + Data([0x00, 0x01, 0x02])
        XCTAssertThrowsError(try AVWireCodec.loadHierarchyFile(from: legacy)) { error in
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, appviewErrorDomain)
            XCTAssertEqual(nsError.code, AppViewSharedErrCode.unsupportedFileType.rawValue)
        }
    }

    /// Live trees often carry NaN frames; export must still archive (JSONEncoder rejects NaN).
    func testAppViewDocumentExportSanitizesNaNGeometry() throws {
        let root = AppViewDisplayItem()
        root.frame = CGRect(x: Double.nan, y: .infinity, width: -Double.nan, height: 100)
        root.bounds = root.frame
        root.alpha = Float.nan
        root.layerObject = {
            let object = AppViewObject()
            object.oid = 9
            object.classChainList = ["UIView"]
            return object
        }()

        let info = AppViewHierarchyInfo()
        info.serverVersion = appviewServerVersionInt32
        info.displayItems = [root]

        var file = AppViewHierarchyFile()
        file.serverVersion = info.serverVersion
        file.hierarchyInfo = info

        let archived = try AVWireCodec.archive(hierarchyFile: file)
        let restored = try AVWireCodec.loadHierarchyFile(from: archived)
        let item = try XCTUnwrap(restored.hierarchyInfo?.displayItems?.first)
        XCTAssertEqual(item.frame.origin.x, 0, accuracy: 0.0001)
        XCTAssertEqual(item.frame.origin.y, 0, accuracy: 0.0001)
        XCTAssertEqual(item.frame.size.width, 0, accuracy: 0.0001)
        XCTAssertEqual(item.frame.size.height, 100, accuracy: 0.0001)
        XCTAssertEqual(item.alpha, 0, accuracy: 0.0001)
    }

    func testAppViewJSONAttributeSupportInvalidJSON() {
        let state = AppViewJSONAttributeSupport.dashboardParseState(from: "{not json")
        guard case .invalid(let message) = state else {
            XCTFail("expected invalid, got \(state)")
            return
        }
        XCTAssertTrue(message.contains("Malformed"))
    }

    func testAppViewJSONAttributeSupportWrongSchema() {
        let state = AppViewJSONAttributeSupport.dashboardParseState(from: #"{"only":"object"}"#)
        guard case .valid = state else {
            XCTFail("single object is wrapped as one row")
            return
        }
        let badArray = AppViewJSONAttributeSupport.dashboardParseState(from: "123")
        guard case .invalid = badArray else {
            XCTFail("scalar JSON should be invalid for tree schema")
            return
        }
    }

    func testAppViewJSONAttributeSupportTreeFromWireJSONKind() throws {
        let doc = #"[[{"title":"root","desc":"v","details":[]}]]"#
        let wire = WireAttrValue.json(doc)
        let attrValue = WireAttributeMapper.appviewValue(from: wire, attrType: .json)
        let roots = AppViewJSONAttributeSupport.appviewTreeRootArray(from: attrValue)
        XCTAssertEqual(roots?.count, 1)
        XCTAssertEqual(roots?.first?["title"] as? String, "root")
    }

    func testAppViewJSONAttributeSupportRawStringDocument() throws {
        let doc = #"[[{"title":"raw","desc":"ok"}]]"#
        let wire = WireAttrValue.string(doc)
        let attrValue = WireAttributeMapper.appviewValue(from: wire, attrType: .json)
        guard case .json(let docValue)? = attrValue else {
            XCTFail("expected json attribute value")
            return
        }
        XCTAssertEqual(docValue, doc)
        XCTAssertEqual(AppViewJSONAttributeSupport.appviewTreeRootArray(from: attrValue)?.first?["title"] as? String, "raw")
    }

    func testWireJSONAttributeRoundTrip() throws {
        let jsonText = #"{"name":"Dog","count":3}"#
        let attr = AppViewAttribute()
        attr.identifier = "dogJson"
        attr.attrType = .json
        attr.value = .json(jsonText)

        let wire = WireAttributeMapper.wireAttribute(from: attr)
        guard case .json(let encodedDoc)? = wire.value else {
            XCTFail("expected json wire value")
            return
        }
        XCTAssertEqual(encodedDoc, jsonText)

        let data = try AVWireCodecV2.encodeJSON(wire)
        let decodedWire = try AVWireCodecV2.decodeJSON(WireAttribute.self, from: data)
        guard case .json = decodedWire.value else {
            XCTFail("expected json wire value after decode")
            return
        }

        let restored = WireAttributeMapper.appviewAttribute(from: decodedWire)
        XCTAssertEqual(restored.attrType, .json)
        guard case .json(let restoredText)? = restored.value else {
            XCTFail("expected json attribute value")
            return
        }
        XCTAssertEqual(restoredText, jsonText)

        let mcpObject = WireAttributeMapper.mcpJSONObject(from: .json(jsonText)) as? [String: Any]
        XCTAssertEqual(mcpObject?["name"] as? String, "Dog")
        XCTAssertEqual(mcpObject?["count"] as? Int, 3)
    }

    func testWireClientRequestPayloadHierarchy() throws {
        let payload = WireClientRequestPayload.hierarchy(
            WireHierarchyRequestParams(clientVersion: "1.0.0", minWireVersion: 2)
        )
        let envelope = payload.envelope(requestType: UInt32(AppViewRequestTypeHierarchy), tag: 7)
        let data = try AVWireCodecV2.encodeJSON(envelope)
        let decoded = try AVWireCodecV2.decodeJSON(WireRequestEnvelope.self, from: data)
        XCTAssertEqual(decoded.tag, 7)
        XCTAssertEqual(decoded.hierarchyParams?.minWireVersion, 2)
        XCTAssertEqual(decoded.hierarchyParams?.clientVersion, "1.0.0")
    }

    func testWireCustomObjectAttributeRoundTrip() {
        let attr = AppViewAttribute()
        attr.attrType = .customObj
        let opaque = NSObject()
        attr.value = .customObject(opaque)

        let wire = WireAttributeMapper.wireAttribute(from: attr)
        guard case .custom = wire.value else {
            XCTFail("expected custom wire value")
            return
        }

        let restored = WireAttributeMapper.appviewAttribute(from: wire)
        XCTAssertEqual(restored.attrType, .customObj)
        guard case .string(let summary)? = restored.value else {
            XCTFail("expected string summary for custom object")
            return
        }
        XCTAssertEqual(summary, String(describing: opaque))
    }

    func testWireClassAttributeRoundTrip() {
        let attr = AppViewAttribute()
        attr.identifier = AppViewAttr_Class_Class_Class
        attr.attrType = .customObj
        let classChains: [[String]] = [
            ["UIView", "UIResponder", "NSObject"],
            ["AppViewCollectionLayoutDemo.AVCollectionLayoutDemoViewController", "UIViewController", "UIResponder", "NSObject"],
        ]
        attr.value = .customObject(classChains)

        let wire = WireAttributeMapper.wireAttribute(from: attr)
        guard case .stringGroups = wire.value else {
            XCTFail("expected stringGroups wire value")
            return
        }

        let restored = WireAttributeMapper.appviewAttribute(from: wire)
        XCTAssertEqual(restored.attrType, .customObj)
        guard case .customObject(let restoredChains)? = restored.value,
              case .customObject(let originalChains)? = attr.value else {
            XCTFail("expected stringGroups custom object")
            return
        }
        XCTAssertEqual(restoredChains as? [[String]], originalChains as? [[String]])
    }

    func testWireRelationAttributeRoundTrip() {
        let attr = AppViewAttribute()
        attr.identifier = AppViewAttr_Relation_Relation_Relation
        attr.attrType = .customObj
        let relations = [
            "(AppViewCollectionLayoutDemo.AVCollectionLayoutDemoViewController *).view",
            "(UIWindow *) -> _delegateViewController",
            "(UIWindow *) -> _rootViewController",
        ]
        attr.value = .customObject(relations)

        let wire = WireAttributeMapper.wireAttribute(from: attr)
        guard case .strings = wire.value else {
            XCTFail("expected strings wire value")
            return
        }

        let restored = WireAttributeMapper.appviewAttribute(from: wire)
        XCTAssertEqual(restored.attrType, .customObj)
        guard case .customObject(let restoredRelations)? = restored.value,
              case .customObject(let originalRelations)? = attr.value else {
            XCTFail("expected strings custom object")
            return
        }
        XCTAssertEqual(restoredRelations as? [String], originalRelations as? [String])
    }

    func testWireDisplayItemObjectMetadataAndBackgroundColorRoundTrip() {
        var ivarTrace = AppViewIvarTrace()
        ivarTrace.hostClassName = "AVDemoLeftRailView"
        ivarTrace.ivarName = "leftRail"

        let viewObject = AppViewObject()
        viewObject.oid = 13
        viewObject.classChainList = ["UILabel", "UIView", "UIResponder", "NSObject"]
        viewObject.memoryAddress = "0x600001a2b3c0"
        viewObject.specialTrace = "{ item:1, sec:0 }"
        viewObject.ivarTraces = [ivarTrace]

        let item = AppViewDisplayItem()
        item.frame = CGRect(x: 0, y: 0, width: 120, height: 44)
        item.bounds = item.frame
        item.viewObject = viewObject
        item.backgroundColor = AppViewColor(red: 1, green: 1, blue: 1, alpha: 1)

        let wire = WireHierarchyMapper.wireItem(from: item)
        XCTAssertEqual(wire.backgroundColorRGBA?.count, 4)
        XCTAssertEqual(wire.viewRef?.specialTrace, "{ item:1, sec:0 }")
        XCTAssertEqual(wire.viewRef?.ivarTraces?.first?.ivarName, "leftRail")

        let restored = WireHierarchyMapper.appviewItem(from: wire)
        XCTAssertEqual(restored.backgroundColor?.appview_rgbaComponents.map(\.doubleValue), [1, 1, 1, 1])
        XCTAssertEqual(restored.viewObject?.specialTrace, "{ item:1, sec:0 }")
        XCTAssertEqual(restored.viewObject?.ivarTraces?.first?.ivarName, "leftRail")

        var wireWithoutBackground = wire
        wireWithoutBackground.backgroundColorRGBA = nil
        XCTAssertNil(WireHierarchyMapper.appviewItem(from: wireWithoutBackground).backgroundColor)
    }

    func testWireDisplayItemHostViewControllerRoundTrip() {
        let hostVC = AppViewObject()
        hostVC.oid = 42
        hostVC.classChainList = [
            "AppViewCollectionLayoutDemo.AVCollectionLayoutDemoViewController",
            "UIViewController",
            "UIResponder",
            "NSObject",
        ]

        let item = AppViewDisplayItem()
        item.frame = CGRect(x: 0, y: 0, width: 320, height: 480)
        item.bounds = item.frame
        item.viewObject = AppViewObject()
        item.viewObject?.oid = 13
        item.viewObject?.classChainList = ["UIView", "UIResponder", "NSObject"]
        item.hostViewControllerObject = hostVC

        let wire = WireHierarchyMapper.wireItem(from: item)
        XCTAssertEqual(wire.hostViewControllerRef?.oid, 42)
        XCTAssertEqual(
            wire.hostViewControllerRef?.classChainList?.first,
            "AppViewCollectionLayoutDemo.AVCollectionLayoutDemoViewController"
        )

        let restored = WireHierarchyMapper.appviewItem(from: wire)
        XCTAssertEqual(restored.hostViewControllerObject?.oid, 42)
        XCTAssertEqual(
            restored.hostViewControllerObject?.classChainList?.first,
            "AppViewCollectionLayoutDemo.AVCollectionLayoutDemoViewController"
        )
    }

    func testLKWireCodecV2RejectsInvalidJSON() {
        let garbage = Data("not-json".utf8)
        XCTAssertThrowsError(try AVWireCodecV2.decodeJSON(WireRequestEnvelope.self, from: garbage))
    }

    func testWireRequestEnvelopeWrongWireVersionDecodesButIsNotV2() throws {
        let json = Data("{\"requestType\":200,\"tag\":1,\"wireVersion\":1}".utf8)
        let envelope = try AVWireCodecV2.decodeJSON(WireRequestEnvelope.self, from: json)
        XCTAssertEqual(envelope.wireVersion, 1)
        XCTAssertNotEqual(envelope.wireVersion, AppViewWireFormat.version)
    }

    func testAppViewWireFormatValidateWireVersion() {
        XCTAssertTrue(AppViewWireFormat.validateWireVersion(AppViewWireFormat.version, context: "test"))
        XCTAssertFalse(AppViewWireFormat.validateWireVersion(1, context: "test"))
    }

    func testAppViewRequestTypeWireEnvelopeRoundTrips() throws {
        var asyncTask = AppViewStaticAsyncUpdateTask()
        asyncTask.oid = 9
        var detailPackage = AppViewStaticAsyncUpdateTasksPackage()
        detailPackage.tasks = [asyncTask]

        var inbuilt = AppViewAttributeModification()
        inbuilt.targetOid = 1
        inbuilt.setterSelector = NSSelectorFromString("setHidden:")
        inbuilt.attrType = .BOOL
        inbuilt.value = .bool(true)

        var custom = AppViewCustomAttrModification()
        custom.attrType = .NSString
        custom.customSetterID = "setTitle"
        custom.value = .string("hello")

        struct Case {
            let requestType: UInt32
            let data: Any?
            let expectsObject: Bool
        }

        let cases: [Case] = [
            Case(requestType: UInt32(AppViewRequestTypePing), data: nil, expectsObject: false),
            Case(
                requestType: UInt32(AppViewRequestTypeApp),
                data: ["needImages": true, "local": [NSNumber(value: 1)]] as NSObject,
                expectsObject: true
            ),
            Case(
                requestType: UInt32(AppViewRequestTypeHierarchy),
                data: ["clientVersion": "1.0.0"] as NSObject,
                expectsObject: true
            ),
            Case(
                requestType: UInt32(AppViewRequestTypeHierarchyDetails),
                data: [detailPackage] as NSObject,
                expectsObject: true
            ),
            Case(requestType: UInt32(AppViewRequestTypeInbuiltAttrModification), data: inbuilt, expectsObject: true),
            Case(requestType: UInt32(AppViewRequestTypeAttrModificationPatch), data: [asyncTask] as NSObject, expectsObject: true),
            Case(
                requestType: UInt32(AppViewRequestTypeInvokeMethod),
                data: ["oid": NSNumber(value: 1), "text": "foo"] as NSObject,
                expectsObject: true
            ),
            Case(requestType: UInt32(AppViewRequestTypeFetchObject), data: NSNumber(value: 7), expectsObject: true),
            Case(requestType: UInt32(AppViewRequestTypeFetchImageViewImage), data: NSNumber(value: 8), expectsObject: true),
            Case(
                requestType: UInt32(AppViewRequestTypeModifyRecognizerEnable),
                data: ["oid": NSNumber(value: 2), "enable": NSNumber(value: true)] as NSObject,
                expectsObject: true
            ),
            Case(requestType: UInt32(AppViewRequestTypeAllAttrGroups), data: NSNumber(value: 3), expectsObject: true),
            Case(
                requestType: UInt32(AppViewRequestTypeAllSelectorNames),
                data: ["className": "UIView", "hasArg": false] as NSObject,
                expectsObject: true
            ),
            Case(requestType: UInt32(AppViewRequestTypeCustomAttrModification), data: custom, expectsObject: true),
        ]

        for item in cases {
            let envelope = WireRequestResponseMapper.requestEnvelope(
                requestType: item.requestType,
                tag: 99,
                data: item.data
            )
            XCTAssertEqual(envelope.wireVersion, AppViewWireFormat.version)
            XCTAssertEqual(envelope.requestType, item.requestType)
            XCTAssertEqual(envelope.tag, 99)

            let json = try AVWireCodecV2.encodeJSON(envelope)
            let decoded = try AVWireCodecV2.decodeJSON(WireRequestEnvelope.self, from: json)
            XCTAssertEqual(decoded.wireVersion, AppViewWireFormat.version)
            XCTAssertEqual(decoded.requestType, item.requestType)
            XCTAssertEqual(decoded.tag, 99)

            let object = WireRequestResponseMapper.requestObject(from: decoded)
            if item.expectsObject {
                XCTAssertNotNil(object, "requestType \(item.requestType)")
            } else {
                XCTAssertNil(object, "requestType \(item.requestType)")
            }
        }
    }

    func testWireRequestEnvelopeJSONRoundTrip() throws {
        let params: [String: Any] = ["needImages": true, "local": [NSNumber(value: 1)]]
        let envelope = WireRequestResponseMapper.requestEnvelope(
            requestType: 201,
            tag: 42,
            data: params as NSObject
        )
        let data = try AVWireCodecV2.encodeJSON(envelope)
        let preview = String(data: data, encoding: .utf8) ?? ""
        XCTAssertTrue(preview.contains("\"requestType\""))
        let decoded = try AVWireCodecV2.decodeJSON(WireRequestEnvelope.self, from: data)
        XCTAssertEqual(decoded.requestType, 201)
        XCTAssertEqual(decoded.tag, 42)
        XCTAssertEqual(decoded.wireVersion, AppViewWireFormat.version)
        XCTAssertEqual(decoded.appParams?.needImages, true)
        XCTAssertEqual(decoded.appParams?.localIdentifiers, [1])

        let pingJSON = Data("{\"requestType\":200,\"tag\":1,\"wireVersion\":2}".utf8)
        let ping = try AVWireCodecV2.decodeJSON(WireRequestEnvelope.self, from: pingJSON)
        XCTAssertEqual(ping.requestType, 200)
    }
}
