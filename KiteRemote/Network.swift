//
//  Network.swift
//  KiteRemote
//
//  Created by Andreas Okholm on 21/07/16.
//  Copyright © 2016 Andreas Okholm. All rights reserved.
//

import Foundation

class Network {
    
    
    func sendData(json: AnyObject) {
        
        let request = NSMutableURLRequest(URL: NSURL(string: "https://project-5747199377705571541.firebaseio.com/video.json")!)
        let data = try! NSJSONSerialization.dataWithJSONObject(json, options: [])

        request.HTTPMethod = "POST"
        
        
        let task = NSURLSession.sharedSession().uploadTaskWithRequest(request, fromData: data) {
            (data, response, error) in
            
            if let error = error {
                print(error)
            }
            
            if let data = data {
                print(NSString(data: data, encoding: NSUTF8StringEncoding))
            }
            
        }
        
        task.resume()
        
        
        
        
        
//        let urlPath: String = "https://project-5747199377705571541.firebaseio.com/"
//        let url: NSURL = NSURL(string: urlPath)!
//        let request1: NSMutableURLRequest = NSMutableURLRequest(URL: url)
//        
//        request1.HTTPMethod = "POST"
//        let stringPost="deviceToken=123456" // Key and Value
//        
//        let data = stringPost.dataUsingEncoding(NSUTF8StringEncoding)
//        
//        request1.timeoutInterval = 60
//        request1.HTTPBody=data
//        request1.HTTPShouldHandleCookies=false
//        
//        let queue:NSOperationQueue = NSOperationQueue()
//        
//        NSURLConnection.sendAsynchronousRequest(request1, queue: queue, completionHandler:{ (response: NSURLResponse?, data: NSData?, error: NSError?) -> Void in
//            
//            do {
//                if let jsonResult = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? NSDictionary {
//                    print("ASynchronous\(jsonResult)")
//                }
//            } catch let error as NSError {
//                print(error.localizedDescription)
//            }
//            
//            
//        })
        
        
        
    }
}