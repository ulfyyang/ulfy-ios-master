//
// Created by 123 on 2019-08-14.
// Copyright (c) 2019 SparkUlfy. All rights reserved.
//

import UIKit
import UlfyIOS

class BaseView: UlfyBaseNibView, IView {

    override init() {
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(model: IViewModel) { }

}