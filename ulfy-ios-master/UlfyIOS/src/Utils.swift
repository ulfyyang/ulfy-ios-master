//
// Created by 123 on 2019-08-09.
// Copyright (c) 2019 SparkUlfy. All rights reserved.
//

import UIKit
import SnapKit

class Dialog: UIView {
    private var dialogId: String = DialogUtils.ULFY_MAIN_DIALOG_ID                // 弹出框的ID

    public init(dialogId: String) {
        self.dialogId = dialogId
        super.init(frame: CGRect.zero)
        self.backgroundColor = UIColor(white: 0.1, alpha: 0.6)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public func show() {
        DialogRepository.instance.addDialog(dialog: self)
        UIApplication.shared.keyWindow!.addSubview(self)
        self.snp.remakeConstraints { maker in
            maker.size.equalTo(UIApplication.shared.keyWindow!)
        }
    }
    
    public func dismiss() {
        DialogRepository.instance.removeDialog(dialog: self)
        self.removeFromSuperview()
    }

    func getDialogId() -> String {
        return dialogId
    }
}

class DialogRepository {
    public static let instance = DialogRepository()
    private var dialogDirectory:[String: Dialog] = [String: Dialog]()

    func getDialogById(dialogId: String) -> Dialog {
        return dialogDirectory[dialogId]!
    }

    func addDialog(dialog: Dialog) {
        if (dialogDirectory[dialog.getDialogId()] != nil) {
            let oldDialog =  dialogDirectory[dialog.getDialogId()]
            if (oldDialog == dialog) {
                return
            } else {
                oldDialog?.dismiss()
            }
        }
        dialogDirectory[dialog.getDialogId()] = dialog
    }

    func removeDialog(dialog: Dialog) {
        dialogDirectory.removeValue(forKey: dialog.getDialogId())
    }
}

import Toast_Swift

public class DialogUtils {
    public static let ULFY_MAIN_DIALOG_ID = "__ULFY_MAIN_DIALOG_ID__"

    /// 显示一个加载弹窗
    public static func showLoadingDialog() {
        let currentView = UiUtils.currentViewController()?.view
        currentView?.makeToastActivity(.center)
    }

    /// 关闭加载弹窗
    public static func dismissLoadingDialog() {
        let currentView = UiUtils.currentViewController()?.view
        currentView?.hideToastActivity()
    }
    
    public static func showDialog() {
        Dialog(dialogId: ULFY_MAIN_DIALOG_ID).show()
    }

    public static func dismissDialog() {
        let dialog = DialogRepository.instance.getDialogById(dialogId: ULFY_MAIN_DIALOG_ID)
        dialog.dismiss()
    }
}

public class TaskUtils {

    /// 执行一个记载数据的任务
    /// - executeBody           提供任务执行的具体过程
    /// - transponder           提供任务执行的响应器
    public static func loadData(executeBody: @escaping (LoadDataUiTask) -> Void, transponder: Transponder) {
        TaskExecutor.defaultExecutor.post(task: LoadDataUiTask(executeBody: executeBody, transponder: transponder))
    }

    public static func loadData(taskInfo: LoadListPageUiTask.LoadListPageUiTaskInfo, loadSimplePage: ((LoadListPageUiTask, NSMutableArray, NSMutableArray, Int, Int) -> Void)?, transponder: Transponder) {
        let loadListPageUiTask = LoadListPageUiTask(taskInfo: taskInfo, loadSimplePage: loadSimplePage, transponder: transponder)
        TaskExecutor.defaultExecutor.post(task: NetUiTask(proxyTask: loadListPageUiTask, transponder: transponder))
    }

    /// 配置一个MJRefresh的普通任务下拉刷新
    public static func configLoadDataRefresh(tableView: UITableView, onRefreshSuccessListener: ((MJRefresher) -> Void)?) -> MJRefresher {
        return MJRefresher(tableView: tableView, onRefreshSuccessListener: onRefreshSuccessListener).buildLoadDataRefresher();
    }

    /// 配置一个MJRefresh的分页任务下拉刷新
    public static func configLoadListPageRefresh(tableView: UITableView, onRefreshSuccessListener: ((MJRefresher) -> Void)?) -> MJRefresher {
        return MJRefresher(tableView: tableView, onRefreshSuccessListener: onRefreshSuccessListener).buildLoadListPageRefresher();
    }

    /// 配置一个MJRefresh的上拉加载
    public static func configLoadListPageLoader(tableView: UITableView, onLoadSuccessListener: ((MJLoader) -> Void)?) -> MJLoader {
        return MJLoader(tableView: tableView, onLoadSuccessListener: onLoadSuccessListener)
    }

    /// 获取一个未来数据对象
    public static func fultureData<T>(onLoadData: ((Fulture<T>) -> Void)?) -> Fulture<T> {
        return Fulture().load(onLoadData: onLoadData)
    }
}

import SnapKit

extension UIView {
    /// 用于动态获取当前View关联的nib文件的名字
    @objc open func getLinkedNibFileName() -> String {
        return NSStringFromClass(type(of: self)).components(separatedBy: ".").last!
    }
}

import Toast_Swift

public class UiUtils {

