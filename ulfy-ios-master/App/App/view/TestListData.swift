//
// Created by 123 on 2019-08-14.
// Copyright (c) 2019 SparkUlfy. All rights reserved.
//

import UIKit
import UlfyIOS

// ------------------------------------------------------------------------
// tableView的基本
/// 注意： Controller之前的单词不要和xib文件名重名，否则会自动去寻找其对应的xib文件导致错乱
class TestListDataController: TitleContentController {
    var contentVm: TestListDataVM!
    var contentView: TestListDataView!

    override func viewDidLoad() {
        super.viewDidLoad()
        initModel()
        initContent()
        initController()
    }

    func initModel() {
        contentVm = TestListDataVM()
    }

    func initContent() {
        TaskUtils.loadData(executeBody: contentVm.loadData(), transponder: ContentDataLoader(container: contentV!, model: contentVm, showFirst: false)
                .onCreateView { loader, view in
                    self.contentView = (view as! TestListDataView)
                }
                .setOnReloadListener {
                    self.initContent()
                }
        )
    }

    func initController() {

    }
}

/// 注意，不要使用和系统命名接近的命名，如TableView，这样很容易造成崩溃
class TestListDataView: BaseView {
    @IBOutlet var dataTV: UITableView!
    private var dataSource = SingleDatasource<TestListDataCM>()
    private var vm: TestListDataVM!

    override init() {
        super.init()
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initView()
    }

    private func initView() {

    }

    override func bind(model: IViewModel) {
        vm = (model as! TestListDataVM)
        dataSource.bindUITableView(tableView: dataTV, supportCellType: TestListDataCell.self)
        dataSource.setOnItemClickListener { tableView, indexPath, cm in
            print("点击了\(indexPath.row)")
        }
        dataSource.setData(modelList: vm.cmList)
    }
}

class TestListDataVM: BaesVM {
    var cmList: [TestListDataCM] = []

    func loadData() -> (LoadDataUiTask) -> Void {
        return provideExecuteBody { task in
            task.notifyStart(tipData: "正在加载...")
            for _ in 1...10 {
                self.cmList.append(TestListDataCM())
            }
            sleep(2)
            task.notifySuccess(tipData: "加载成功")
        }
    }

    override func getViewType() -> UIView.Type {
        return TestListDataView.self
    }
}

class TestListDataCell: BaseCell {
    @IBOutlet var contentLB: UILabel!
    private var vm: TestListDataCM!

    override func bind(model: IViewModel) {
        vm = (model as! TestListDataCM)
        self.contentLB.text = vm.content
    }
}

class TestListDataCM: BaseCM {
    var content: String = "这是测试内容"

    override func getViewType() -> UIView.Type {
        return TestListDataCell.self
    }
}
