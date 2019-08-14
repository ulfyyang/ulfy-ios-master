//
// Created by 123 on 2019-08-14.
// Copyright (c) 2019 SparkUlfy. All rights reserved.
//

import UIKit
import UlfyIOS

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
