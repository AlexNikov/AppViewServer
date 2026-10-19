#if canImport(AppViewShared)
import AppViewShared
#endif
#if SHOULD_COMPILE_APPVIEW_SERVER

import Foundation
import UIKit

@MainActor
public final class AVS_RequestHandler {

    private let validRequestTypes: Set<UInt32>
    private var activeDetailTasks: [UUID: Task<Void, Never>] = [:]

    public init() {
        validRequestTypes = Set([
            UInt32(AppViewRequestTypePing),
            UInt32(AppViewRequestTypeApp),
            UInt32(AppViewRequestTypeHierarchy),
            UInt32(AppViewRequestTypeInbuiltAttrModification),
            UInt32(AppViewRequestTypeCustomAttrModification),
            UInt32(AppViewRequestTypeAttrModificationPatch),
            UInt32(AppViewRequestTypeHierarchyDetails),
            UInt32(AppViewRequestTypeFetchObject),
            UInt32(AppViewRequestTypeAllAttrGroups),
            UInt32(AppViewRequestTypeAllSelectorNames),
            UInt32(AppViewRequestTypeInvokeMethod),
            UInt32(AppViewRequestTypeFetchImageViewImage),
            UInt32(AppViewRequestTypeModifyRecognizerEnable),
            UInt32(AppViewPush_CanceHierarchyDetails),
        ])
    }

    public func canHandleRequestType(_ requestType: UInt32) -> Bool {
        validRequestTypes.contains(requestType)
    }

