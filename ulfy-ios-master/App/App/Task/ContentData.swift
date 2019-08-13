//
//  ContentData.swift
//  App
//
//  Created by 123 on 2019/8/9.
//  Copyright © 2019 SparkUlfy. All rights reserved.
//

import UIKit
import UlfyIOS
import Alamofire

class ContentDataLoadView: UIView, IView {
    var contentLB: UILabel?
    var vm: ContentDataVM?

    init() {
        super.init(frame: CGRect.zero)
        layoutContainerUI(parent: self)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(model: IViewModel) {
        vm = (model as! ContentDataVM)
        contentLB?.text = vm?.content
    }

    /// 控件容器
    func layoutContainerUI(parent: UIView) {
        // ------------- 控件容器 -------------
        let container = UIView()
        parent.addSubview(container)

        // 控件容器属性
        container.backgroundColor = UIColor.red

        // 控件容器约束
        container.snp.makeConstraints { (make) in
            make.center.equalTo(parent)
            make.size.equalTo(parent)
        }

        // ------------- 标签 -------------
        let label = UILabel()
        container.addSubview(label)
        self.contentLB = label

        // 标签属性
        label.backgroundColor = UIColor.yellow
        label.numberOfLines = 0
        label.text = "测试文本"

        // 标签文字约束
        label.snp.makeConstraints { make in
            make.centerX.centerY.equalTo(parent)
        }
    }
}

class ContentDataVM: IViewModel {
    var content = "你好，我是内容"

    func loadData() -> (LoadDataUiTask) -> Void {
        return provideExecuteBody { task in
            task.notifyStart(tipData: "加载中...")
            Alamofire.request("https://httpbin.org/get").responseJSON { response in
                print(response.request as Any)  // 原始的URL请求
                print(response.response as Any) // HTTP URL响应
                print(response.data as Any)     // 服务器返回的数据
                print(response.result as Any)   // 响应序列化结果，在这个闭包里，存储的是JSON数据

                if let JSON = response.result.value {
                    print("JSON: \(JSON)")
                }
                
                sleep(2)
                
                self.content = "网络加载的内容"
                task.notifySuccess(tipData: "加载结束..." as AnyObject)
            }
        }
    }

    func provideExecuteBody(executeBody: @escaping (LoadDataUiTask) -> Void) -> (LoadDataUiTask) -> Void {
        return executeBody
    }

    func getGetViewType() -> UIView.Type {
        return ContentDataLoadView.self
    }
}
