//
//  ViewController.swift
//  KiteRemote
//
//  Created by Andreas Okholm on 05/07/16.
//  Copyright © 2016 Andreas Okholm. All rights reserved.
//

import UIKit
import Starscream

class ViewController: UIViewController {
    
    let socket = WebSocket(url: NSURL(string: "ws://192.168.4.1:81/")!)

    var lastTime = NSDate()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        //websocketDidReceiveMessage
        socket.onText = { (text: String) in
            print("got some text: \(text)")
        }
        
        
        socket.connect()
        socket.onConnect = {
            print("connected woho!")
        }
        socket.onDisconnect = { (err: NSError?) in
            if let err = err {
                print(err)
            } else {
                print("disconnected without error")
            }
            
        }

        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func newSliderValue(sender: UISlider) {
        newPos( Int( (sender.value - 0.5) * 1600*10 ) )
    }
    
    
    func newPos(pos: Int) {
        if (lastTime.timeIntervalSinceNow < -0.05) {
            
            if socket.isConnected {
                socket.writeString(String(pos))
            }
            
            lastTime = NSDate()
        }
    }


}

