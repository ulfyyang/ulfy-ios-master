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

    public func updateExecuteBody(executeBody: ((LoadDataUiTask) -> Void)?) {
        loadDataUiTask.setExecuteBody(executeBody: executeBody)
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
        print(data)
    }

    override func onSuccess(data: Any) {
        onRefreshSuccessListener?(self)
    }

    override func onFinish(data: Any) {
        tableView.mj_header.endRefreshing()
    }
}