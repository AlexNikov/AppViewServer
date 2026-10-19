import Foundation

// Connection ports (from AppViewDefines.h; not in AppViewVersion.swift).
public let appviewUSBDeviceIPv4PortNumberStart = 47175
public let appviewUSBDeviceIPv4PortNumberEnd = 47179
public let appviewSimulatorIPv4PortNumberStart = 47164
public let appviewSimulatorIPv4PortNumberEnd = 47169

public let appviewNodeImageMaxLengthInPx: Double = 16384

public enum AppViewPreviewBitMask: UInt {
    case none = 0
    case selectable = 2
    case unselectable = 4
    case hasLight = 8
    case noLight = 16
}

// MARK: - Legacy C names (AppView mac client)

public let APPVIEW_CLIENT_VERSION = appviewClientVersion
public let APPVIEW_SUPPORTED_SERVER_MIN = appviewSupportedServerMin
public let APPVIEW_SUPPORTED_SERVER_MAX = appviewSupportedServerMax

public let AppViewUSBDeviceIPv4PortNumberStart = appviewUSBDeviceIPv4PortNumberStart
public let AppViewUSBDeviceIPv4PortNumberEnd = appviewUSBDeviceIPv4PortNumberEnd
public let AppViewSimulatorIPv4PortNumberStart = appviewSimulatorIPv4PortNumberStart
public let AppViewSimulatorIPv4PortNumberEnd = appviewSimulatorIPv4PortNumberEnd

public let AppViewErrorDomain = appviewErrorDomain
public let AppViewStringFlag_VoidReturn = appviewStringFlagVoidReturn
public let AppViewNodeImageMaxLengthInPx = appviewNodeImageMaxLengthInPx

public let AppViewErrCode_Default = AppViewSharedErrCode.default.rawValue
public let AppViewErrCode_Inner = AppViewSharedErrCode.inner.rawValue
public let AppViewErrCode_PeerTalk = AppViewSharedErrCode.peerTalk.rawValue
public let AppViewErrCode_NoConnect = AppViewSharedErrCode.noConnect.rawValue
public let AppViewErrCode_PingFailForTimeout = AppViewSharedErrCode.pingFailForTimeout.rawValue
public let AppViewErrCode_Timeout = AppViewSharedErrCode.timeout.rawValue
public let AppViewErrCode_Discard = AppViewSharedErrCode.discard.rawValue
public let AppViewErrCode_PingFailForBackgroundState = AppViewSharedErrCode.pingFailForBackgroundState.rawValue
public let AppViewErrCode_ObjectNotFound = AppViewSharedErrCode.objectNotFound.rawValue
public let AppViewErrCode_ModifyValueTypeInvalid = AppViewSharedErrCode.modifyValueTypeInvalid.rawValue
public let AppViewErrCode_Exception = AppViewSharedErrCode.exception.rawValue
public let AppViewErrCode_ServerVersionTooHigh = AppViewSharedErrCode.serverVersionTooHigh.rawValue
public let AppViewErrCode_ServerVersionTooLow = AppViewSharedErrCode.serverVersionTooLow.rawValue
public let AppViewErrCode_UnsupportedFileType = AppViewSharedErrCode.unsupportedFileType.rawValue
