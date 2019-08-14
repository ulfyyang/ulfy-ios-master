//
// Created by 123 on 2019-08-14.
// Copyright (c) 2019 SparkUlfy. All rights reserved.
//

import UIKit

// ------------------------------------------------------------------------
// tableView的基本
class TableViewController: UIViewController {
    private var dataSource = DataSource()

    // 注意: Swift中mark注释的格式: MARK:-
    // MARK:- 属性
    let cellID = "cell"

    override func viewDidLoad() {
        super.viewDidLoad()

        // 1.创建tableView,并添加的控制器的view
        let tableView = UITableView(frame: view.bounds)

        // 2.设置数据源代理（因为这里是弱引用，因此必须要在外部以成员变量的方式编写数据源）
        tableView.dataSource = dataSource
        tableView.delegate = dataSource

        // 3.添加到控制器的view
        view.addSubview(tableView)

        // 4.注册cell
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellID)
    }
}

class DataSource: NSObject, UITableViewDataSource, UITableViewDelegate {

    /// 设置一共有多少组数据
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    /// 设置每组数据的数量
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }

    /// 获取具体的行
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        // 去除点击效果
        cell?.selectionStyle = UITableViewCell.SelectionStyle.none
        cell?.textLabel?.text = "测试数据\(indexPath.row)"
        return cell!
    }

    /// 设置点击事件
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("点击了\(indexPath.row)")
    }
}