    /// 显示吐司：支持View和常规对象
    /// 如果是View则以View原本的样式显示
    /// 如果是常规对象则以toString的样式显示
    public static func show(message: Any) {
        let currentView = currentViewController()?.view
        if (message is UIView) {
            (message as! UIView).removeFromSuperview()
            currentView?.showToast(message as! UIView)
        } else {
            currentView?.makeToast((message as! String))
        }
    }

    /// 将一个View填充到容器中，该容器中只会有一个View
    public static func displayViewOnContainer(view: UIView, container: UIView) {
        container.subviews.forEach { view in view.removeFromSuperview() }
        container.addSubview(view)
        view.snp.remakeConstraints { maker in
            maker.size.equalTo(container)
        }
    }

    /// 将和该View关联的Nib填充到该View中
    public static func inflateNibToUIView(uiView: UIView) {
        // 获取View类名对应的Nib文件View
        let nib = UINib(nibName: uiView.getLinkedNibFileName(), bundle: Bundle(for: type(of: uiView)))
        let nibView = nib.instantiate(withOwner: uiView, options: nil).first as! UIView
        // 填充到容器中
        uiView.addSubview(nibView)
        nibView.snp.makeConstraints { maker in
            maker.size.equalTo(uiView)
        }
    }

    /// 获取当前课件的视图控制器，该方法必须在控制器课件时才能获取。如果在应用刚启动的时候是无法获取的
    public static func currentViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return currentViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            return currentViewController(base: tab.selectedViewController)
        }
        if let presented = base?.presentedViewController {
            return currentViewController(base: presented)
        }
        return base
    }

    /// 根据View获取该View所属的ViewController
    /// - view      用于搜索的View
    /// - type      用于搜索的ViewController类型
    public static func findViewControllerByView<T: UIViewController>(view: UIView, type: T.Type) -> T? {
        var next = view.next
        while (next != nil) {
            if (next is T) {
                return next as? T
            }
            next = next?.next
        }
        return nil
    }

    /// 根据StoryBoard的名字获取对应的控制器
    /// -name           StoryBoard文件的名字
    /// -identifier     控制器的唯一标识
    /// -type           控制器的类型
    public static func createViewControllerByStoryBoardForMain(name: String, identifier: String?) -> UIViewController {
        return createViewControllerByStoryBoard(name: name, identifier: identifier, bundle: nil)
    }

    /// 根据StoryBoard的名字获取对应的控制器（当前Framework使用）
    /// -name           StoryBoard文件的名字
    /// -identifier     控制器的唯一标识
    /// -type           控制器的类型
    static func createViewControllerByStoryBoardForFramework(name: String, identifier: String?) -> UIViewController {
        return createViewControllerByStoryBoard(name: name, identifier: identifier, bundle: Bundle(identifier: Environment.BUNDLE_ID))
    }

    /// 根据StoryBoard的名字获取对应的控制器
    /// -name           StoryBoard文件的名字
    /// -identifier     控制器的唯一标识
    /// -bundle         用于搜索资源的Bundle
    /// -type           控制器的类型
    private static func createViewControllerByStoryBoard(name: String, identifier: String?, bundle: Bundle?) -> UIViewController {
        let storyBoard = UIStoryboard(name: name, bundle: bundle)
        if (identifier == nil) {
            return storyBoard.instantiateInitialViewController()!
        } else {
            return storyBoard.instantiateViewController(withIdentifier: identifier!)
        }
    }
}

/// File工具类
public class FileUtils {
    /// 删除文件或者文件夹
    public static func delete(directory: String, keepRoot: Bool = true) {
        let enumerator = FileManager.default.enumerator(atPath: directory)!
        while let element = enumerator.nextObject() as? String {
            try! FileManager.default.removeItem(atPath: element)
        }
        if (!keepRoot) {
            try! FileManager.default.removeItem(atPath: directory)
        }
    }
}

import HandyJSON

public protocol ICache {
    func isCached<T: HandyJSON>(clazz: T.Type) -> Bool
    func cache<T: HandyJSON>(object: T) -> T
    func getCache<T: HandyJSON>(clazz: T.Type) -> T?
    func deleteCache(clazz: AnyClass)
    func deleteAllCache()
}

public class MemoryCache: ICache {
    private var objectDirectory: [String: AnyObject] = [:]

    public func isCached<T: HandyJSON>(clazz: T.Type) -> Bool {
        return objectDirectory[NSStringFromClass(clazz as! AnyClass)] != nil
    }

    public func cache<T: HandyJSON>(object: T) -> T {
        objectDirectory[NSStringFromClass(type(of: object) as! AnyClass)] = object as AnyObject
        return object
    }

    public func getCache<T: HandyJSON>(clazz: T.Type) -> T? {
        return objectDirectory[NSStringFromClass(clazz as! AnyClass)] as? T
    }

    public func deleteCache(clazz: AnyClass) {
        objectDirectory.removeValue(forKey: NSStringFromClass(clazz))
    }

