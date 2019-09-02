//
//  Task.swift
//  UlfyIOS
//
//  Created by 123 on 2019/8/8.
//  Copyright © 2019 SparkUlfy. All rights reserved.
//

import Foundation


//////////////////////////  任务的基本框架  //////////////////////////////

/// 最基础的任务类，该类制定了任务执行的基本方式
/// - 为了支持异步的调用，对于任务的状态需要子类来指定
public class Task {
    private var isRunning: Bool = false         // 任务是否正在执行
    private var onStart: (() -> Void)?          // 任务开始执行回调（生命周期回调）
    private var onFinish: (() -> Void)?         // 任务结束执行回调（生命周期回调）

    /// 设置生命周期回调
    final func setLifecycleCallback(onStart: (() -> Void)?, onFinish: (() -> Void)?) {
        self.onStart = onStart
        self.onFinish = onFinish
    }

    /// 每个任务都应该有一个可执行的方法
    /// 对于具体的任务必须实现该方法
    func run() {
        isRunning = true
        onStart?()
        run(task: self)
        isRunning = false
        onFinish?()
    }

    func run(task: Task) { }
}

/// 通常任务都是在后台执行的，该任务内部提供了可直接更新UI的方法
public class UiTask : Task {
    private var cancelUiHandler = false         // 是否取消未执行的UI操作

    /// 在UI线程中执行一段代码块
    final func runOnUiThread(runnable: @escaping () -> Void) {
        if (cancelUiHandler) {
            return
        }
        DispatchQueue.main.async {
            if (!self.cancelUiHandler) {
                runnable()
            }
        }
    }

    /// 设置取消还没有执行的UI操作
    func setCancelUiHandler(cancelUiHandler: Bool) {
        self.cancelUiHandler = cancelUiHandler
    }

    /// 是否取消UI操作
    func isCancelUiHandler() -> Bool {
        return self.cancelUiHandler
    }
}

/// 网络任务
/// 该任务配有网络访问的常用配置
public class NetUiTask: UiTask {
    private var proxyTask: UiTask
    private var transponder: Transponder
    private var netWorkEnable = true

    public init(proxyTask: UiTask, transponder: Transponder) {
        self.proxyTask = proxyTask
        self.transponder = transponder
    }

    override func run(task: Task) {
        // 没有打开网络连接开关 或 网络连接开关已经打开，但是无网络连接
        if (!netWorkEnable) {
            runOnUiThread {
                self.transponder.onTranspondMessage(message: Message(type: Message.TYPE_NO_NET_CONNECTION, data: "当前无网络链接"))
            }
        }
        // 有网络并且是wifi
        else if (!isCancelUiHandler()) {
            proxyTask.run()
        }
    }

    override func setCancelUiHandler(cancelUiHandler: Bool) {
        super.setCancelUiHandler(cancelUiHandler: cancelUiHandler)
        proxyTask.setCancelUiHandler(cancelUiHandler: cancelUiHandler)
    }

    override func isCancelUiHandler() -> Bool {
        return super.isCancelUiHandler() && proxyTask.isCancelUiHandler()
    }
}

/// 任务执行器，用于执行一个任务。后期会扩展不同的执行器实现
public class TaskExecutor {
    public static let defaultConcurrentTaskExecutor = ConcurrentTaskExecutor()       // 默认的并发执行器
    public static let defaultSerialTaskExecutor = SerialTaskExecutor()               // 默认的串行执行器

    public static var defaultExecutor: TaskExecutor {                                // 默认的执行器
        return defaultConcurrentTaskExecutor
    }
    public static var newConcurrentTaskExecutor: ConcurrentTaskExecutor {            // 新建的并发执行器
        return ConcurrentTaskExecutor()
    }
    public static var netSerialTaskExecutor: SerialTaskExecutor {                    // 新建的串行执行器
        return SerialTaskExecutor()
    }

    /// 提交一个任务，该方法由子类实现
    func post(task: Task) { }
}

/// 提供并发功能的任务执行器
public class ConcurrentTaskExecutor : TaskExecutor {
    private let dispatchQueue = DispatchQueue(label: "ConcurrentTaskExecutor", attributes: .concurrent)

    final override func post(task: Task) {
        dispatchQueue.async {
            task.run()
        }
    }
}

/// 顺序执行任务的执行器
public class SerialTaskExecutor : TaskExecutor {
    private let dispatchQueue = DispatchQueue(label: "ConcurrentTaskExecutor")

    final override func post(task: Task) {
        dispatchQueue.async {
            task.run()
        }
    }
}

