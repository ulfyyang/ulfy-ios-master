//
// Created by 123 on 2019-08-09.
// Copyright (c) 2019 SparkUlfy. All rights reserved.
//

import Foundation

public class TaskUtils {

    /// 执行一个记载数据的任务
    /// - executeBody           提供任务执行的具体过程
    /// - transponder           提供任务执行的响应器
    public static func loadData(executeBody: @escaping (LoadDataUiTask) -> Void, transponder: Transponder) {
        TaskExecutor.defaultExecutor.post(task: LoadDataUiTask(executeBody: executeBody, transponder: transponder))
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