    public func handleRequestType(_ requestType: UInt32, tag: UInt32, object: Any?) async {
        switch requestType {
        case UInt32(AppViewRequestTypePing):
            var responseAttachment = AVConnectionResponseAttachment()
            let isActive = await MainActor.run {
                AVS_ConnectionManager.sharedInstance.refreshApplicationActiveStateFromUIKit()
            }
            if !isActive {
                responseAttachment.appIsInBackground = true
            }
            AVS_ConnectionManager.sharedInstance.respond(responseAttachment, requestType: requestType, tag: tag)

        case UInt32(AppViewRequestTypeApp):
            guard let params = object as? [String: Any] else {
                submitResponseWithError(AppViewConnectionErrors.inner, requestType: requestType, tag: tag)
                return
            }
            let needImages = (params["needImages"] as? NSNumber)?.boolValue ?? false
            let localIdentifiers = params["local"] as? [NSNumber]
            let appStart = CFAbsoluteTimeGetCurrent()
            let appInfo = AVAppInfo.currentInfo(withScreenshot: needImages, icon: needImages, localIdentifiers: localIdentifiers)
            let appMs = Int((CFAbsoluteTimeGetCurrent() - appStart) * 1000)
            AVServerConnectionTiming.recordInstant(
                "server.appRequest",
                durationMs: appMs,
                attrs: ["needImages": needImages, "cached": appInfo.shouldUseCache]
            )

            var responseAttachment = AVConnectionResponseAttachment()
            responseAttachment.data = appInfo
            AVS_ConnectionManager.sharedInstance.respond(responseAttachment, requestType: requestType, tag: tag)

        case UInt32(AppViewRequestTypeHierarchy):
            var clientVersion: String?
            var scanLayoutIssues = false
            if let params = object as? [String: Any] {
                clientVersion = params["clientVersion"] as? String
                scanLayoutIssues = (params["scanLayoutIssues"] as? NSNumber)?.boolValue
                    ?? (params["scanLayoutIssues"] as? Bool) ?? false
            }
            var responseAttachment = AVConnectionResponseAttachment()
            responseAttachment.data = AVHierarchyInfo.staticInfo(
                withAppViewVersion: clientVersion,
                scanLayoutIssues: scanLayoutIssues
            )
            AVS_ConnectionManager.sharedInstance.respond(responseAttachment, requestType: requestType, tag: tag)

        case UInt32(AppViewRequestTypeInbuiltAttrModification):
            guard let modification = object as? AppViewAttributeModification else {
                AppViewDiagLog.log("Peertalk inbuilt req tag=\(tag) reject — not AppViewAttributeModification")
                submitResponseWithError(AppViewConnectionErrors.inner, requestType: requestType, tag: tag)
                return
            }
            AppViewDiagLog.log(
                "Peertalk inbuilt req tag=\(tag) targetOid=\(modification.targetOid) attr=\(modification.attrIdentifier ?? "?")"
            )
            do {
                let detail = try await AVS_InbuiltAttrModificationHandler.handleModification(modification)
                AppViewDiagLog.log(
                    "Peertalk inbuilt resp OK tag=\(tag) detailOid=\(detail.displayItemOid)"
                )
                var attachment = AVConnectionResponseAttachment()
                attachment.data = detail
                AVS_ConnectionManager.sharedInstance.respond(attachment, requestType: requestType, tag: tag)
            } catch {
                AppViewDiagLog.log(
                    "Peertalk inbuilt resp ERROR tag=\(tag) code=\((error as NSError).code) \(error.localizedDescription)"
                )
                submitResponseWithError(error, requestType: requestType, tag: tag)
            }

        case UInt32(AppViewRequestTypeCustomAttrModification):
            let custom = object as? AppViewCustomAttrModification
            AppViewDiagLog.log(
                "Peertalk custom req tag=\(tag) setterID=\(custom?.customSetterID ?? "?") attrType=\(custom?.attrType.rawValue ?? -1)"
            )
            let success = AVS_CustomAttrModificationHandler.handleModification(custom)
            if success {
                AppViewDiagLog.log("Peertalk custom resp OK tag=\(tag) (empty ACK)")
                submitResponseWithData(nil, requestType: requestType, tag: tag)
            } else {
                AppViewDiagLog.log("Peertalk custom resp FAIL tag=\(tag)")
                submitResponseWithError(AppViewConnectionErrors.inner, requestType: requestType, tag: tag)
            }

        case UInt32(AppViewRequestTypeAttrModificationPatch):
            guard let tasks = object as? [AppViewStaticAsyncUpdateTask], !tasks.isEmpty else { return }
            let dataTotalCount = tasks.count
            for await detail in AVS_ConnectionRuntimeBridge.handlePatch(with: tasks) {
                var attrAttachment = AVConnectionResponseAttachment()
                attrAttachment.data = detail
                attrAttachment.dataTotalCount = UInt(dataTotalCount)
                attrAttachment.currentDataCount = 1
                AVS_ConnectionManager.sharedInstance.respond(
                    attrAttachment,
                    requestType: UInt32(AppViewRequestTypeAttrModificationPatch),
                    tag: tag
                )
            }

        case UInt32(AppViewRequestTypeHierarchyDetails):
            await handleHierarchyDetails(object: object, tag: tag)

        case UInt32(AppViewRequestTypeFetchObject):
            let oid = (object as? NSNumber)?.uintValue ?? 0
            let targetObject = NSObject.avs_object(withOid: oid)
            var attach = AVConnectionResponseAttachment()
            if let targetObject {
                attach.data = AppViewObject.instance(with: targetObject)
            }
            AVS_ConnectionManager.sharedInstance.respond(attach, requestType: requestType, tag: tag)

        case UInt32(AppViewRequestTypeAllAttrGroups):
            let oid = (object as? NSNumber)?.uintValue ?? 0
            guard let layer = NSObject.avs_object(withOid: oid) as? CALayer else {
                submitResponseWithError(AppViewConnectionErrors.objectNotFound, requestType: requestType, tag: tag)
                return
            }
            let list = AVS_AttrGroupsMaker.attrGroups(for: layer)
            submitResponseWithData(list as NSObject?, requestType: requestType, tag: tag)

        case UInt32(AppViewRequestTypeAllSelectorNames):
            guard let params = object as? [String: Any] else {
                submitResponseWithError(AppViewConnectionErrors.inner, requestType: requestType, tag: tag)
                return
            }
            guard let className = params["className"] as? String,
                  let targetClass = NSClassFromString(className) else {
                let errorMsg = String(
                    format: lksLocalized("Didn't find the class named \"%@\". Please input another class and try again."),
                    (object as? String) ?? ""
                )
                submitResponseWithError(AppViewConnectionErrors.make(title: errorMsg), requestType: requestType, tag: tag)
                return
            }
            let hasArg = (params["hasArg"] as? NSNumber)?.boolValue ?? false
            let selNames = AVS_ConnectionRuntimeBridge.methodNameList(for: targetClass, hasArg: hasArg)
            submitResponseWithData(selNames as NSObject, requestType: requestType, tag: tag)

        case UInt32(AppViewRequestTypeInvokeMethod):
            guard let param = object as? [String: Any] else {
                submitResponseWithError(AppViewConnectionErrors.inner, requestType: requestType, tag: tag)
                return
            }
            let oid = (param["oid"] as? NSNumber)?.uintValue ?? 0
            guard let text = param["text"] as? String, !text.isEmpty else {
                submitResponseWithError(AppViewConnectionErrors.inner, requestType: requestType, tag: tag)
                return
            }
            guard let targetObj = NSObject.avs_object(withOid: oid) else {
                submitResponseWithError(AppViewConnectionErrors.objectNotFound, requestType: requestType, tag: tag)
                return
            }

            let targetSelector = NSSelectorFromString(text)
            if targetSelector != NSSelectorFromString(""), targetObj.responds(to: targetSelector) {
                var resultDescription: NSString?
                var resultObject: AppViewObject?
                var error: NSError?
                AVS_ConnectionRuntimeBridge.handleInvoke(
                    with: targetObj,
                    selector: targetSelector,
                    resultDescription: &resultDescription,
                    resultObject: &resultObject,
                    error: &error
                )
                if let error {
                    submitResponseWithError(error, requestType: requestType, tag: tag)
                    return
                }
                var responseData: [String: Any] = [:]
                if let resultDescription {
                    responseData["description"] = resultDescription
                }
                if let resultObject {
                    responseData["object"] = resultObject
                }
                submitResponseWithData(responseData as NSObject, requestType: requestType, tag: tag)
            } else {
                let errMsg = String(
                    format: lksLocalized("%@ doesn't have an instance method called \"%@\"."),
                    NSStringFromClass(type(of: targetObj)),
                    text
                )
                submitResponseWithError(AppViewConnectionErrors.make(title: errMsg), requestType: requestType, tag: tag)
            }

        case UInt32(AppViewPush_CanceHierarchyDetails):
            for task in activeDetailTasks.values {
                task.cancel()
            }
            activeDetailTasks.removeAll()

        case UInt32(AppViewRequestTypeFetchImageViewImage):
            guard let oidNumber = object as? NSNumber else {
                submitResponseWithError(AppViewConnectionErrors.inner, requestType: requestType, tag: tag)
                return
            }
            guard let imageView = NSObject.avs_object(withOid: oidNumber.uintValue) as? UIImageView else {
                submitResponseWithError(
                    imageViewExists(object: object) ? AppViewConnectionErrors.inner : AppViewConnectionErrors.objectNotFound,
                    requestType: requestType,
                    tag: tag
                )
                return
            }
            let imageData = imageView.image?.appview_data()
            submitResponseWithData(imageData as NSObject?, requestType: requestType, tag: tag)

        case UInt32(AppViewRequestTypeModifyRecognizerEnable):
            guard let params = object as? [String: NSNumber] else {
                submitResponseWithError(AppViewConnectionErrors.inner, requestType: requestType, tag: tag)
                return
            }
            let recognizerOid = params["oid"]?.uintValue ?? 0
            let shouldBeEnabled = params["enable"]?.boolValue ?? false
            guard let recognizer = NSObject.avs_object(withOid: recognizerOid) as? UIGestureRecognizer else {
                submitResponseWithError(
                    recognizerExists(oid: recognizerOid) ? AppViewConnectionErrors.inner : AppViewConnectionErrors.objectNotFound,
                    requestType: requestType,
                    tag: tag
                )
                return
            }
            recognizer.isEnabled = shouldBeEnabled
            await Task.yield()
            submitResponseWithData(NSNumber(value: recognizer.isEnabled), requestType: requestType, tag: tag)

        default:
            break
        }
    }

