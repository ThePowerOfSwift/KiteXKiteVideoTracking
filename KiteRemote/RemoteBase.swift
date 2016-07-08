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
    
    init() {
        
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
    
    func newPos(pos: Int) {
        if (lastTime.timeIntervalSinceNow < -0.05) {
            
            if socket.isConnected {
                socket.writeString(String(pos))
            }
            
            lastTime = NSDate()
        }
    }
    

}