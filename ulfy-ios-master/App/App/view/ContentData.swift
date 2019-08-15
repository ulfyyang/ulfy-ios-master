//
// Created by 123 on 2019-08-14.
// Copyright (c) 2019 SparkUlfy. All rights reserved.
//

import UIKit
import UlfyIOS
import SnapKit

class ContentDataController: TitleContentController {
    var contentVm: ContentDataVM!
    var contentView: ContentDataView!

    override func viewDidLoad() {
        super.viewDidLoad()
        initModel()
        initContent()
        initController()
    }

    func initModel() {
        contentVm = ContentDataVM()
    }

    func initContent() {
        TaskUtils.loadData(executeBody: contentVm.loadData(), transponder: ContentDataLoader(container: contentV!, model: contentVm, showFirst: false)
                .onCreateView { loader, view in
                    self.contentView = (view as! ContentDataView)
                }
                .setOnReloadListener {
                    self.initContent()
                }
        )
    }

    func initController() {

    }
}

class ContentDataView: BaseView {
    @IBOutlet var contentLB: UILabel!
    private var vm: ContentDataVM!
    
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
        vm = (model as! ContentDataVM)
        contentLB.text = vm.content

        TaskUtils.loadData(executeBody: vm.loadData(), transponder: DialogProcesser().setOnSuccess { processer in
            print("处理完了")
        })
    }
}

class ContentDataVM: BaesVM {
    var content: String = "加载成功的内容"

    func loadData() -> (LoadDataUiTask) -> Void {
        return provideExecuteBody { task in
            task.notifyStart(tipData: "正在加载...")
            sleep(2)
            task.notifySuccess(tipData: "加载成功")
        }
    }
    
    override func getViewType() -> UIView.Type {
        return ContentDataView.self
    }
}
