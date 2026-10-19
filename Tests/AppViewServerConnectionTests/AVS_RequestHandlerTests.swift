#if SHOULD_COMPILE_APPVIEW_SERVER

import QuartzCore
import XCTest
@testable import AppViewServer
@testable import AppViewShared

@MainActor
final class AVS_RequestHandlerTests: XCTestCase {

    private var retainedLayers: [CALayer] = []

    func testCanHandlePingAndHierarchyDetails() async {
        let handler = AVS_RequestHandler()
        XCTAssertTrue(handler.canHandleRequestType(UInt32(AppViewRequestTypePing)))
        XCTAssertTrue(handler.canHandleRequestType(UInt32(AppViewRequestTypeHierarchyDetails)))
        XCTAssertFalse(handler.canHandleRequestType(999_999))
    }

    func testHierarchyDetailsEmptyPackagesRespondsWithoutCrashing() async {
        let handler = AVS_RequestHandler()
        await handler.handleHierarchyDetails(object: [], tag: 42)
    }

    func testHierarchyDetailsHandlerYieldsOneDetailPerTaskInOrder() async {
        let layers = (0..<3).map { _ in CALayer() }
        let oids = layers.map { register(layer: $0) }

        var packages: [AppViewStaticAsyncUpdateTasksPackage] = []
        for oid in oids {
            var task = AppViewStaticAsyncUpdateTask()
            task.oid = oid
            task.taskType = .noScreenshot
            task.attrRequest = .notNeed
            var package = AppViewStaticAsyncUpdateTasksPackage()
            package.tasks = [task]
            packages.append(package)
        }

        let handler = AVS_HierarchyDetailsHandler()
        var yieldedOids: [UInt] = []
        for await details in handler.generateDetails(for: packages) {
            XCTAssertEqual(details.count, 1)
            yieldedOids.append(details[0].displayItemOid)
        }

        XCTAssertEqual(yieldedOids, oids)
    }

    func testCancelHierarchyDetailsStopsFurtherYields() async {
        let layers = (0..<5).map { _ in CALayer() }
        let oids = layers.map { register(layer: $0) }

        var package = AppViewStaticAsyncUpdateTasksPackage()
        package.tasks = oids.map { oid in
            var task = AppViewStaticAsyncUpdateTask()
            task.oid = oid
            task.taskType = .noScreenshot
            task.attrRequest = .notNeed
            return task
        }

        let detailsHandler = AVS_HierarchyDetailsHandler()
        var yieldedCount = 0
        for await _ in detailsHandler.generateDetails(for: [package]) {
            yieldedCount += 1
            if yieldedCount == 2 {
                detailsHandler.cancel()
            }
        }
        XCTAssertEqual(yieldedCount, 2)
    }

    func testCancelHierarchyDetailsRequestClearsInFlightWork() async {
        let layer = CALayer()
        let oid = register(layer: layer)
        var task = AppViewStaticAsyncUpdateTask()
        task.oid = oid
        task.taskType = .noScreenshot
        task.attrRequest = .notNeed
        var package = AppViewStaticAsyncUpdateTasksPackage()
        package.tasks = (0..<20).map { _ in task }

        let handler = AVS_RequestHandler()
        await handler.handleHierarchyDetails(object: [package], tag: 11)
        await handler.handleRequestType(UInt32(AppViewPush_CanceHierarchyDetails), tag: 0, object: nil)
        await Task.yield()
    }

    func testPingDuringHierarchyDetailsDoesNotDeadlock() async {
        let layer = CALayer()
        let oid = register(layer: layer)
        var task = AppViewStaticAsyncUpdateTask()
        task.oid = oid
        task.taskType = .noScreenshot
        task.attrRequest = .notNeed
        var package = AppViewStaticAsyncUpdateTasksPackage()
        package.tasks = [task]

        let handler = AVS_RequestHandler()
        async let details: Void = handler.handleHierarchyDetails(object: [package], tag: 99)
        async let ping: Void = handler.handleRequestType(UInt32(AppViewRequestTypePing), tag: 1, object: nil)
        _ = await (details, ping)
    }

    // MARK: - Helpers

    @discardableResult
    private func register(layer: CALayer) -> UInt {
        retainedLayers.append(layer)
        return AVS_ObjectRegistry.sharedInstance.addObject(layer)
    }
}

#endif
