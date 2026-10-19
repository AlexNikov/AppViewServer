import Foundation

/// Shared detail payload ↔ `AppViewDisplayItemDetail` mapping (iOS + macOS AppView client).
public enum WireDetailMapper {
    public static func wireDetail(from detail: AppViewDisplayItemDetail) -> WireDisplayItemDetailPayload {
        var payload = WireDisplayItemDetailPayload(displayItemOid: detail.displayItemOid)
        if let frameValue = detail.frameValue {
            payload.frame = Rect(frameValue.appviewCGRectValue)
        }
        if let boundsValue = detail.boundsValue {
            payload.bounds = Rect(boundsValue.appviewCGRectValue)
        }
        if let hidden = detail.hiddenValue {
            payload.isHidden = hidden.boolValue
        }
        if let alpha = detail.alphaValue {
            payload.alpha = alpha.floatValue
        }
        payload.failureCode = detail.failureCode == 0 ? nil : Int(detail.failureCode)
        payload.customDisplayTitle = detail.customDisplayTitle
        payload.danceUISource = detail.danceUISource
        if let groups = detail.attributesGroupList {
            payload.attributesGroupList = groups.map { WireAttributeMapper.wireGroup(from: $0) }
        }
        if let groups = detail.customAttrGroupList {
            payload.customAttrGroupList = groups.map { WireAttributeMapper.wireGroup(from: $0) }
        }
        payload.subitems = detail.subitems?.map { WireHierarchyMapper.wireItem(from: $0) }
        return payload
    }

    public static func appviewDetail(from payload: WireDisplayItemDetailPayload) -> AppViewDisplayItemDetail {
        var detail = AppViewDisplayItemDetail()
        detail.displayItemOid = payload.displayItemOid
        if let frame = payload.frame {
            #if canImport(UIKit)
            detail.frameValue = NSValue(cgRect: frame.cgRect)
            #else
            detail.frameValue = NSValue(rect: frame.cgRect)
            #endif
        }
        if let bounds = payload.bounds {
            #if canImport(UIKit)
            detail.boundsValue = NSValue(cgRect: bounds.cgRect)
            #else
            detail.boundsValue = NSValue(rect: bounds.cgRect)
            #endif
        }
        if let hidden = payload.isHidden {
            detail.hiddenValue = NSNumber(value: hidden)
        }
        if let alpha = payload.alpha {
            detail.alphaValue = NSNumber(value: alpha)
        }
        if let code = payload.failureCode {
            detail.failureCode = code
        }
        detail.customDisplayTitle = payload.customDisplayTitle
        detail.danceUISource = payload.danceUISource
        if let groups = payload.attributesGroupList {
            detail.attributesGroupList = groups.map { WireAttributeMapper.appviewGroup(from: $0) }
        }
        if let groups = payload.customAttrGroupList {
            detail.customAttrGroupList = groups.map { WireAttributeMapper.appviewGroup(from: $0) }
        }
        if let subitems = payload.subitems {
            detail.subitems = subitems.map { WireHierarchyMapper.appviewItem(from: $0) }
        }
        return detail
    }
}
