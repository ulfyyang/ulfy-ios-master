//
// Created by 123 on 2019-08-09.
// Copyright (c) 2019 SparkUlfy. All rights reserved.
//

import Foundation

/// View 需要实现的接口
public protocol IView {
    /// 数据绑定方法
    func bind(model: IViewModel)
}

/// 数据模型需要实现的接口
public protocol IViewModel {
    /// 数据模型使用的View
    func getGetViewType() -> UIView.Type
}