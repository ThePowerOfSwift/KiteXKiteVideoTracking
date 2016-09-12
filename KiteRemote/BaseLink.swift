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
    
    let socket = WebSocket(url: NSURL(string: "ws://192.168.2.1:8080/")!)
    var stateChangeIsConnected: (Bool -> Void)?
    var trackingState: (Bool -> Void)?
    var captureImage: (Void -> Void)?
    
    private let minDelay = 0.02 // second
    private var lastTime = NSDate()
    var batteryTimer: NSTimer!
    
    init(type: BaseLinkType) {
        
        socket.onConnect = {
            self.socket.writeString("id,\(type.rawValue)")
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
            
            
            let a = text.componentsSeparatedByString(",")
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
    
    func startTimer() {
        batteryTimer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: #selector(BaseLink.updatebatteryInfo), userInfo: nil, repeats: true)
    }
    
    @objc func updatebatteryInfo() {
        UIDevice.currentDevice().batteryMonitoringEnabled = true
        socket.writeString("phoneBat," + String(UIDevice.currentDevice().batteryLevel))
    }
}