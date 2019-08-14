//
// Created by 123 on 2019-08-13.
// Copyright (c) 2019 SparkUlfy. All rights reserved.
//

import UIKit
import SnapKit

/// 以弹出框的方式进行数据处理
public class DialogProcesser: Transponder {
    private var onFail: ((DialogProcesser) -> Void)?
    private var onSuccess: ((DialogProcesser) -> Void)?

    public override init() {
    }

    override func onNetError(data: Any) {
        super.onNetError(data: data)
    }

    override func onStart(data: Any) {
        DialogUtils.showDialog()
    }

    override func onFail(data: Any) {
        if (onFail == nil) {

        } else {
            onFail!(self)
        }
    }

    override func onSuccess(data: Any) {
        onSuccess?(self)
    }

    override func onFinish(data: Any) {
        DialogUtils.dismissDialog()
    }

    public func setOnFail(onFail: @escaping (DialogProcesser) -> Void) -> DialogProcesser {
        self.onFail = onFail
        return self
    }

    public func setOnSuccess(onSuccess: @escaping (DialogProcesser) -> Void) -> DialogProcesser {
        self.onSuccess = onSuccess
        return self
    }
}