    public func handleHierarchyDetails(object: Any?, tag: UInt32) async {
        let packages = Self.taskPackages(from: object)
        let responsesDataTotalCount = (packages as NSArray?)?.appview_reduceInteger({ accumulator, _, package in
            guard let package = package as? AppViewStaticAsyncUpdateTasksPackage else { return accumulator }
            return accumulator + (package.tasks?.count ?? 0)
        }, initialAccumlator: 0) ?? 0

        guard let packages else {
            submitResponseWithError(AppViewConnectionErrors.inner, requestType: UInt32(AppViewRequestTypeHierarchyDetails), tag: tag)
            return
        }

        if responsesDataTotalCount == 0 {
            var attachment = AVConnectionResponseAttachment()
            attachment.data = NSArray()
            attachment.dataTotalCount = 0
            attachment.currentDataCount = 0
            AVS_ConnectionManager.sharedInstance.respond(
                attachment,
                requestType: UInt32(AppViewRequestTypeHierarchyDetails),
                tag: tag
            )
            return
        }

        let taskID = UUID()
        let detailTask = Task { @MainActor in
            let handler = AVS_HierarchyDetailsHandler()
            for await details in handler.generateDetails(for: packages) {
                if Task.isCancelled { break }
                var attachment = AVConnectionResponseAttachment()
                attachment.data = details
                attachment.dataTotalCount = UInt(responsesDataTotalCount)
                attachment.currentDataCount = UInt(details.count)
                AVS_ConnectionManager.sharedInstance.respond(
                    attachment,
                    requestType: UInt32(AppViewRequestTypeHierarchyDetails),
                    tag: tag
                )
            }
            await self.finishDetailTask(taskID)
        }
        activeDetailTasks[taskID] = detailTask
    }

