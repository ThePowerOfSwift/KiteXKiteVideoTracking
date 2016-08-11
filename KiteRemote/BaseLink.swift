//
//  RemoteBase.swift
//  KiteRemote
//
//  Created by Andreas Okholm on 08/07/16.
//  Copyright © 2016 Andreas Okholm. All rights reserved.
//

import Foundation
import Starscream


enum BaseLinkType: String {
    case Camera = "Camera"
    case Control = "Control"
}

class BaseLink { // FIXME: added reconnect behavior
    
    let socket = WebSocket(url: NSURL(string: "ws://192.168.2.1:8080/")!)
    var stateChangeIsConnected: (Bool -> Void)?
    
    private let minDelay = 0.02 // second
    private var lastTime = NSDate()
    //private var onData: (Int16 -> Void)?
    
    init(type: BaseLinkType) {
        
        socket.onConnect = {
            self.socket.writeString("id.\(type.rawValue)")
            if let didConnect = self.stateChangeIsConnected {
                didConnect(true)
            }
            
        }

        socket.onDisconnect = { (err: NSError?) in
            if let err = err {
                print(err)
            } else {
                print("disconnected without error")
            }
            if let stateChangeIsConnected = self.stateChangeIsConnected {
                stateChangeIsConnected(false)
            }
        }
        
        
        socket.onText = { (text: String) in
            print("got some text: \(text)")
        }
        
        socket.onData = { (data: NSData) in
            // not in use
//            if let onData = self.onData {
//                var numbers = [Int16](count: 1, repeatedValue: 0)
//                data.getBytes(&numbers, length: 2)
//                onData(numbers[0])
//            }
        }
    }
    
    func sendData(data: NSData) {
        if lastTime.timeIntervalSinceNow <= -minDelay && socket.isConnected {
            socket.writeData(data)
        }
    }
}