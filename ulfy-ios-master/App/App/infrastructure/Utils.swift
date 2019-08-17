//
// Created by 123 on 2019-08-16.
// Copyright (c) 2019 SparkUlfy. All rights reserved.
//

import Foundation
import UlfyIOS

class HttpUtils {

    static func getContentLoadDataFulture() -> Fulture<String> {
        return TaskUtils.fultureData { fulture in
            // 模拟网络异步调用
            DispatchQueue.global().async {
                sleep(2)
                if (false) {
                    fulture.error(error: NSError(domain: "加载失败", code: 100))
                } else {
                    fulture.success(data: "加载成功的数据")
                }
            }
        }
    }
    
    static func getTestListDataFulture(page: Int, pageSize: Int) -> Fulture<[String]> {
        return TaskUtils.fultureData { fulture in
            sleep(2)
            var contentArray: [String] = []
            for index in 1...pageSize {
                contentArray.append("当前页：\(page) 页大小：\(pageSize) 所在位置：\(index)")
            }
            fulture.success(data: contentArray)
        }
    }
    
}
