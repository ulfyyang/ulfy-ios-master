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

public class DialogUtils {
    public static let ULFY_MAIN_DIALOG_ID = "__ULFY_MAIN_DIALOG_ID__"

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
    
}

import SnapKit

extension UIView {
    /// 用于动态获取当前View关联的nib文件的名字
    @objc open func getLinkedNibFileName() -> String {
        return NSStringFromClass(type(of: self)).components(separatedBy: ".").last!
    }
}

public class UiUtils {

    /// 显示吐司：支持View和常规对象
    /// 如果是View则以View原本的样式显示
    /// 如果是常规对象则以toString的样式显示
    public static func show(message: Any) {
        print(message)
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
        return createViewControllerByStoryBoard(name: name, identifier: identifier, bundle: Bundle(identifier: Envirnment.BUNDLE_ID))
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
