import Foundation

/// Integer request types (legacy `AppViewDefines.h` removed; Swift is source of truth).
public let AppViewRequestTypePing = 200
public let AppViewRequestTypeApp = 201
public let AppViewRequestTypeHierarchy = 202
public let AppViewRequestTypeHierarchyDetails = 203
public let AppViewRequestTypeInbuiltAttrModification = 204
public let AppViewRequestTypeAttrModificationPatch = 205
public let AppViewRequestTypeInvokeMethod = 206
public let AppViewRequestTypeFetchObject = 207
public let AppViewRequestTypeFetchImageViewImage = 208
public let AppViewRequestTypeModifyRecognizerEnable = 209
public let AppViewRequestTypeAllAttrGroups = 210
public let AppViewRequestTypeAllSelectorNames = 213
public let AppViewRequestTypeCustomAttrModification = 214
public let AppViewPushBringForwardScreenshotTask = 303
public let AppViewPushCancelHierarchyDetails = 304
/// Typo preserved from legacy header (`Cance` not `Cancel`).
public let AppViewPush_CanceHierarchyDetails = AppViewPushCancelHierarchyDetails
