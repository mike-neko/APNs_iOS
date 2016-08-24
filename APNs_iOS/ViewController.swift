//
//  ViewController.swift
//  APNs_iOS
//
//  Created by M.Ike on 2016/08/24.
//  Copyright © 2016年 M.Ike. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    private var pushSender: PushSender? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        guard let url = NSBundle.mainBundle().URLForResource("apns", withExtension: "p12") else { return }
        pushSender = PushSender(development: true, p12URL: url, p12Passphrase: "0000")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func tapSend(sender: UIButton) {
        guard let apns = pushSender else { return }

        let deviceToken = "00fc13adff785122b4ad28809a3420982341241421348097878e577c991de8f0"
        let payload = "{\"aps\":{\"alert\":\"Hello!\"}}"
        
        apns.send(payload, deviceToken: deviceToken)
    }
}
