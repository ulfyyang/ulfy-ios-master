//
// Created by 123 on 2019-08-16.
// Copyright (c) 2019 SparkUlfy. All rights reserved.
//

import Foundation
import MJRefresh

/// 下拉刷新器
/// 支持组件：UIScrollView、UITableView、UICollectionView、UIWebView
public class MJRefresher: Transponder {
    private var tableView: UITableView
    private var netUiTask: NetUiTask!
    private var loadDataUiTask: LoadDataUiTask!
    private var loadListPageUiTask: LoadListPageUiTask!
    private var taskExecutor: TaskExecutor?
    private var onRefreshSuccessListener: ((MJRefresher) -> Void)?

    public init(tableView: UITableView, onRefreshSuccessListener: ((MJRefresher) -> Void)?) {
        self.tableView = tableView
        self.onRefreshSuccessListener = onRefreshSuccessListener
        super.init()
        self.initSetting()
    }

    private func initSetting() {
        let header = MJRefreshNormalHeader()
        header.lastUpdatedTimeLabel.isHidden = true                                     // 隐藏时间
//        header.stateLabel.isHidden = true                                             // 隐藏状态文字，这会隐藏所有的文字控件只留下箭头和指示器
        header.setTitle("下拉刷新", for: .idle)                                          // 下拉时的问题
        header.setTitle("释放刷新", for: .pulling)                                       // 会触发更新时的提示
        header.setTitle("正在刷新...", for: .refreshing)                                 // 更新时的提示
//        header.stateLabel.font = UIFont.systemFont(ofSize: 15)                        // 修改字体
//        header.lastUpdatedTimeLabel.font = UIFont.systemFont(ofSize: 13)              // 修改字体
//        header.stateLabel.textColor = UIColor.red                                     // 修改文字颜色
//        header.lastUpdatedTimeLabel.textColor = UIColor.blue                          // 修改文字颜色
        header.setRefreshingTarget(self, refreshingAction: #selector(onRefreshData))    // 设置下拉刷新触发的方法
        tableView.mj_header = header                                                    // 设置与之关联的组件
    }
    
    @objc private func onRefreshData() {
        if (loadListPageUiTask != nil) {
            loadListPageUiTask.getTaskInfo().loadStartPage()
        }
        if (taskExecutor == nil) {
            TaskExecutor.defaultConcurrentTaskExecutor.post(task: netUiTask)
        } else {
            taskExecutor?.post(task: netUiTask)
        }
    }
    
    func buildLoadDataRefresher() -> MJRefresher {
        loadDataUiTask = LoadDataUiTask(executeBody: nil, transponder: self)
        netUiTask = NetUiTask(proxyTask: loadDataUiTask, transponder: self)
        return self
    }

    func buildLoadListPageRefresher() -> MJRefresher {
        loadListPageUiTask = LoadListPageUiTask(taskInfo: nil, loadSimplePage: nil, transponder: self)
        netUiTask = NetUiTask(proxyTask: loadListPageUiTask, transponder: self)
        return self
    }

    public func updateExecuteBody(executeBody: ((LoadDataUiTask) -> Void)?) {
        loadDataUiTask.setExecuteBody(executeBody: executeBody)
    }

    public func updateExecuteBody(taskInfo: LoadListPageUiTask.LoadListPageUiTaskInfo, loadSimplePage: ((LoadListPageUiTask, NSMutableArray, NSMutableArray, Int, Int) -> Void)?) -> MJRefresher {
        loadListPageUiTask.setTaskInfo(taskInfo: taskInfo)
        loadListPageUiTask.setLoadSimplePage(loadSimplePage: loadSimplePage)
        return self
    }
    
    public func setTaskExecutor(taskExecutor: TaskExecutor) -> MJRefresher {
        self.taskExecutor = taskExecutor
        return self
    }

    public func startRefresh() {
        tableView.mj_header.beginRefreshing()
    }
    
    override func onNoNetConnection(data: Any) {
        super.onNoNetConnection(data: data)
        tableView.mj_header.endRefreshing()
    }

    override func onNetError(data: Any) {
        super.onNetError(data: data)
        tableView.mj_header.endRefreshing()
        UiUtils.show(message: data)
    }

    override func onSuccess(data: Any) {
        onRefreshSuccessListener?(self)
    }

    override func onFinish(data: Any) {
        tableView.mj_header.endRefreshing()
    }
}

/// 上拉加载器
/// 支持组件：UIScrollView、UITableView、UICollectionView、UIWebView
public class MJLoader: Transponder {
    private var tableView: UITableView
    private var netUiTask: NetUiTask!
    private var loadListPageUiTask: LoadListPageUiTask!
    private var taskExecutor: TaskExecutor?
    private var onLoadSuccessListener: ((MJLoader) -> Void)?

    public init(tableView: UITableView, onLoadSuccessListener: ((MJLoader) -> Void)?) {
        self.tableView = tableView
        self.onLoadSuccessListener = onLoadSuccessListener
        super.init()
        self.loadListPageUiTask = LoadListPageUiTask(taskInfo: nil, loadSimplePage: nil, transponder: self)
        self.netUiTask = NetUiTask(proxyTask: loadListPageUiTask, transponder: self)
        self.initSetting()
    }

    private func initSetting() {
//    let footer = MJRefreshAutoNormalFooter()                                      // 在ios11上会触发多次回调
        let footer = MJRefreshBackStateFooter()
        footer.setTitle("上拉加载...", for: .idle)                                   // 上拉时的提示
        footer.setTitle("上拉加载...", for: .pulling)                                // 上拉时的提示
        footer.setTitle("正在加载...", for: .refreshing)                             // 正在加载时的提示
        footer.setTitle("正在加载...", for: .willRefresh)                            // 加载完毕即将显示的提示
        footer.setTitle("没有了", for: .noMoreData)                                  // 当没有数据时的提示
        footer.setRefreshingTarget(self, refreshingAction: #selector(onLoadData))   // 设置上拉加载触发的方法
        tableView.mj_footer = footer                                                // 设置与之关联的组件
    }

    @objc private func onLoadData() {
        if (loadListPageUiTask != nil) {
            loadListPageUiTask.getTaskInfo().loadNextPage()
        }
        if (taskExecutor == nil) {
            TaskExecutor.defaultConcurrentTaskExecutor.post(task: netUiTask)
        } else {
            taskExecutor?.post(task: netUiTask)
        }
    }

    public func updateExecuteBody(taskInfo: LoadListPageUiTask.LoadListPageUiTaskInfo, loadSimplePage: ((LoadListPageUiTask, NSMutableArray, NSMutableArray, Int, Int) -> Void)?) {
        loadListPageUiTask.setTaskInfo(taskInfo: taskInfo)
        loadListPageUiTask.setLoadSimplePage(loadSimplePage: loadSimplePage)
    }

    public func setTaskExecutor(taskExecutor: TaskExecutor) -> MJLoader {
        self.taskExecutor = taskExecutor
        return self
    }

    override func onNoNetConnection(data: Any) {
        super.onNoNetConnection(data: data)
        tableView.mj_footer.endRefreshing()
    }

    override func onNetError(data: Any) {
        super.onNetError(data: data)
        tableView.mj_footer.endRefreshing()
        UiUtils.show(message: data)
    }

    override func onSuccess(data: Any) {
        onLoadSuccessListener?(self)
    }

    override func onFinish(data: Any) {
        tableView.mj_footer.endRefreshing()
    }
}