//
// Created by 123 on 2019-08-09.
// Copyright (c) 2019 SparkUlfy. All rights reserved.
//

import Foundation

class Envirnment {
    static let BUNDLE_ID: String = "com.ulfy.UlfyIOS"       // 唯一标识ID
    static let LOADING_STORY_BOARD = "Loading"              // 加载中默认相关页面
    static let LOADING_VIEW_CONTROLLER = "Loading"          // 加载中控制器
}

/// 框架总配置
public class UlfyConfig {
    public class TransponderConfig {
        public static var contentDataLoaderConfig: ContentDataLoaderConfig = DefaultContentDataLoaderConfig()
    }
}

/// 内容加载器配置
public protocol ContentDataLoaderConfig {
    func getNetErrorView() -> ReloadView
    func getFailView() -> ReloadView
    func getLoadingView() -> TipView
}

public class DefaultContentDataLoaderConfig: ContentDataLoaderConfig {
    public func getNetErrorView() -> ReloadView {
        return ContentDataLoaderFailedView()
    }
    public func getFailView() -> ReloadView {
        return ContentDataLoaderFailedView()
    }
    public func getLoadingView() -> TipView {
        return ContentDataLoaderLoadingView()
    }
}