import CoreGraphics
import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public enum WireAttributeMapper {
    public static func wireGroup(from group: AppViewAttributesGroup) -> WireAttributesGroup {
        WireAttributesGroup(
            identifier: group.identifier,
            userCustomTitle: group.userCustomTitle,
            attrSections: group.attrSections?.map { wireSection(from: $0) }
        )
    }

    public static func appviewGroup(from wire: WireAttributesGroup) -> AppViewAttributesGroup {
        var group = AppViewAttributesGroup()
        group.identifier = wire.identifier
        group.userCustomTitle = wire.userCustomTitle
        group.attrSections = wire.attrSections?.map { appviewSection(from: $0) }
        return group
    }

    public static func wireSection(from section: AppViewAttributesSection) -> WireAttributesSection {
        WireAttributesSection(
            identifier: section.identifier,
            attributes: section.attributes?.map { wireAttribute(from: $0) }
        )
    }

    public static func appviewSection(from wire: WireAttributesSection) -> AppViewAttributesSection {
        var section = AppViewAttributesSection()
        section.identifier = wire.identifier
        section.attributes = wire.attributes?.map { appviewAttribute(from: $0) }
        return section
    }

    public static func wireAttribute(from attribute: AppViewAttribute) -> WireAttribute {
        WireAttribute(
            identifier: attribute.identifier,
            displayTitle: attribute.displayTitle,
            attrType: attribute.attrType.rawValue,
            value: wireValue(from: attribute.value),
            extraValue: wireValue(from: attribute.extraValue),
            customSetterID: attribute.customSetterID
        )
    }

    public static func appviewAttribute(from wire: WireAttribute) -> AppViewAttribute {
        let attrType = AppViewAttrType(rawValue: wire.attrType) ?? .none
        let attribute = AppViewAttribute()
        attribute.identifier = wire.identifier
        attribute.displayTitle = wire.displayTitle
        attribute.attrType = attrType
        attribute.value = appviewValue(from: wire.value, attrType: attrType)
        attribute.extraValue = appviewValue(from: wire.extraValue, attrType: attrType)
        attribute.customSetterID = wire.customSetterID
        return attribute
    }

    public static func wireValue(from attrValue: AttributeValue?) -> WireAttrValue? {
        guard let attrValue else { return nil }
        switch attrValue {
        case .bool(let v):
            return .bool(v)
        case .char(let v):
            return .number(Double(v))
        case .int(let v):
            return .number(Double(v))
        case .short(let v):
            return .number(Double(v))
        case .long(let v):
            return .number(Double(v))
        case .longLong(let v):
            return .number(Double(v))
        case .unsignedChar(let v):
            return .number(Double(v))
        case .unsignedInt(let v):
            return .number(Double(v))
        case .unsignedShort(let v):
            return .number(Double(v))
        case .unsignedLong(let v):
            return .number(Double(v))
        case .unsignedLongLong(let v):
            return .number(Double(v))
        case .float(let v):
            return .number(Double(v).appviewJSONFinite)
        case .double(let v):
            return .number(Double(v).appviewJSONFinite)
        case .selector(let v):
            return .string(NSStringFromSelector(v))
        case .classRef(let v):
            return .string(v.map { NSStringFromClass($0) } ?? "")
        case .string(let v):
            return .string(v)
        case .json(let v):
            return .json(v)
        case .color(let v):
            return .numbers(v.map(\.appviewJSONFinite))
        case .cgPoint(let v):
            return .point(Point(x: Double(v.x).appviewJSONFinite, y: Double(v.y).appviewJSONFinite))
        case .cgVector(let v):
            return .vector(Vector(dx: Double(v.dx).appviewJSONFinite, dy: Double(v.dy).appviewJSONFinite))
        case .cgSize(let v):
            return .size(Size(width: Double(v.width).appviewJSONFinite, height: Double(v.height).appviewJSONFinite))
        case .cgRect(let v):
            return .rect(Rect(v))
        case .cgAffineTransform(let v):
            return .transform(AffineTransform(
                a: Double(v.a).appviewJSONFinite, b: Double(v.b).appviewJSONFinite, c: Double(v.c).appviewJSONFinite,
                d: Double(v.d).appviewJSONFinite, tx: Double(v.tx).appviewJSONFinite, ty: Double(v.ty).appviewJSONFinite
            ))
        case .edgeInsets(let v):
            return .insets(EdgeInsets(
                top: Double(v.top).appviewJSONFinite, left: Double(v.left).appviewJSONFinite,
                bottom: Double(v.bottom).appviewJSONFinite, right: Double(v.right).appviewJSONFinite
            ))
        case .offset(let h, let vert):
            return .offset(Offset(horizontal: Double(h).appviewJSONFinite, vertical: Double(vert).appviewJSONFinite))
        case .shadow(let s):
            return .shadow(ShadowValue(
                offsetWidth: Double(s.offsetWidth).appviewJSONFinite,
                offsetHeight: Double(s.offsetHeight).appviewJSONFinite,
                opacity: Double(s.opacity).appviewJSONFinite,
                radius: Double(s.radius).appviewJSONFinite,
                colorRGBA: s.colorRGBA?.map(\.appviewJSONFinite)
            ))
        case .customObject(let v):
            return wireCustomObject(from: v)
        }
    }

    public static func appviewValue(from wire: WireAttrValue?, attrType: AppViewAttrType) -> AttributeValue? {
        guard let wire, wire != .null else { return nil }

        switch wire {
        case .null:
            return nil
        case .bool(let value):
            return .bool(value)
        case .number(let value):
            switch attrType {
            case .char: return .char(Int8(value))
            case .int, .enumInt: return .int(Int32(value))
            case .short: return .short(Int16(value))
            case .long, .enumLong: return .long(Int(value))
            case .longLong: return .longLong(Int64(value))
            case .unsignedChar: return .unsignedChar(UInt8(value))
            case .unsignedInt: return .unsignedInt(UInt32(value))
            case .unsignedShort: return .unsignedShort(UInt16(value))
            case .unsignedLong: return .unsignedLong(UInt(value))
            case .unsignedLongLong: return .unsignedLongLong(UInt64(value))
            case .float: return .float(Float(value))
            case .double: return .double(value)
            default: return .double(value)
            }
        case .string(let value):
            switch attrType {
            case .sel: return .selector(NSSelectorFromString(value))
            case .class: return .classRef(NSClassFromString(value))
            case .json: return .json(value)
            default: return .string(value)
            }
        case .numbers(let numbers):
            return .color(numbers)
        case .strings(let strings):
            return .customObject(strings)
        case .stringGroups(let groups):
            return .customObject(groups)
        case .point(let point):
            return .cgPoint(CGPoint(x: point.x, y: point.y))
        case .vector(let vector):
            return .cgVector(CGVector(dx: vector.dx, dy: vector.dy))
        case .size(let size):
            return .cgSize(CGSize(width: size.width, height: size.height))
        case .rect(let rect):
            return .cgRect(rect.cgRect)
        case .transform(let t):
            return .cgAffineTransform(CGAffineTransform(a: t.a, b: t.b, c: t.c, d: t.d, tx: t.tx, ty: t.ty))
        case .insets(let insets):
            return .edgeInsets(AppViewInsets(
                top: insets.top, left: insets.left,
                bottom: insets.bottom, right: insets.right
            ))
        case .offset(let offset):
            return .offset(CGFloat(offset.horizontal), CGFloat(offset.vertical))
        case .shadow(let shadow):
            return .shadow(ShadowComponents(
                offsetWidth: CGFloat(shadow.offsetWidth),
                offsetHeight: CGFloat(shadow.offsetHeight),
                opacity: Float(shadow.opacity),
                radius: CGFloat(shadow.radius),
                colorRGBA: shadow.colorRGBA
            ))
        case .json(let doc):
            return .json(doc)
        case .custom(let summary):
            return .string(summary)
        case .autoLayoutConstraints(let rows):
            return .customObject(rows.map { appviewConstraint(from: $0) })
        case .layoutIssues(let rows):
            return .customObject(rows.map { appviewLayoutIssue(from: $0) })
        }
    }

    // MARK: - Auto Layout rows (al_c_c / al_l)

    public static func wireConstraint(from constraint: AppViewAutoLayoutConstraint) -> WireAutoLayoutConstraint {
        WireAutoLayoutConstraint(
            id: constraint.snapshotID,
            effective: constraint.effective,
            active: constraint.active,
            shouldBeArchived: constraint.shouldBeArchived,
            firstItem: WireHierarchyObjectMapping.wireRef(constraint.firstItem),
            firstItemType: constraint.firstItemType.rawValue,
            firstAttribute: constraint.firstAttribute,
            relation: constraint.relation.rawValue,
            secondItem: WireHierarchyObjectMapping.wireRef(constraint.secondItem),
            secondItemType: constraint.secondItemType.rawValue,
            secondAttribute: constraint.secondAttribute,
            multiplier: Double(constraint.multiplier).appviewJSONFinite,
            constant: Double(constraint.constant).appviewJSONFinite,
            priority: Double(constraint.priority).appviewJSONFinite,
            identifier: constraint.identifier
        )
    }

    public static func appviewConstraint(from wire: WireAutoLayoutConstraint) -> AppViewAutoLayoutConstraint {
        let constraint = AppViewAutoLayoutConstraint()
        constraint.snapshotID = wire.id
        constraint.effective = wire.effective
        constraint.active = wire.active
        constraint.shouldBeArchived = wire.shouldBeArchived
        constraint.firstItem = wire.firstItem.map { WireHierarchyObjectMapping.appviewObject(from: $0) }
        constraint.firstItemType = AppViewConstraintItemType(rawValue: wire.firstItemType) ?? .unknown
        constraint.firstAttribute = wire.firstAttribute
        constraint.relation = NSLayoutConstraint.Relation(rawValue: wire.relation) ?? .equal
        constraint.secondItem = wire.secondItem.map { WireHierarchyObjectMapping.appviewObject(from: $0) }
        constraint.secondItemType = AppViewConstraintItemType(rawValue: wire.secondItemType) ?? .unknown
        constraint.secondAttribute = wire.secondAttribute
        constraint.multiplier = CGFloat(wire.multiplier)
        constraint.constant = CGFloat(wire.constant)
        constraint.priority = CGFloat(wire.priority)
        constraint.identifier = wire.identifier
        return constraint
    }

    public static func wireLayoutIssue(from issue: AppViewLayoutIssue) -> WireLayoutIssue {
        WireLayoutIssue(kind: issue.kind.rawValue, title: issue.title, constraintIds: issue.constraintIDs)
    }

    public static func appviewLayoutIssue(from wire: WireLayoutIssue) -> AppViewLayoutIssue {
        AppViewLayoutIssue(
            kind: AppViewLayoutIssueKind(rawValue: wire.kind) ?? .ambiguous,
            title: wire.title,
            constraintIDs: wire.constraintIds
        )
    }

    // MARK: - MCP HTTP JSON (same semantics as wire, no keyed archive)

    /// Attribute value → JSON-friendly object for MCP responses.
    public static func mcpJSONObject(from attrValue: AttributeValue?) -> Any {
        guard let wire = wireValue(from: attrValue) else { return NSNull() }
        return mcpJSONObject(from: wire)
    }

    public static func mcpJSONObject(from wire: WireAttrValue) -> Any {
        switch wire {
        case .null:
            return NSNull()
        case .bool(let v):
            return v
        case .number(let v):
            return v
        case .string(let v):
            return v
        case .numbers(let v):
            return v.map { NSNumber(value: $0) }
        case .strings(let v):
            return v
        case .stringGroups(let v):
            return v
        case .point(let p):
            return ["x": p.x, "y": p.y]
        case .vector(let v):
            return ["dx": v.dx, "dy": v.dy]
        case .size(let s):
            return ["width": s.width, "height": s.height]
        case .rect(let r):
            return ["x": r.x, "y": r.y, "width": r.width, "height": r.height]
        case .transform(let t):
            return ["a": t.a, "b": t.b, "c": t.c, "d": t.d, "tx": t.tx, "ty": t.ty]
        case .insets(let i):
            return ["top": i.top, "left": i.left, "bottom": i.bottom, "right": i.right]
        case .offset(let o):
            return ["horizontal": o.horizontal, "vertical": o.vertical]
        case .shadow(let s):
            var dict: [String: Any] = [
                "offsetWidth": s.offsetWidth,
                "offsetHeight": s.offsetHeight,
                "opacity": s.opacity,
                "radius": s.radius,
            ]
            if let rgba = s.colorRGBA, rgba.count >= 4 {
                dict["color"] = ["r": rgba[0], "g": rgba[1], "b": rgba[2], "a": rgba[3]]
            }
            return dict
        case .json(let doc):
            guard let data = doc.data(using: .utf8),
                  let parsed = try? JSONSerialization.jsonObject(with: data) else {
                return doc
            }
            return parsed
        case .custom(let s):
            return s
        case .autoLayoutConstraints(let rows):
            return rows.map { mcpJSONObject(from: $0) }
        case .layoutIssues(let rows):
            return rows.map { mcpJSONObject(from: $0) }
        }
    }

    /// `al_c_c` row for MCP: same fields as the wire row; `id` matches `al_l[].constraintIds`.
    public static func mcpJSONObject(from row: WireAutoLayoutConstraint) -> [String: Any] {
        var dict: [String: Any] = [
            "effective": row.effective,
            "active": row.active,
            "shouldBeArchived": row.shouldBeArchived,
            "firstItemType": row.firstItemType,
            "firstAttribute": row.firstAttribute,
            "relation": row.relation,
            "secondItemType": row.secondItemType,
            "secondAttribute": row.secondAttribute,
            "multiplier": row.multiplier,
            "constant": row.constant,
            "priority": row.priority,
        ]
        if let id = row.id { dict["id"] = id }
        if let identifier = row.identifier { dict["identifier"] = identifier }
        if let first = row.firstItem { dict["firstItem"] = mcpJSONObject(from: first) }
        if let second = row.secondItem { dict["secondItem"] = mcpJSONObject(from: second) }
        return dict
    }

    private static func mcpJSONObject(from ref: WireObjectRef) -> [String: Any] {
        var dict: [String: Any] = ["oid": ref.oid]
        if let className = ref.classChainList?.first { dict["className"] = className }
        if let address = ref.memoryAddress { dict["memoryAddress"] = address }
        return dict
    }

    /// `al_l` row for MCP.
    public static func mcpJSONObject(from row: WireLayoutIssue) -> [String: Any] {
        ["kind": row.kind, "title": row.title, "constraintIds": row.constraintIds]
    }

    /// MCP POST body `value` → in-memory attribute value.
    public static func appviewValue(fromMCPJSON json: Any?, attrType: AppViewAttrType) -> AttributeValue? {
        guard let json, !(json is NSNull) else { return nil }

        switch attrType {
        case .BOOL:
            let v = (json as? NSNumber)?.boolValue ?? (json as? Bool) ?? false
            return .bool(v)
        case .float:
            if let number = json as? NSNumber { return .float(number.floatValue) }
            if let double = json as? Double { return .float(Float(double)) }
            if let int = json as? Int { return .float(Float(int)) }
            return nil
        case .double:
            if let number = json as? NSNumber { return .double(number.doubleValue) }
            if let double = json as? Double { return .double(double) }
            if let int = json as? Int { return .double(Double(int)) }
            return nil
        case .int, .enumInt:
            if let number = json as? NSNumber { return .int(number.int32Value) }
            if let int = json as? Int { return .int(Int32(int)) }
            return nil
        case .short:
            if let number = json as? NSNumber { return .short(number.int16Value) }
            return nil
        case .long, .enumLong:
            if let number = json as? NSNumber { return .long(number.intValue) }
            if let int = json as? Int { return .long(int) }
            return nil
        case .longLong:
            if let number = json as? NSNumber { return .longLong(number.int64Value) }
            return nil
        case .char:
            if let number = json as? NSNumber { return .char(number.int8Value) }
            return nil
        case .unsignedInt:
            if let number = json as? NSNumber { return .unsignedInt(number.uint32Value) }
            return nil
        case .unsignedShort:
            if let number = json as? NSNumber { return .unsignedShort(number.uint16Value) }
            return nil
        case .unsignedLong:
            if let number = json as? NSNumber { return .unsignedLong(number.uintValue) }
            return nil
        case .unsignedLongLong:
            if let number = json as? NSNumber { return .unsignedLongLong(number.uint64Value) }
            return nil
        case .unsignedChar:
            if let number = json as? NSNumber { return .unsignedChar(number.uint8Value) }
            return nil
        case .NSString, .sel, .class, .enumString:
            return .string((json as? String) ?? String(describing: json))
        case .json:
            if let string = json as? String { return .json(string) }
            guard JSONSerialization.isValidJSONObject(json),
                  let data = try? JSONSerialization.data(withJSONObject: json),
                  let text = String(data: data, encoding: .utf8) else {
                return .json(String(describing: json))
            }
            return .json(text)
        case .CGPoint:
            guard let dict = json as? [String: Any] else { return nil }
            return .cgPoint(CGPoint(x: dict["x"] as? CGFloat ?? 0, y: dict["y"] as? CGFloat ?? 0))
        case .CGSize:
            guard let dict = json as? [String: Any] else { return nil }
            return .cgSize(CGSize(width: dict["width"] as? CGFloat ?? 0, height: dict["height"] as? CGFloat ?? 0))
        case .CGRect:
            guard let dict = json as? [String: Any] else { return nil }
            return .cgRect(CGRect(
                x: dict["x"] as? CGFloat ?? 0, y: dict["y"] as? CGFloat ?? 0,
                width: dict["width"] as? CGFloat ?? 0, height: dict["height"] as? CGFloat ?? 0
            ))
        case .UIEdgeInsets:
            guard let dict = json as? [String: Any] else { return nil }
            return .edgeInsets(AppViewInsets(
                top: dict["top"] as? CGFloat ?? 0, left: dict["left"] as? CGFloat ?? 0,
                bottom: dict["bottom"] as? CGFloat ?? 0, right: dict["right"] as? CGFloat ?? 0
            ))
        case .UIColor:
            if let components = json as? [NSNumber], components.count >= 4 {
                return .color(components.map(\.doubleValue))
            }
            if let dict = json as? [String: Any] {
                return .color([
                    (dict["r"] as? NSNumber)?.doubleValue ?? 0,
                    (dict["g"] as? NSNumber)?.doubleValue ?? 0,
                    (dict["b"] as? NSNumber)?.doubleValue ?? 0,
                    (dict["a"] as? NSNumber)?.doubleValue ?? 1,
                ])
            }
            return nil
        case .shadow:
            guard let dict = json as? [String: Any] else { return nil }
            var rgba: [Double]?
            if let color = dict["color"] as? [String: Any] {
                rgba = [
                    (color["r"] as? NSNumber)?.doubleValue ?? 0,
                    (color["g"] as? NSNumber)?.doubleValue ?? 0,
                    (color["b"] as? NSNumber)?.doubleValue ?? 0,
                    (color["a"] as? NSNumber)?.doubleValue ?? 1,
                ]
            }
            return .shadow(ShadowComponents(
                offsetWidth: dict["offsetWidth"] as? CGFloat ?? 0,
                offsetHeight: dict["offsetHeight"] as? CGFloat ?? 0,
                opacity: Float((dict["opacity"] as? NSNumber)?.floatValue ?? 0),
                radius: dict["radius"] as? CGFloat ?? 0,
                colorRGBA: rgba
            ))
        default:
            return appviewValue(from: mcpJSONToWire(json, attrType: attrType), attrType: attrType)
        }
    }

    private static func mcpJSONToWire(_ json: Any, attrType: AppViewAttrType) -> WireAttrValue? {
        switch attrType {
        case .BOOL:
            let v = (json as? NSNumber)?.boolValue ?? (json as? Bool) ?? false
            return .bool(v)
        case .NSString, .sel, .class, .enumString:
            return .string((json as? String) ?? String(describing: json))
        default:
            if let number = json as? NSNumber { return .number(number.doubleValue) }
            if let double = json as? Double { return .number(double) }
            if let string = json as? String { return .string(string) }
            return nil
        }
    }

    private static func wireCustomObject(from any: Any?) -> WireAttrValue? {
        guard let any, !(any is NSNull) else { return nil }
        if let string = any as? String {
            return .string(string)
        }
        if let string = any as? NSString {
            return .string(string as String)
        }
        // An empty array casts to every element type: only non-empty arrays can be constraints or issues,
        // so an empty string list stays a string list below.
        if let constraints = any as? [AppViewAutoLayoutConstraint], !constraints.isEmpty {
            return .autoLayoutConstraints(constraints.map { wireConstraint(from: $0) })
        }
        if let issues = any as? [AppViewLayoutIssue], !issues.isEmpty {
            return .layoutIssues(issues.map { wireLayoutIssue(from: $0) })
        }
        if let strings = any as? [String] {
            return .strings(strings)
        }
        if let strings = any as? [NSString] {
            return .strings(strings.map { $0 as String })
        }
        if let groups = any as? [[String]] {
            return .stringGroups(groups)
        }
        if let groups = any as? [[NSString]] {
            return .stringGroups(groups.map { $0.map { $0 as String } })
        }
        if let array = any as? [Any], let groups = stringGroups(from: array) {
            return .stringGroups(groups)
        }
        if let array = any as? [Any], let strings = stringList(from: array) {
            return .strings(strings)
        }
        return .custom(String(describing: any))
    }

    private static func stringList(from array: [Any]) -> [String]? {
        guard !array.isEmpty else { return nil }
        var strings: [String] = []
        strings.reserveCapacity(array.count)
        for element in array {
            if let string = element as? String {
                strings.append(string)
            } else if let string = element as? NSString {
                strings.append(string as String)
            } else {
                return nil
            }
        }
        return strings
    }

    private static func stringGroups(from array: [Any]) -> [[String]]? {
        guard !array.isEmpty else { return nil }
        var groups: [[String]] = []
        groups.reserveCapacity(array.count)
        for element in array {
            if let nested = element as? [String] {
                groups.append(nested)
            } else if let nested = element as? [NSString] {
                groups.append(nested.map { $0 as String })
            } else if let nested = element as? [Any], let strings = stringList(from: nested) {
                groups.append(strings)
            } else {
                return nil
            }
        }
        return groups
    }

}