/// 单一任务执行器，在当前任务没有执行完毕之后其它的任务将被丢弃
public class SingleTaskExecutor : TaskExecutor {
    private let dispatchQueue = DispatchQueue(label: "SingleTaskExecutor")
    private var task: Task?

    final override func post(task: Task) {
        initTask(task: task)
    }

    private func initTask(task: Task) {
        if (self.task == nil) {
            self.task = task
            self.task?.setLifecycleCallback(onStart: nil, onFinish: { self.clearTask() })
            dispatchQueue.async {
                self.task?.run()
            }
        }
    }

    private func clearTask() {
        self.task = nil
    }
}

/// 最终任务UI执行器，当有新的任务被添加进来时，之前的任务将会丧失更新UI的能力
/// - 只有最后添加进来的任务有更新UI的能力
public class FinalUiTaskExecutor : TaskExecutor {
    private let dispatchQueue = DispatchQueue(label: "FinalUiTaskExecutor", attributes: .concurrent)
    private var uiTaskArray: [UiTask] = [UiTask]()

    final override func post(task: Task) {
        if (task is UiTask) {
            for uiTask in self.uiTaskArray {
                uiTask.setCancelUiHandler(cancelUiHandler: true)
            }
            let pendingUiTask: UiTask = task as! UiTask
            pendingUiTask.setLifecycleCallback(onStart: nil, onFinish: { self.uiTaskArray = self.uiTaskArray.filter { (uiTask: UiTask) -> Bool in pendingUiTask === uiTask } })
            uiTaskArray.append(pendingUiTask)
            dispatchQueue.async {
                pendingUiTask.run()
            }
        }
    }
}

//////////////////////////  任务的响应框架  //////////////////////////////

/// 任务执行过程中在不同的阶段会发布不同的消息给响应器，响应器根据这些消息做出不同的响应
class Message {
    static let TYPE_NO_NET_CONNECTION = 0           // 没有网络连接
    static let TYPE_NET_ERROR = 1;                  // 网络错误
    static let TYPE_START = 2;                      // 任务开始
    static let TYPE_SUCCESS = 3;                    // 任务成功
    static let TYPE_FAIL = 4;                       // 任务失败
    static let TYPE_UPDATE = 5;                     // 更新任务
    static let TYPE_FINISH = 6;                     // 任务结束
    final var type: Int         // 消息的类型
    final var data: Any         // 消息携带的内容

    /// 构造方法
    init(type: Int, data: Any) {
        self.type = type
        self.data = data
    }
}

/// 响应器的最基本约定
open class Transponder {

    /// 当任务发布消息的时候调用该方法
    final func onTranspondMessage(message: Message) -> Void {
        switch message.type {
        case Message.TYPE_NO_NET_CONNECTION:
            onNoNetConnection(data: message.data);
            break
        case Message.TYPE_NET_ERROR:
            onNetError(data: message.data);
            break
        case Message.TYPE_START:
            onStart(data: message.data);
            break
        case Message.TYPE_SUCCESS:
            onSuccess(data: message.data);
            break
        case Message.TYPE_FAIL:
            onFail(data: message.data);
            break
        case Message.TYPE_UPDATE:
            onUpdate(data: message.data);
            break
        case Message.TYPE_FINISH:
            onFinish(data: message.data);
            break
        default:
            break
        }
    }

    /// 无网络链接消息
    func onNoNetConnection(data: Any) -> Void { }
    /// 网络错误消息
    func onNetError(data: Any) -> Void { }
    /// 任务开始消息
    func onStart(data: Any) -> Void { }
    /// 任务成功消息
    func onSuccess(data: Any) -> Void { }
    /// 任务失败消息
    func onFail(data: Any) -> Void { }
    /// 任务更新消息
    func onUpdate(data: Any) -> Void { }
    /// 任务结束消息
    func onFinish(data: Any) -> Void { }
}

/// 加载无状态数据的任务
public class LoadDataUiTask : UiTask {
    private var executeBody: ((LoadDataUiTask) -> Void)?        // 任务执行的执行体
    private var transponder: Transponder                        // 任务执行的响应器

    /// 构造方法，需要任务的执行体和对应的响应器
    public init(executeBody: ((LoadDataUiTask) -> Void)?, transponder: Transponder) {
        self.executeBody = executeBody;
        self.transponder = transponder;
    }

