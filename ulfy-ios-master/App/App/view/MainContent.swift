//
// Created by 123 on 2019-09-03.
// Copyright (c) 2019 SparkUlfy. All rights reserved.
//

import UIKit
import UlfyIOS

class MainController: TitleContentController {
    var contentVm: MainVM!
    var contentView: MainView!

    override func viewDidLoad() {
        super.viewDidLoad()
        initModel()
        initContent()
        initController()
    }

    func initModel() {
        contentVm = MainVM()
    }

    func initContent() {
        TaskUtils.loadData(executeBody: contentVm.loadData, transponder: ContentDataLoader(container: contentV!, model: contentVm, showFirst: false)
                .onCreateView { loader, view in
                    self.contentView = (view as! MainView)
                }
                .setOnReloadListener {
                    self.initContent()
                }
        )
    }

    func initController() {
        navigationBarHidden = true
    }
}

class MainView: BaseView {
    private var vm: MainVM!

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
        vm = (model as! MainVM)
    }

    @IBAction func clickContentDataBT(_ sender: Any) {
        // 以导航的方式跳转，需要UINavigationController支持
        UiUtils.currentViewController()?.navigationController?.pushViewController(ContentDataController(), animated: true)
        // 默认跳转方式，UIViewController支持，从底部弹出跳转
//        UiUtils.currentViewController()?.present(ContentDataController(), animated: true, completion: nil)
    }

    @IBAction func clickTableViewBT(_ sender: Any) {
        // 以导航的方式跳转，需要UINavigationController支持
        UiUtils.currentViewController()?.navigationController?.pushViewController(TestListDataController(), animated: true)
        // 默认跳转方式，UIViewController支持，从底部弹出跳转
//        UiUtils.currentViewController()?.present(TestListDataController(), animated: true, completion: nil)
    }

}

class MainVM: BaseVM {

    func loadData(task: LoadDataUiTask) {
        task.notifyStart(tipData: "正在加载...")
        do {
            task.notifySuccess(tipData: "加载成功")
        } catch {
            task.notifyFail(tipData: error)
        }
    }

    override func getViewType() -> UIView.Type {
        return MainView.self
    }

}