    public func deleteAllCache() {
        objectDirectory.removeAll()
    }
}

public class DiskCache: ICache {

    public func isCached<T: HandyJSON>(clazz: T.Type) -> Bool {
        return getCache(clazz: clazz) != nil
    }

    public func cache<T: HandyJSON>(object: T) -> T {
        cacheInner(object: object, haveTryed: false)
        return object
    }

    public func getCache<T: HandyJSON>(clazz: T.Type) -> T? {
        return getCacheInner(clazz: clazz)
    }

    public func deleteCache(clazz: AnyClass) {
        let cacheFile = CacheConfig.getLocalEntityCacheDir() + "/" + NSStringFromClass(clazz)
        try! FileManager.default.removeItem(atPath: cacheFile)
    }

    public func deleteAllCache() {
        FileUtils.delete(directory: CacheConfig.getLocalEntityCacheDir())
    }
    
    private func cacheInner<T: HandyJSON>(object: T, haveTryed: Bool) {
        let cacheFile = CacheConfig.getLocalEntityCacheDir() + "/" + NSStringFromClass(type(of: object) as! AnyClass)
        do {
            let content = object.toJSONString()!
            if (!FileManager.default.createFile(atPath: cacheFile, contents: content.data(using: String.Encoding.utf8)!)) {
                throw NSError(domain: "文件创建失败", code: Environment.CODE_CREATE_FILE_FAIL)
            }
        } catch {
            print(error)
            deleteCache(clazz: type(of: object) as! AnyClass)
            cacheInner(object: object, haveTryed: true)
        }
    }
    
    private func getCacheInner<T: HandyJSON>(clazz: T.Type) -> T? {
        let cacheFile = CacheConfig.getLocalEntityCacheDir() + "/" + NSStringFromClass(clazz as! AnyClass)
        if (FileManager.default.fileExists(atPath: cacheFile)) {
            do {
                if let readHandler = FileHandle(forReadingAtPath: cacheFile) {
                    let content = String(data: readHandler.readDataToEndOfFile(), encoding: String.Encoding.utf8)
                    return clazz.deserialize(from: content)!
                } else {
                    throw NSError(domain: "实体解析失败", code: Environment.CODE_DESERIALIZE_JSON_FAIL)
                }
            } catch {
                print(error)
                deleteCache(clazz: clazz as! AnyClass)
                return nil
            }
        } else {
            return nil
        }
    }
}

public class MemoryDiskCache: ICache {
    private let memoryCache: ICache
    private let diskCache: ICache

    public init(memoryCache: ICache, diskCache: ICache) {
        self.memoryCache = memoryCache
        self.diskCache = diskCache
    }

    public func isCached<T: HandyJSON>(clazz: T.Type) -> Bool {
        return memoryCache.isCached(clazz: clazz) || diskCache.isCached(clazz: clazz)
    }

    public func cache<T: HandyJSON>(object: T) -> T {
        memoryCache.cache(object: object)
        diskCache.cache(object: object)
        return object
    }

    public func getCache<T: HandyJSON>(clazz: T.Type) -> T? {
        if (memoryCache.isCached(clazz: clazz)) {
            return memoryCache.getCache(clazz: clazz)
        } else {
            let object = diskCache.getCache(clazz: clazz)
            if (object != nil) {
                memoryCache.cache(object: object!)
            }
            return object
        }
    }

    public func deleteCache(clazz: AnyClass) {
        memoryCache.deleteCache(clazz: clazz)
        diskCache.deleteCache(clazz: clazz)
    }

    public func deleteAllCache() {
        memoryCache.deleteAllCache()
        diskCache.deleteAllCache()
    }
}

/// 缓存工具类
/// 默认使用的内存硬盘双重缓存
public class CacheUtils {
    public static let defaultMemoryCache = MemoryCache()        /// 获取默认的内存缓存
    public static let defaultDiskCache = DiskCache()            /// 获取默认的硬盘缓存
    public static let defaultMemoryDiskCache = MemoryDiskCache(memoryCache: defaultMemoryCache, diskCache: defaultDiskCache)        /// 获取内存硬盘双重缓存

    /// 判断一个对象是否被缓存了
    public static func isCached<T: HandyJSON>(clazz: T.Type) -> Bool {
        return defaultMemoryDiskCache.isCached(clazz: clazz)
    }

    /// 缓存一个对象
    public static func cache<T: HandyJSON>(object: T) -> T {
        return defaultMemoryDiskCache.cache(object: object)
    }

    /// 取出一个缓存对象
    public static func getCache<T: HandyJSON>(clazz: T.Type) -> T? {
        return defaultMemoryDiskCache.getCache(clazz: clazz)
    }

    /// 删除缓存对象
    public static func deleteCache(clazz: AnyClass) {
        defaultMemoryDiskCache.deleteCache(clazz: clazz)
    }

    /// 删除所有缓存对象
    public static func deleteAllCache() {
        defaultMemoryDiskCache.deleteAllCache()
    }
}