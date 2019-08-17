//
// Created by 123 on 2019-08-09.
// Copyright (c) 2019 SparkUlfy. All rights reserved.
//

import Foundation

class Envirnment {
    static let BUNDLE_ID: String = "com.ulfy.UlfyIOS"       // 唯一标识ID
    static let LOADING_STORY_BOARD = "Loading"              // 加载中默认相关页面
    static let LOADING_VIEW_CONTROLLER = "Loading"          // 加载中控制器

    static let CODE_CREATE_FILE_FAIL = -1                   // 文件创建失败抛出的异常错误码
    static let CODE_DESERIALIZE_JSON_FAIL = -2              // 解析JSON为实体失败抛出的异常错误码
}

/// 框架总配置
public class UlfyConfig {
    public class TransponderConfig {
        public static var contentDataLoaderConfig: ContentDataLoaderConfig = DefaultContentDataLoaderConfig()
    }
}

/// 为缓存提供目录的配置
class CacheConfig {
    /// 获得本地实体缓存目录
    public static func getLocalEntityCacheDir() -> String {
        let dir = NSHomeDirectory() + "/Library/Caches/local_entity_cache"
        try! FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)
        return dir
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