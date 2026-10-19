#if canImport(AppViewShared)
import AppViewShared
#endif
#if SHOULD_COMPILE_APPVIEW_SERVER

import Foundation
import UIKit

public typealias AVS_StringSetter = @convention(block) (String) -> Void
public typealias AVS_NumberSetter = @convention(block) (NSNumber) -> Void
public typealias AVS_BoolSetter = @convention(block) (Bool) -> Void
public typealias AVS_ColorSetter = @convention(block) (UIColor?) -> Void
public typealias AVS_EnumSetter = @convention(block) (String) -> Void
public typealias AVS_RectSetter = @convention(block) (CGRect) -> Void
public typealias AVS_SizeSetter = @convention(block) (CGSize) -> Void
public typealias AVS_PointSetter = @convention(block) (CGPoint) -> Void
public typealias AVS_InsetsSetter = @convention(block) (UIEdgeInsets) -> Void

@objc(AVS_CustomAttrSetterManager)
public final class AVS_CustomAttrSetterManager: NSObject {

    @objc(sharedInstance)
    public class func sharedInstance() -> AVS_CustomAttrSetterManager {
        SingletonStorage.instance
    }

    private enum SingletonStorage {
        static let instance = AVS_CustomAttrSetterManager()
    }

    private var settersMap: [String: Any] = [:]

    private override init() {
        super.init()
    }

    @objc(removeAll)
    public func removeAll() {
        settersMap.removeAll()
    }

    @objc(saveSetter:uniqueID:)
    public func saveSetter(_ setter: Any, uniqueID: String) {
        settersMap[uniqueID] = setter
    }

    @objc(saveStringSetter:uniqueID:)
    public func saveStringSetter(_ setter: AVS_StringSetter?, uniqueID: String) {
        guard let setter else { return }
        settersMap[uniqueID] = setter
    }

    @objc(getStringSetterWithID:)
    public func getStringSetter(withID uniqueID: String) -> AVS_StringSetter? {
        settersMap[uniqueID] as? AVS_StringSetter
    }

    @objc(saveNumberSetter:uniqueID:)
    public func saveNumberSetter(_ setter: AVS_NumberSetter?, uniqueID: String) {
        guard let setter else { return }
        settersMap[uniqueID] = setter
    }

    @objc(getNumberSetterWithID:)
    public func getNumberSetter(withID uniqueID: String) -> AVS_NumberSetter? {
        settersMap[uniqueID] as? AVS_NumberSetter
    }

    @objc(saveBoolSetter:uniqueID:)
    public func saveBoolSetter(_ setter: AVS_BoolSetter?, uniqueID: String) {
        guard let setter else { return }
        settersMap[uniqueID] = setter
    }

    @objc(getBoolSetterWithID:)
    public func getBoolSetter(withID uniqueID: String) -> AVS_BoolSetter? {
        settersMap[uniqueID] as? AVS_BoolSetter
    }

    @objc(saveColorSetter:uniqueID:)
    public func saveColorSetter(_ setter: AVS_ColorSetter?, uniqueID: String) {
        guard let setter else { return }
        settersMap[uniqueID] = setter
    }

    @objc(getColorSetterWithID:)
    public func getColorSetter(withID uniqueID: String) -> AVS_ColorSetter? {
        settersMap[uniqueID] as? AVS_ColorSetter
    }

    @objc(saveEnumSetter:uniqueID:)
    public func saveEnumSetter(_ setter: AVS_EnumSetter?, uniqueID: String) {
        guard let setter else { return }
        settersMap[uniqueID] = setter
    }

    @objc(getEnumSetterWithID:)
    public func getEnumSetter(withID uniqueID: String) -> AVS_EnumSetter? {
        settersMap[uniqueID] as? AVS_EnumSetter
    }

    @objc(saveRectSetter:uniqueID:)
    public func saveRectSetter(_ setter: AVS_RectSetter?, uniqueID: String) {
        guard let setter else { return }
        settersMap[uniqueID] = setter
    }

    @objc(getRectSetterWithID:)
    public func getRectSetter(withID uniqueID: String) -> AVS_RectSetter? {
        settersMap[uniqueID] as? AVS_RectSetter
    }

    @objc(saveSizeSetter:uniqueID:)
    public func saveSizeSetter(_ setter: AVS_SizeSetter?, uniqueID: String) {
        guard let setter else { return }
        settersMap[uniqueID] = setter
    }

    @objc(getSizeSetterWithID:)
    public func getSizeSetter(withID uniqueID: String) -> AVS_SizeSetter? {
        settersMap[uniqueID] as? AVS_SizeSetter
    }

    @objc(savePointSetter:uniqueID:)
    public func savePointSetter(_ setter: AVS_PointSetter?, uniqueID: String) {
        guard let setter else { return }
        settersMap[uniqueID] = setter
    }

    @objc(getPointSetterWithID:)
    public func getPointSetter(withID uniqueID: String) -> AVS_PointSetter? {
        settersMap[uniqueID] as? AVS_PointSetter
    }

    @objc(saveInsetsSetter:uniqueID:)
    public func saveInsetsSetter(_ setter: AVS_InsetsSetter?, uniqueID: String) {
        guard let setter else { return }
        settersMap[uniqueID] = setter
    }

    @objc(getInsetsSetterWithID:)
    public func getInsetsSetter(withID uniqueID: String) -> AVS_InsetsSetter? {
        settersMap[uniqueID] as? AVS_InsetsSetter
    }
}

#endif
