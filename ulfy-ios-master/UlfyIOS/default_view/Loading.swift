//
//  Loading.swift
//  App
//
//  Created by 123 on 2019/8/9.
//  Copyright © 2019 SparkUlfy. All rights reserved.
//

import UIKit
import SnapKit

/// 具有提示功能的View需要实现的协议
public protocol TipView {
    func setTipMessage(message: Any)
}

/// 具有重新加载能力的View需要实现的协议
public protocol ReloadView {
    func setOnReloadListener(onReload: (() -> Void)?)
}

/// 当加载页面正在加载中时显示的界面
class ContentDataLoaderLoadingView: UIView, TipView {
    private var messageLabel: UILabel?              // 显示提示消息的标签

    init() {
        super.init(frame: CGRect.zero)
        layoutLoadingUI(parent: self)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    /// 设置提示信息
    final func setTipMessage(message: Any) {
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
        container.snp.makeConstraints { maker in
            maker.center.equalTo(parent)
            maker.size.lessThanOrEqualTo(parent)
        }

        // ------------- 加载指示器 -------------
        let activityIndicator = UIActivityIndicatorView()
        container.addSubview(activityIndicator)

        // 加载指示器属性
        activityIndicator.style = UIActivityIndicatorView.Style.gray
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()

        // 加载指示器约束
        activityIndicator.snp.makeConstraints { maker in
            maker.centerX.equalTo(container)
            maker.top.equalTo(container).inset(20)
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
        label.snp.makeConstraints { maker in
            maker.centerX.equalTo(container)
            maker.top.equalTo(activityIndicator.snp.bottom).offset(20)
            maker.left.right.bottom.equalTo(container).inset(20)
        }
    }
}

/// 当加载内容时出现错误重新加载显示的界面
class ContentDataLoaderFailedView: UIView, ReloadView, TipView {
    private var messageLabel: UILabel?                  // 显示提示消息的标签
    private var reloadButton: UIButton?                 // 重新加载的按钮
    private var onReload: (() -> Void)?                 // 点击重试执行的操作

    init() {
        super.init(frame: CGRect.zero)
        layoutLoadFailedUI(parent: self)
        injectClickTarget()
//        backgroundColor = UIColor.red
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    /// 设置重试操作
    func setOnReloadListener(onReload: (() -> Void)?) {
        self.onReload = onReload
    }

    /// 设置提示信息
    func setTipMessage(message: Any) {
        messageLabel?.text = message as? String
    }

    @objc func reload() {
        self.onReload?()
    }

    /// 控件容器
    func layoutLoadFailedUI(parent: UIView) {
        // ------------- 控件容器 -------------
        let container = UIView()
        parent.addSubview(container)

        // 控件容器属性
//        container.backgroundColor = UIColor.green

        // 控件容器约束
        container.snp.makeConstraints { maker in
            maker.center.equalTo(parent)
            maker.size.lessThanOrEqualTo(parent)
        }

        // ------------- 标签 -------------
        let label = UILabel()
        container.addSubview(label)
        self.messageLabel = label

        // 标签属性
        label.numberOfLines = 0
        label.text = "测试文本"
//        label.backgroundColor = UIColor.blue

        // 标签文字约束
        label.snp.makeConstraints { maker in
            maker.top.equalTo(container).inset(20)
            maker.left.right.equalTo(container).inset(20)
        }

        // ------------- 按钮 -------------
        let button:UIButton = UIButton(type:.custom)
        container.addSubview(button)
        self.reloadButton = button

        // 按钮属性
        button.setTitle("重新加载", for: .normal) //普通状态下的文字
        button.setTitleColor(UIColor.black, for: .normal)

        // 按钮约束
        button.snp.makeConstraints { maker in
            maker.top.equalTo(label.snp.bottom).offset(20)
            maker.left.right.bottom.equalTo(container).inset(20)
            maker.centerX.equalTo(parent)
        }
    }

    /// 注入点击事件
    private func injectClickTarget() {
        self.reloadButton?.addTarget(self, action:#selector(reload), for:.touchUpInside)
    }
}