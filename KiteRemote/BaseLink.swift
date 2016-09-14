//
//  RemoteBase.swift
//  KiteRemote
//
//  Created by Andreas Okholm on 08/07/16.
//  Copyright © 2016 Andreas Okholm. All rights reserved.
//

import Foundation
import Starscream
import UIKit


enum BaseLinkType: String {
    case Camera = "Camera"
    case Control = "Control"
}

class BaseLink { // FIXME: added reconnect behavior
    
    let socket = WebSocket(url: URL(string: "ws://192.168.2.1:8080/")!)
    var stateChangeIsConnected: ((Bool) -> Void)?
    var trackingState: ((Bool) -> Void)?
    var captureImage: ((Void) -> Void)?
    
    var batteryTimer: Timer!
    
    init(type: BaseLinkType) {
        
        socket.onConnect = {
            self.socket.write(string: "id,\(type.rawValue)")
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
            
            
            let a = text.components(separatedBy: ",")
            let command = a[0]
            let value = a[1]
            
            switch command {
            case "camera":
                if let callback = self.trackingState {
                    switch value {
                    case "on":
                        callback(true)
                        break
                    case "off":
                        callback(false)
                        break
                    default: break
                    }
                }
                
                if let callback = self.captureImage {
                    if (value == "capture") {
                        callback()
                    }
                }
                
            default:
                print("got some text: \(text)")
            }
            
        }
        
        socket.onData = { (data: Data) in
            // not in use
        }
    }
    
    func sendData(_ data: Data) {
        if socket.isConnected {
            socket.write(data)
        }
    }
    
    func startTimer() {
        batteryTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(BaseLink.updatebatteryInfo), userInfo: nil, repeats: true)
    }
    
    @objc func updatebatteryInfo() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        socket.write(string:"phoneBat," + String(UIDevice.current.batteryLevel))
    }
}