    /// 任务的执行方法实现
    final override func run(task: Task) {
        if (!isCancelUiHandler()) {
            if (executeBody == nil) {
                notifySuccess(tipData: "加载完成")
            } else {
                executeBody!(self)
            }
        }
    }

    /// 通知任务开始了
    public final func notifyStart(tipData: Any) -> Void {
        runOnUiThread {
            self.transponder.onTranspondMessage(message: Message(type: Message.TYPE_START, data: tipData));
        }
    }
    /// 通知任务成功了
    public final func notifySuccess(tipData: Any) -> Void {
        runOnUiThread {
            self.transponder.onTranspondMessage(message: Message(type: Message.TYPE_SUCCESS, data: tipData));
            self.transponder.onTranspondMessage(message: Message(type: Message.TYPE_FINISH, data: tipData));
        }
    }
    /// 通知任务失败了
    public final func notifyFail(tipData: Any) -> Void {
        runOnUiThread {
            self.transponder.onTranspondMessage(message: Message(type: Message.TYPE_FAIL, data: tipData));
            self.transponder.onTranspondMessage(message: Message(type: Message.TYPE_FINISH, data: tipData));
        }
    }
    /// 通知任务更新了
    public final func notifyUpdate(tipData: Any) -> Void {
        runOnUiThread {
            self.transponder.onTranspondMessage(message: Message(type: Message.TYPE_UPDATE, data: tipData));
        }
    }
    
    public func setExecuteBody(executeBody: ((LoadDataUiTask) -> Void)?) {
        self.executeBody = executeBody
    }
}

/// 分页加载列表数据的UI任务
public class LoadListPageUiTask: UiTask {
    public static let LOAD_START_PAGE: Int = 1                   // 当前状态为加载第一页的状态
    public static let LOAD_NEXT_PAGE: Int = 2                    // 当前状态为加载下一页的状态
    public static let LOAD_RELOAD_ALL: Int = 3                   // 当前状态为重新加载已有的页面的状态
    public static let DEFAULT_START_PAGE: Int = 1                // 起始页默认为1
    public static let DEFAULT_PAGE_SIZE: Int = 20                // 每页默认大小为20
    internal static let END_PAGE_NO_POINT: Int = -1              // 尾页未指定标识符

    private var taskInfo: LoadListPageUiTaskInfo!           // 任务处理的信息
    private var loadListPageBody: ((LoadListPageUiTask, NSMutableArray, NSMutableArray, Int, Int, Int) -> Void)?        // 任务的执行体
    private var loadSimplePage: ((LoadListPageUiTask, NSMutableArray, NSMutableArray, Int, Int) -> Void)?
    private var transponder: Transponder                         // 响应器

    public init(taskInfo: LoadListPageUiTaskInfo!, loadSimplePage: ((LoadListPageUiTask, NSMutableArray, NSMutableArray, Int, Int) -> Void)?, transponder: Transponder) {
        self.taskInfo = taskInfo
        self.loadSimplePage = loadSimplePage
        self.transponder = transponder
        super.init()
        self.loadListPageBody = onLoadListPage
    }

    public func setTaskInfo(taskInfo: LoadListPageUiTaskInfo) {
        self.taskInfo = taskInfo
    }

    public func setLoadSimplePage(loadSimplePage: ((LoadListPageUiTask, NSMutableArray, NSMutableArray, Int, Int) -> Void)?) {
        self.loadSimplePage = loadSimplePage
    }
    
    override func run(task: Task) {
        if (!isCancelUiHandler()) {
            if (loadListPageBody == nil) {
                notifySuccess(tipData: "加载完成");
            } else {
                loadListPageBody!(self, taskInfo.getDataList(), taskInfo.getTempList(), taskInfo.getLoadFromPage(), taskInfo.getLoadToPage(), taskInfo.getPageSize())
            }
        }
    }

    /// 通知任务开始了
    public final func notifyStart(tipData: Any) -> Void {
        runOnUiThread {
            self.transponder.onTranspondMessage(message: Message(type: Message.TYPE_START, data: tipData));
        }
    }
    /// 通知任务成功了
    public final func notifySuccess(tipData: Any) -> Void {
        runOnUiThread {
            self.taskInfo.combileData()
            self.transponder.onTranspondMessage(message: Message(type: Message.TYPE_SUCCESS, data: tipData));
            self.transponder.onTranspondMessage(message: Message(type: Message.TYPE_FINISH, data: tipData));
        }
    }
    /// 通知任务失败了
    public final func notifyFail(tipData: Any) -> Void {
        runOnUiThread {
            self.taskInfo.clearTemp()
            self.transponder.onTranspondMessage(message: Message(type: Message.TYPE_FAIL, data: tipData));
            self.transponder.onTranspondMessage(message: Message(type: Message.TYPE_FINISH, data: tipData));
        }
    }

