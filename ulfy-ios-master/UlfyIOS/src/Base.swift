//
// Created by 123 on 2019-08-14.
// Copyright (c) 2019 SparkUlfy. All rights reserved.
//

import UIKit

/// 提供全局使用的公共控制器
open class UlfyBaseController: UIViewController {

    public init() {
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

/// 提供Nib绘制界面加载View的公共父类
open class UlfyBaseNibView: UIView, IView {

    /// 构造方法：子类必须实现
    public init() {
        super.init(frame: CGRect.zero)
        UiUtils.inflateNibToUIView(uiView: self)
    }

    /// 构造方法：子类必须实现
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    /// 数据绑定方法
    open func bind(model: IViewModel) { }

}

/// 提供Nib绘制界面加载Cell的公共父类
open class UlfyBaseNibCell: UITableViewCell, IView {

    /// 构造方法：子类必须实现
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        UiUtils.inflateNibToUIView(uiView: self)
    }

    /// 构造方法：子类必须实现
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    /// 数据绑定方法
    open func bind(model: IViewModel) { }

}

/// 数据模型的公共父类
open class UlfyBaseVM: IViewModel {

    /// 公共构造方法
    public init() { }

    /// 提供LoadDataUiTask任务执行的执行体
    public func provideExecuteBody(executeBody: @escaping (LoadDataUiTask) -> Void) -> (LoadDataUiTask) -> Void {
        return executeBody
    }

    /// 数据模型提供的显示界面
    open func getViewType() -> UIView.Type {
        fatalError("getGetViewType() has not been implemented")
    }

}