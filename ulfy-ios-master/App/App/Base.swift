//
// Created by 123 on 2019-08-14.
// Copyright (c) 2019 SparkUlfy. All rights reserved.
//

import UIKit
import UlfyIOS

class BaseController: UlfyBaseController { }

class BaseView: UlfyBaseNibView { }

class BaesVM: UlfyBaseVM { }

class BaseCell: UlfyBaseNibCell { }

class BaseCM: UlfyBaseVM { }

import SnapKit

class TitleContentController: BaseController {
    var contentV: UIView?

    override func viewDidLoad() {
        super.viewDidLoad()
        let box: UIView = UIView()
        box.backgroundColor = UIColor.white
        self.view.addSubview(box)
        box.snp.makeConstraints { maker in
            maker.size.equalToSuperview()
        }

        self.contentV = box
    }
}