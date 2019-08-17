//
//  Main.swift
//  App
//
//  Created by 123 on 2019/8/8.
//  Copyright © 2019 SparkUlfy. All rights reserved.
//

import UIKit
import UlfyIOS
import Alamofire
import HandyJSON

import Toast_Swift

class ViewController: UIViewController {

    class BasicTypes: HandyJSON {
        var int: Int!
        required init() {}
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func clickContentDataBT(_ sender: Any) {
        self.present(ContentDataController(), animated: true, completion: nil)
    }

    @IBAction func clickTableViewBT(_ sender: Any) {
        self.present(TestListDataController(), animated: true, completion: nil)
    }

}