    private func finishDetailTask(_ id: UUID) {
        activeDetailTasks.removeValue(forKey: id)
    }

    private static func taskPackages(from object: Any?) -> [AppViewStaticAsyncUpdateTasksPackage]? {
        if let packages = object as? [AppViewStaticAsyncUpdateTasksPackage] {
            return packages
        }
        if let nsArray = object as? NSArray {
            return nsArray.compactMap { $0 as? AppViewStaticAsyncUpdateTasksPackage }
        }
        return nil
    }

    private func imageViewExists(object: Any?) -> Bool {
        guard let oidNumber = object as? NSNumber else { return false }
        return NSObject.avs_object(withOid: oidNumber.uintValue) != nil
    }

    private func recognizerExists(oid: UInt) -> Bool {
        NSObject.avs_object(withOid: oid) != nil
    }

    private func submitResponseWithError(_ error: Error, requestType: UInt32, tag: UInt32) {
        var attachment = AVConnectionResponseAttachment()
        attachment.error = error as NSError
        AVS_ConnectionManager.sharedInstance.respond(attachment, requestType: requestType, tag: tag)
    }

    private func submitResponseWithData(_ data: NSObject?, requestType: UInt32, tag: UInt32) {
        var attachment = AVConnectionResponseAttachment()
        attachment.data = data
        AVS_ConnectionManager.sharedInstance.respond(attachment, requestType: requestType, tag: tag)
    }

    private func lksLocalized(_ key: String) -> String {
        NSLocalizedString(key, tableName: nil, bundle: AVS_Helper.bundle(), comment: "")
    }
}

#endif
