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

class ViewController: UIViewController {
    @IBOutlet var contentCV: UIView!
    var vm: ContentDataVM = ContentDataVM()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        TaskUtils.loadData(executeBody: vm.loadData(), transponder: ContentDataLoader(container: contentCV, model: vm))
    }

}

