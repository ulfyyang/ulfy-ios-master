//
// Created by 123 on 2019-08-14.
// Copyright (c) 2019 SparkUlfy. All rights reserved.
//

import UIKit
import SnapKit

open class UlfyBaseNibView: UIView {

    public init() {
        super.init(frame: CGRect.zero)
        UiUtils.inflateNibToUIView(uiView: self)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}