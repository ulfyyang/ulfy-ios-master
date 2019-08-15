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
    func run() { }

    /// 通知任务开始执行了
    final func notifyStart() {
        isRunning = true
        onStart?()
    }

    // 通知任务执行完成了
    final func notifyFinish() {
        isRunning = false
        onFinish?()
    }
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

import SnapKit

/// 内容加载器，该加载器会在页面的指定位置上进行操作
public class ContentDataLoader : Transponder {
    private var container: UIView                                       // 执行过程中操作的容器
    private var model: IViewModel                                       // 当任务执行成功后使用的数据模型
    private var view: UIView?                                           // 执行成功后保留的View，保留是为了尽可能的复用
    private var showFirst: Bool                                         // 是否有限显示出来
    private var contentDataLoaderConfig: ContentDataLoaderConfig        // 表现配置
    private var onCreateView: ((ContentDataLoader, UIView) -> Void)?    // 当View被创建时的回调
    private var onReload: (() -> Void)?                                 // 点击重试执行的操作

    public init(container: UIView, model: IViewModel, showFirst: Bool) {
        self.container = container
        self.model = model
        self.showFirst = showFirst
        self.contentDataLoaderConfig = UlfyConfig.TransponderConfig.contentDataLoaderConfig
        super.init()
        if (showFirst) {
            view = model.getGetViewType().init()
            onCreateView?(self, view!)
            UiUtils.displayViewOnContainer(view: view!, container: container)
        }
    }

    public final func setContentDataLoaderConfig(contentDataLoaderConfig: ContentDataLoaderConfig) -> ContentDataLoader {
        self.contentDataLoaderConfig = contentDataLoaderConfig
        return self
    }

    override func onNetError(data: Any) {
        let netErrorView: ReloadView = contentDataLoaderConfig.getNetErrorView()
        netErrorView.setOnReloadListener(onReload: onReload)
        if (netErrorView is TipView) {
            (netErrorView as! TipView).setTipMessage(message: data)
        }
        UiUtils.displayViewOnContainer(view: netErrorView as! UIView, container: container)
    }

    override func onStart(data: Any) {
        if (!showFirst) {
            let loadingView: TipView = contentDataLoaderConfig.getLoadingView()
            loadingView.setTipMessage(message: data)
            UiUtils.displayViewOnContainer(view: loadingView as! UIView, container: container)
        }
    }

    override func onSuccess(data: Any) {
        if (showFirst) {
            (view as! IView).bind(model: model)
        } else {
            view = model.getGetViewType().init()
            onCreateView?(self, view!)
            (view as! IView).bind(model: model)
            UiUtils.displayViewOnContainer(view: view!, container: container)
        }
    }

    override func onFail(data: Any) {
        let failView: ReloadView = contentDataLoaderConfig.getFailView()
        failView.setOnReloadListener(onReload: onReload)
        if (failView is TipView) {
            (failView as! TipView).setTipMessage(message: data)
        }
        UiUtils.displayViewOnContainer(view: failView as! UIView, container: container)
    }

    public final func getView() -> UIView? {
        return self.view
    }

    /// 当View被创建时的回调
    public final func onCreateView(onCreateView: @escaping (ContentDataLoader, UIView) -> Void) -> ContentDataLoader {
        self.onCreateView = onCreateView
        return self
    }

    /// 设置重试操作
    public final func setOnReloadListener(onReload: (() -> Void)?) -> ContentDataLoader {
        self.onReload = onReload
        return self
    }
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
    final override func run() {
        if (!isCancelUiHandler()) {
            if (executeBody == nil) {
                notifySuccess(tipData: "加载完成")
            } else {
                executeBody?(self)
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

