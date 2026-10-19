import Foundation

public enum WireAsyncTaskMapper {
    public static func wireTask(from task: AppViewStaticAsyncUpdateTask) -> WireStaticAsyncUpdateTask {
        WireStaticAsyncUpdateTask(
            oid: task.oid,
            taskType: task.taskType.rawValue,
            attrRequest: task.attrRequest.rawValue,
            needBasisVisualInfo: task.needBasisVisualInfo,
            needSubitems: task.needSubitems,
            clientReadableVersion: task.clientReadableVersion
        )
    }

    public static func appviewTask(from wire: WireStaticAsyncUpdateTask) -> AppViewStaticAsyncUpdateTask {
        var task = AppViewStaticAsyncUpdateTask()
        task.oid = wire.oid
        task.taskType = AppViewStaticAsyncUpdateTaskType(rawValue: wire.taskType) ?? .noScreenshot
        task.attrRequest = AppViewDetailUpdateTaskAttrRequest(rawValue: wire.attrRequest) ?? .automatic
        task.needBasisVisualInfo = wire.needBasisVisualInfo
        task.needSubitems = wire.needSubitems
        task.clientReadableVersion = wire.clientReadableVersion
        return task
    }

    public static func wirePackage(from package: AppViewStaticAsyncUpdateTasksPackage) -> WireStaticAsyncUpdateTasksPackage {
        WireStaticAsyncUpdateTasksPackage(
            tasks: package.tasks?.map { wireTask(from: $0) }
        )
    }

    public static func appviewPackage(from wire: WireStaticAsyncUpdateTasksPackage) -> AppViewStaticAsyncUpdateTasksPackage {
        var package = AppViewStaticAsyncUpdateTasksPackage()
        package.tasks = wire.tasks?.map { appviewTask(from: $0) }
        return package
    }

    public static func wirePackages(from data: Any?) -> [WireStaticAsyncUpdateTasksPackage]? {
        if let packages = data as? [AppViewStaticAsyncUpdateTasksPackage] {
            return packages.map { wirePackage(from: $0) }
        }
        if let packages = data as? NSArray {
            return packages.compactMap { $0 as? AppViewStaticAsyncUpdateTasksPackage }.map { wirePackage(from: $0) }
        }
        return nil
    }

    public static func wirePatchTasks(from data: Any?) -> [WireStaticAsyncUpdateTask]? {
        if let tasks = data as? [AppViewStaticAsyncUpdateTask] {
            return tasks.map { wireTask(from: $0) }
        }
        if let tasks = data as? NSArray {
            return tasks.compactMap { $0 as? AppViewStaticAsyncUpdateTask }.map { wireTask(from: $0) }
        }
        return nil
    }
}
