//
//  RemoteBase.swift
//  KiteRemote
//
//  Created by Andreas Okholm on 08/07/16.
//  Copyright © 2016 Andreas Okholm. All rights reserved.
//

import Foundation
import Starscream


class RemoteBase { // FIXME: added reconnect behaviour
    
    let socket = WebSocket(url: NSURL(string: "ws://192.168.4.1:81/")!)
    
    var lastTime = NSDate()
    var t: NSTimer!
    
    init() {
        
        socket.onText = { (text: String) in
            print("got some text: \(text)")
        }
        
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
    
    func connect() {
        t = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: #selector(self.checkConnection), userInfo: nil, repeats: true)
    }
    
    func newPos(pos: Int) {
        if (lastTime.timeIntervalSinceNow < -0.05) {
            
            if socket.isConnected {
                socket.writeString(String(pos))
            }
            
            lastTime = NSDate()
        }
    }
    
    @objc func checkConnection() {
        if !socket.isConnected {
            socket.connect()
        }
    }
}