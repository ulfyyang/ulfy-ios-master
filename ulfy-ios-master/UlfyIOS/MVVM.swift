//
// Created by 123 on 2019-08-09.
// Copyright (c) 2019 SparkUlfy. All rights reserved.
//

import Foundation

/// View 需要实现的接口
public protocol IView {
    /// 数据绑定方法
    func bind(model: IViewModel)
}

/// 数据模型需要实现的接口
public protocol IViewModel {
    /// 数据模型使用的View
    func getGetViewType() -> UIView.Type
}

/// 针对TableView的数据源适配器
public class SingleDatasource<M: IViewModel>: NSObject, UITableViewDataSource, UITableViewDelegate {
    private var modelList:[M]?                                                      // 数据模型列表
    private var onItemClickListener: ((UITableView, IndexPath, M) -> Void)?         // 单击事件

    /// 构造方法
    public override init() { }

    /// 构造方法
    public init(modelList:[M]) {
        self.modelList = modelList
    }

    /// 绑定到TabView
    public func bindUITableView(tableView: UITableView, supportCellType: UITableViewCell.Type...) {
        for cellType in supportCellType {
            tableView.register(cellType, forCellReuseIdentifier: NSStringFromClass(cellType))
        }
        tableView.dataSource = self
        tableView.delegate = self
    }

    /// 设置显示的数据
    public func setData(modelList: [M]) {
        self.modelList = modelList
    }

    /// 设置单击事件
    public func setOnItemClickListener(onItemClickListener: ((UITableView, IndexPath, M) -> Void)?) {
        self.onItemClickListener = onItemClickListener
    }

    /// -----------------------------  复写方法  -----------------------------

    /// 点击事件
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        onItemClickListener?(tableView, indexPath, modelList![indexPath.row])
    }

    /// 获取每一行的样式
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let convertView = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(modelList![indexPath.row].getGetViewType()))
        // 去除点击效果
        convertView?.selectionStyle = UITableViewCell.SelectionStyle.none
        // 执行数据绑定
        if (convertView is IView) {
            (convertView as! IView).bind(model: modelList![indexPath.row])
        }
        return convertView!
    }

    /// 每组显示的数量
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return modelList?.count ?? 0
    }
}