//
//  Loader.swift
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

/// 内容加载器，该加载器会在页面的指定位置上进行操作
public class ContentDataLoader : Transponder {
    private var container: UIView                                       // 执行过程中操作的容器
    private var model: IViewModel                                       // 当任务执行成功后使用的数据模型
    private var view: UIView!                                           // 执行成功后保留的View，保留是为了尽可能的复用
    private var showFirst: Bool                                         // 是否有限显示出来
    private var contentDataLoaderConfig: ContentDataLoaderConfig        // 表现配置
    private var onCreateView: ((ContentDataLoader, UIView) -> Void)?    // 当View被创建时的回调
    private var onReload: (() -> Void)?                                 // 点击重试执行的操作

    public init(container: UIView, model: IViewModel, showFirst: Bool) {
        self.container = container
        self.model = model
        self.showFirst = showFirst
        self.contentDataLoaderConfig = UlfyConfig.TransponderConfig.contentDataLoaderConfig
        super.init()
        if (showFirst) {
            view = model.getViewType().init()
            onCreateView?(self, view)
            UiUtils.displayViewOnContainer(view: view, container: container)
        }
    }

    public final func setContentDataLoaderConfig(contentDataLoaderConfig: ContentDataLoaderConfig) -> ContentDataLoader {
        self.contentDataLoaderConfig = contentDataLoaderConfig
        return self
    }

    override func onNetError(data: Any) {
        let netErrorView: ReloadView = contentDataLoaderConfig.getNetErrorView()
        netErrorView.setOnReloadListener(onReload: onReload)
        if (netErrorView is TipView) {
            (netErrorView as! TipView).setTipMessage(message: data)
        }
        UiUtils.displayViewOnContainer(view: netErrorView as! UIView, container: container)
    }

    override func onStart(data: Any) {
        if (!showFirst) {
            let loadingView: TipView = contentDataLoaderConfig.getLoadingView()
            loadingView.setTipMessage(message: data)
            UiUtils.displayViewOnContainer(view: loadingView as! UIView, container: container)
        }
    }

    override func onSuccess(data: Any) {
        if (showFirst) {
            (view as! IView).bind(model: model)
        } else {
            view = model.getViewType().init()
            onCreateView?(self, view)
            (view as! IView).bind(model: model)
            UiUtils.displayViewOnContainer(view: view, container: container)
        }
    }

    override func onFail(data: Any) {
        let failView: ReloadView = contentDataLoaderConfig.getFailView()
        failView.setOnReloadListener(onReload: onReload)
        if (failView is TipView) {
            (failView as! TipView).setTipMessage(message: data)
        }
        UiUtils.displayViewOnContainer(view: failView as! UIView, container: container)
    }

    public final func getView() -> UIView {
        return self.view
    }

    /// 当View被创建时的回调
    public final func onCreateView(onCreateView: @escaping (ContentDataLoader, UIView) -> Void) -> ContentDataLoader {
        self.onCreateView = onCreateView
        return self
    }

    /// 设置重试操作
    public final func setOnReloadListener(onReload: (() -> Void)?) -> ContentDataLoader {
        self.onReload = onReload
        return self
    }
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