    public func getTaskInfo() -> LoadListPageUiTaskInfo {
        return taskInfo
    }

    public func setLoadListPageBody(loadListPageBody: ((LoadListPageUiTask, NSMutableArray, NSMutableArray, Int, Int, Int) -> Void)?) {
        self.loadListPageBody = loadListPageBody
    }

    /// 将加载分页任务中需要持久维护的信息抽象到外部中
    /// 隔绝客户端于人物的直接依赖，使得客户端只需要知道一个任务必要的信息
    public class LoadListPageUiTaskInfo {
        private var dataList: NSMutableArray                                                // 真正的数据容器
        private var tempList: NSMutableArray                                                // 临时存储结果的容器
        private var startPage = LoadListPageUiTask.DEFAULT_START_PAGE                       // 起始页
        private var pageSize = LoadListPageUiTask.DEFAULT_PAGE_SIZE                         // 每页大小
        // 在没有设置最后一页的情况下可以考虑以tempList大小是否为0来默认判断是否到底了
        private var currentPage: Int!                                                       // 当前页码指针
        private var toPagePointer: Int!                                                     // 加载至页码指针
        private var loadingStatus: Int!                                                     // 当前所处的加载状态
        private var endPage = LoadListPageUiTask.END_PAGE_NO_POINT                          // 最后一页的页码，这个也可以不设置。-1表示没有设置结束页做小设置为0
        private var isLoadTempListEmpty: Bool!                                              // 是否加载了一个空的临时列表，如果没有最后页码设置，则已该边变量作为是否到底的依据
        private var onPageCombineListener: ((LoadListPageUiTaskInfo, NSMutableArray) -> Void)?       // 当分页合并后的回调

        public init(dataList: NSMutableArray) {
            self.dataList = dataList
            self.tempList = NSMutableArray()
            loadStartPage()
        }

        public func loadStartPage() -> LoadListPageUiTaskInfo {
            self.loadingStatus = LoadListPageUiTask.LOAD_START_PAGE;
            self.currentPage = startPage - 1;
            self.toPagePointer = self.currentPage + 1;
            self.endPage = LoadListPageUiTask.END_PAGE_NO_POINT;
            isLoadTempListEmpty = false;
            return self
        }

        public func loadNextPage() -> LoadListPageUiTaskInfo {
            self.loadingStatus = LoadListPageUiTask.LOAD_NEXT_PAGE;
            self.toPagePointer = self.currentPage + 1;
            return self;
        }

        public func reloadAllPage() -> LoadListPageUiTaskInfo {
            self.loadingStatus = LoadListPageUiTask.LOAD_RELOAD_ALL;
            self.toPagePointer = self.currentPage;
            self.currentPage = startPage - 1;
            return self;
        }

        /// 数据合并与清除
        func combileData() {
            // 加载起始页或者重新加载
            if (loadingStatus == LoadListPageUiTask.LOAD_START_PAGE || loadingStatus == LoadListPageUiTask.LOAD_RELOAD_ALL) {
                dataList.removeAllObjects()

                dataList.addObjects(from: tempList as! [Any])
            }
            // 加载下一页
            else if (loadingStatus == LoadListPageUiTask.LOAD_NEXT_PAGE) {
                isLoadTempListEmpty = tempList.count == 0
                dataList.addObjects(from: tempList as! [Any])
            }
            // 如果加载了数据则回调数据合并接口
            if (onPageCombineListener != nil) {
                onPageCombineListener?(self, dataList)
            }
            // 加载完毕之后设置状态
            tempList.removeAllObjects()
            currentPage = toPagePointer
        }

        func clearTemp() {
            tempList.removeAllObjects()
        }

        /// 修改初始设置
        public func resetStartPage(startPage: Int) -> LoadListPageUiTaskInfo {
            self.startPage = startPage
            self.currentPage = startPage - 1
            self.toPagePointer = startPage
            return self
        }

        /// 修改初始设置
        public func setPageSize(pageSize: Int) -> LoadListPageUiTaskInfo {
            self.pageSize = pageSize
            return self
        }

        public func getPageSize() -> Int {
            return pageSize
        }

        public func setCurrentPointer(currentPointer: Int) -> LoadListPageUiTaskInfo {
            self.currentPage = currentPointer
            correctPagePointer()
            return self
        }

