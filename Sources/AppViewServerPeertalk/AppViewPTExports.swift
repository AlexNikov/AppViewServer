#if SHOULD_COMPILE_APPVIEW_SERVER

import Foundation

public let kAppViewPTProtocolErrorDomain = "PTProtocolError"
public let kAppViewPTUSBHubErrorDomain = "PTUSBHubError"
public let kAppViewPTUSBDeviceDidAttachNotification = "AppView_PTUSBDeviceDidAttachNotification"
public let kAppViewPTUSBDeviceDidDetachNotification = "AppView_PTUSBDeviceDidDetachNotification"

/// Legacy names used by AppView mac client (`AppViewDefines.h` era).
public let AppView_PTUSBDeviceDidAttachNotification = kAppViewPTUSBDeviceDidAttachNotification
public let AppView_PTUSBDeviceDidDetachNotification = kAppViewPTUSBDeviceDidDetachNotification

#endif /* SHOULD_COMPILE_APPVIEW_SERVER */
