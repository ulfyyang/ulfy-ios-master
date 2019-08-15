//
// Created by 123 on 2019-08-14.
// Copyright (c) 2019 SparkUlfy. All rights reserved.
//

import UIKit
import UlfyIOS

// ------------------------------------------------------------------------
// tableView的基本
class TableViewController: UIViewController {
    private var cmList: [TableViewCM] = []
    private let dataSource = SingleDatasource<TableViewCM>()

    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource.setOnItemClickListener { view, path, cm in
            print("点击了\(indexPath.row)")
        }

        for _ in 1...10 {
            cmList.append(TableViewCM())
        }
        let tableView = UITableView(frame: view.bounds)
        dataSource.bindUITableView(tableView: tableView, supportCellType: TableViewCell.self)
        dataSource.setData(modelList: cmList)
        self.view.addSubview(tableView)
    }
}

class TableViewCell: UITableViewCell, IView {
    private var vm: TableViewCM?

    func bind(model: IViewModel) {
        vm = (model as! TableViewCM)
        self.textLabel?.text = vm!.content
    }
}

class TableViewCM: IViewModel {
    var content: String = "这是测试内容"

    func getGetViewType() -> UIView.Type {
        return TableViewCell.self
    }
}