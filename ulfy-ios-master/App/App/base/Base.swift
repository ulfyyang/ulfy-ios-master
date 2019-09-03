//
// Created by 123 on 2019-08-14.
// Copyright (c) 2019 SparkUlfy. All rights reserved.
//

import UIKit
import UlfyIOS

class BaseController: UlfyBaseController { }

class BaseView: UlfyBaseNibView { }

class BaseVM: UlfyBaseVM { }

class BaseCell: UlfyBaseNibCell { }

class BaseCM: UlfyBaseVM { }

import SnapKit

class TitleContentController: BaseController {
    var contentV: UIView?                       // 内容显示的容器
    var navigationBarHidden: Bool = false {     // 是否显示标题栏
        didSet {
            self.navigationController?.setNavigationBarHidden(navigationBarHidden, animated: true)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // 创建显示内容的容器
        let box: UIView = UIView()
        box.backgroundColor = UIColor.white
        self.view.addSubview(box)
        box.snp.makeConstraints { maker in
            maker.size.equalToSuperview()
        }
        self.contentV = box
        // 标题栏设置
        self.navigationController?.navigationBar.barTintColor = UIColor.white       // 设置背景色
        self.navigationController?.navigationBar.tintColor = UIColor.black          // 设置返回箭头和文字的颜色
        self.navigationController?.navigationBar.topItem?.title = ""                // 设置返回按钮文字，如果在根控制器因为没有返回按钮会设置到标题上
//        self.navigationController?.navigationBar.clipsToBounds = true             // 隐藏底部的线条（该方法会导致状态栏为默认色，即自定义颜色失效，不建议使用）
        self.navigationController?.navigationBar.shadowImage = UIImage()            // 隐藏底部的线条（通过替换系统自带的阴影实现，最好同时指定一下背景色），可以通过该方法设置底部线条颜色
//        self.navigationItem.titleView = UISegmentedControl()                      // 自定义中间显示的View
        self.navigationItem.title = "标题"                                          // 设置标题（该方法最好放到最后一行，和返回按钮文字会相互覆盖）
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if (navigationBarHidden) {
            self.navigationController?.setNavigationBarHidden(true, animated: true)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if (navigationBarHidden) {
            self.navigationController?.setNavigationBarHidden(false, animated: true)
        }
    }
}