        public func moveCurrentPointer(offset: Int) -> LoadListPageUiTaskInfo {
            self.currentPage += offset
            correctPagePointer()
            return self
        }

        private func correctPagePointer() {
            if (self.currentPage < self.startPage - 1) {
                self.currentPage = self.startPage - 1
            }
            if (self.currentPage >= self.toPagePointer) {
                self.toPagePointer = self.currentPage + 1
            }
        }

        public func setOnPageCombineListener(onPageCombineListener: ((LoadListPageUiTaskInfo, NSMutableArray) -> Void)?) -> LoadListPageUiTaskInfo {
            self.onPageCombineListener = onPageCombineListener
            return self
        }

        /// 设置最后一页的页码
        public func setEndPage(endPage: Int) ->LoadListPageUiTaskInfo {
            self.endPage = endPage
            return self
        }

        /// 设置末尾页的页码
        /// 该方法将会自动计算出最后一页的页码
        public func setEndIndex(endIndex: Int) -> LoadListPageUiTaskInfo {
            endPage = Int((Double(startPage) + ceil(Double(endIndex) / Double(pageSize)) - 1))
            return self
        }

        /// 是否已经加载了最后一页的数据，该方法应该在任务生命周期回调中使用，并且必须设置最后一页的页码才能得到正确的判断
        /// 判断依据：本次加载数据小于页大小、达到指定的最后一页、尝试加载一下页时无数据
        public func isLoadedEndPage() -> Bool {
            if (endPage == END_PAGE_NO_POINT) {
                return isLoadTempListEmpty
            } else {
                return endPage >= 0 && currentPage >= endPage
            }
        }

        /// 获取内部存储数据

        public func getDataList() -> NSMutableArray {
            return dataList
        }

        func getTempList() -> NSMutableArray {
            return tempList
        }
        
        /// 获取加载时的页码区间
        
        func getLoadFromPage() -> Int {
            return currentPage + 1
        }

        func getLoadToPage() -> Int {
            return toPagePointer
        }

        func getLoadingStatus() -> Int {
            return loadingStatus
        }
    }

    /// 对loadListPageBody的一个默认实现
    func onLoadListPage(task: LoadListPageUiTask, dataList: NSMutableArray, tempList: NSMutableArray, fromPage: Int, toPage: Int, pageSize: Int) {
        //-- 开始阶段
        if (task.taskInfo.getLoadingStatus() == LoadListPageUiTask.LOAD_START_PAGE) {
            task.notifyStart(tipData: "正在刷新数据...")
        } else if (task.taskInfo.getLoadingStatus() == LoadListPageUiTask.LOAD_RELOAD_ALL) {
            task.notifyStart(tipData: "正在刷新数据...")
        } else if (task.taskInfo.getLoadingStatus() == LoadListPageUiTask.LOAD_NEXT_PAGE) {
            task.notifyStart(tipData: "正在加载数据...")
        }
        //-- 加载具体数据阶段
        for page in fromPage...toPage {
            loadSimplePage?(task, dataList, tempList, page, pageSize)
        }
        //-- 扫尾工作阶段
        if (task.taskInfo.getLoadingStatus() == LoadListPageUiTask.LOAD_START_PAGE) {
            task.notifySuccess(tipData: "刷新成功");
        } else if (task.taskInfo.getLoadingStatus() == LoadListPageUiTask.LOAD_RELOAD_ALL) {
            task.notifySuccess(tipData: "刷新成功");
        } else if (task.taskInfo.getLoadingStatus() == LoadListPageUiTask.LOAD_NEXT_PAGE) {
            task.notifySuccess(tipData: "加载成功");
        }
    }
}

/// 用于转化异步方法为同步方法的工具
public class Fulture<T> {
    let semaphore = DispatchSemaphore(value: 0)     // 控制执行流程的信号量
    var error: Error?                               // 检测是否有错误的异常
    var data: T?                                    // 加载的数据

    func load(onLoadData: ((Fulture<T>) -> Void)?) -> Fulture {
        DispatchQueue.global().async {
            onLoadData?(self)
        }
        return self
    }

    /// 异步任务执行成功
    public func success(data: T) {
        self.data = data
        semaphore.signal()
    }

    /// 异步任务执行失败
    public func error(error: Error) {
        self.error = error
        semaphore.signal()
    }

    /// 获取异步任务执行的结果
    public func get() throws -> T? {
        semaphore.wait()
        if (error == nil) {
            return data
        } else {
            throw error!
        }
    }
}