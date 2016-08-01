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
    
    var onData: (Int16 -> Void)?
    var didConnect: (Bool -> Void)?
    
    
    init() {
        
        socket.onData = { (data: NSData) in
            
            if let onData = self.onData {
                var numbers = [Int16](count: 1, repeatedValue: 0)
                data.getBytes(&numbers, length: 2)
                onData(numbers[0])
            }
        }
        
        socket.onText = { (text: String) in
            print("got some text: \(text)")
        }
        
        socket.onConnect = {
            print("connected woho!")
            self.socket.writeString("T")
            if let didConnect = self.didConnect {
                didConnect(true)
            }
            
        }
        socket.onDisconnect = { (err: NSError?) in
            if let err = err {
                print(err)
            } else {
                print("disconnected without error")
            }
            if let didConnect = self.didConnect {
                didConnect(false)
            }
        }
    }
    
    func connect() {
        t = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: #selector(self.checkConnection), userInfo: nil, repeats: true)
    }
    
    func newPos(pos: Int) {
        if (lastTime.timeIntervalSinceNow < -0.01) {
            
            if socket.isConnected {
                socket.writeString(String(pos))
            }
            
            lastTime = NSDate()
        }
    }
    
    func sendData(data: NSData) {
        if socket.isConnected {
            socket.writeData(data)
        }
    }
    
    @objc func checkConnection() {
        if !socket.isConnected {
            socket.connect()
        }
    }
}