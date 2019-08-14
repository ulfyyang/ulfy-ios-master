//
// Created by 123 on 2019-08-14.
// Copyright (c) 2019 SparkUlfy. All rights reserved.
//

import UIKit
import UlfyIOS
import SnapKit

class ContentDataController: UIViewController {
    var vm: ContentDataVM = ContentDataVM()
    let box: UIView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        box.backgroundColor = UIColor.white
        self.view.addSubview(box)
        box.snp.makeConstraints { maker in
            maker.size.equalToSuperview()
        }
        self.initContent()
    }

    func initContent() {
        TaskUtils.loadData(executeBody: vm.loadData(), transponder: ContentDataLoader(container: self.box, model: vm, showFirst: false).setOnReloadListener {
            self.initContent()
        })
    }
}

class ContentDataView: BaseView {
    @IBOutlet var contentLB: UILabel!
    private var vm: ContentDataVM?
    
    override init() {
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func bind(model: IViewModel) {
        vm = model as? ContentDataVM
        contentLB.text = vm?.content

        TaskUtils.loadData(executeBody: vm!.loadData(), transponder: DialogProcesser().setOnSuccess { processer in
            print("处理完了")
        })
    }


}

class ContentDataVM: IViewModel {
    var content: String = "加载成功的内容"

    func loadData() -> (LoadDataUiTask) -> Void {
        return provideOnExecutor { task in
            task.notifyStart(tipData: "正在加载...")
            sleep(2)
            task.notifySuccess(tipData: "加载成功")
        }
    }
    
    private func provideOnExecutor(executeBody: @escaping (LoadDataUiTask) -> Void) -> (LoadDataUiTask) -> Void {
        return executeBody
    }
    
    func getGetViewType() -> UIView.Type {
        return ContentDataView.self
    }
}
