//
//  Loading.swift
//  App
//
//  Created by 123 on 2019/8/9.
//  Copyright © 2019 SparkUlfy. All rights reserved.
//

import UIKit
import SnapKit

protocol TipView {
    func setTipMessage(message: Any)
}

class ContentDataLoadingView: UIView, TipView {
    var messageLabel: UILabel?              // 显示提示消息的标签

    init() {
        super.init(frame: CGRect.zero)
        layoutLoadingUI(parent: self)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    /// 设置提示信息
    func setTipMessage(message: Any) {
        messageLabel?.text = message as? String
    }

    /// 新建一个加载中容器
    private func layoutLoadingUI(parent: UIView) {
        // ------------- 控件容器 -------------
        let container = UIView()
        parent.addSubview(container)

        // 控件容器属性
//        container.backgroundColor = UIColor.red

        // 控件容器约束
        container.snp.makeConstraints { (make) in
            make.center.equalTo(parent)
            make.size.lessThanOrEqualTo(parent)
        }

        // ------------- 加载指示器 -------------
        let activityIndicator = UIActivityIndicatorView()
        container.addSubview(activityIndicator)

        // 加载指示器属性
        activityIndicator.style = UIActivityIndicatorView.Style.gray
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()

        // 加载指示器约束
        activityIndicator.snp.makeConstraints { (make) in
            make.centerX.equalTo(container)
            make.top.equalTo(container).inset(20)
        }

        // ------------- 标签 -------------
        let label = UILabel()
        container.addSubview(label)
        self.messageLabel = label

        // 标签基本属性
//        label.backgroundColor = UIColor.yellow
        label.numberOfLines = 0
        label.text = "测试文本"

        // 标签约束
        label.snp.makeConstraints { (make) in
            make.centerX.equalTo(container)
            make.top.equalTo(activityIndicator.snp.bottom).offset(20)
            make.left.right.bottom.equalTo(container).inset(20)
        }
    }
}
