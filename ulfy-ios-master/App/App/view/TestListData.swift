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
        TaskUtils.loadData(executeBody: contentVm.loadData, transponder: ContentDataLoader(container: contentV!, model: contentVm, showFirst: false)
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

import MJRefresh

/// 注意，不要使用和系统命名接近的命名，如TableView，这样很容易造成崩溃
class TestListDataView: BaseView {
    @IBOutlet var dataTV: UITableView!
    private var dataSource = SingleDatasource<TestListDataCM>()
    private var vm: TestListDataVM!
    private var refresher: MJRefresher!

    // 支持组件：UIScrollView、UITableView、UICollectionView、UIWebView

//    let header = MJRefreshNormalHeader()
//    let footer = MJRefreshAutoNormalFooter()      // 在ios11上会触发多次回调
    let footer = MJRefreshBackStateFooter()

    override init() {
        super.init()
        initView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initView()
    }

    private func initView() {
        refresher = TaskUtils.configLoadDataRefresh(tableView: self.dataTV) { refresher in
            print("刷新了...")
            self.dataTV.reloadData()
        }

        // 上拉加载
        footer.setRefreshingTarget(self, refreshingAction: #selector(loadData))
        footer.setTitle("上拉加载...", for: .idle)
        footer.setTitle("上拉加载...", for: .pulling)
        footer.setTitle("正在加载...", for: .refreshing)
        footer.setTitle("正在加载...", for: .willRefresh)
        footer.setTitle("没有了", for: .noMoreData)
        self.dataTV.mj_footer = footer
//        self.dataTV.mj_footer.isHidden = true                               // 禁用上拉加载
    }

    override func bind(model: IViewModel) {
        vm = (model as! TestListDataVM)
        refresher.updateExecuteBody(executeBody: vm.loadData)
        dataSource.bindUITableView(tableView: dataTV, supportCellType: TestListDataCell.self)
        dataSource.setOnItemClickListener { tableView, indexPath, cm in
            print("点击了\(indexPath.row)")
        }
        dataSource.setData(modelList: vm.cmList)
    }

    @objc func loadData() {
        sleep(2)
        print("加载了...")
        for _ in 0..<10 {
            vm.cmList.add(TestListDataCM())
        }
        print(vm.cmList.count)
        self.dataTV.reloadData()
        footer.endRefreshing()
    }
}

class TestListDataVM: BaesVM {
    var cmList = NSMutableArray()

    func loadData(task: LoadDataUiTask) {
        task.notifyStart(tipData: "正在加载...")
        self.cmList.removeAllObjects()
        for _ in 1...25 {
            self.cmList.add(TestListDataCM())
        }
        sleep(2)
        task.notifySuccess(tipData: "加载成功")
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