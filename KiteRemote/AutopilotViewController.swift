//
//  ViewController.swift
//  KiteRemote
//
//  Created by Andreas Okholm on 05/07/16.
//  Copyright © 2016 Andreas Okholm. All rights reserved.
//

import UIKit
import Starscream
import GPUImage
import AVFoundation

class AutopilotViewController: UIViewController {
    
    let network = Network()
    let baseLink = BaseLink(type: .Camera)
    let kite = Kite()
    var videoProcessing: VideoProcessing!

    var colorThreshold = NSUserDefaults.standardUserDefaults().floatForKey("colorThreshold")

    @IBOutlet weak var colorView: UIView!
    
    @IBOutlet weak var controlView: ControlView!
    @IBOutlet weak var renderView: RenderView!
    @IBOutlet weak var velocity: UILabel!
    @IBOutlet weak var angular: UILabel!
    @IBOutlet weak var threshold: UILabel!

//    var kiteKinematicss = [KiteKinematics]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        controlView.baseLink = baseLink
        controlView.next = {
            if let pagevc = self.parentViewController as? KiteRemotePageViewController {
                pagevc.next(self)
            }
        }
        
        
        // Do any additional setup after loading the view, typically from a nib.
        videoProcessing = VideoProcessing(renderView: renderView, video: false)
        videoProcessing.newPosition = { (position, time) in
            if let kiteKinematics = self.kite.newPosition(position, time: time) {
//                self.kiteKinematicss.append(kiteKinematics)
                self.velocity.text = String(format: "%.1f m/s", kiteKinematics.velocity.length)
                self.angular.text = String(format: "%.1f r/s", kiteKinematics.angularVelocity)
                
                self.baseLink.sendData(kiteKinematics.data)
            }
        }
        
        let tabGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        renderView.addGestureRecognizer(tabGesture)
        let slideGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan(_:)))
        renderView.addGestureRecognizer(slideGesture)
        
        let ud = NSUserDefaults.standardUserDefaults()
        
        let storedTrackingColor = CIColor(
            red: CGFloat(ud.doubleForKey("colorRed")),
            green: CGFloat(ud.doubleForKey("colorGreen")),
            blue: CGFloat(ud.doubleForKey("colorBlue")))
        
        setTrackingColor(storedTrackingColor)
        setTrackingThreshold(colorThreshold)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func switchStateChanged(sender: UISwitch) {
        if sender.on {
            videoProcessing.start()
        } else {
            videoProcessing.stop()
            
//            network.sendData( kiteKinematicss.map { $0.json } )
//            kiteKinematicss.removeAll()
        }
    }
    
    func handleTap(sender: UITapGestureRecognizer) {
        
        if sender.state == .Ended {
            let touchPoint = sender.locationOfTouch(0, inView: renderView)
            
            let normalizedPoint = CGPoint(x: touchPoint.x / renderView.frame.size.width, y: touchPoint.y / renderView.frame.size.height)
            
            videoProcessing.getColorForPoint(normalizedPoint) {
                color in
                self.setTrackingColor(color)
                NSUserDefaults.standardUserDefaults().setDouble(Double(color.red), forKey: "colorRed")
                NSUserDefaults.standardUserDefaults().setDouble(Double(color.green), forKey: "colorGreen")
                NSUserDefaults.standardUserDefaults().setDouble(Double(color.blue), forKey: "colorBlue")
            }
        }
    }
    
    func setTrackingColor(color: CIColor) {
        colorView.backgroundColor = UIColor(CIColor: color)
        videoProcessing.setColor(color)
    }
    
    func setTrackingThreshold(threshold: Float) {
        videoProcessing.setThreshold(threshold)
        self.threshold.text = String(format: "%.2f", threshold)
    }
    
    func handlePan(sender: UIPanGestureRecognizer) {
        let change = Float(sender.translationInView(renderView).x/100)
        
        if sender.state == .Changed {
            setTrackingThreshold(colorThreshold+change)
        }
        
        if sender.state == .Ended {
            colorThreshold = colorThreshold+change
            setTrackingThreshold(colorThreshold)
            NSUserDefaults.standardUserDefaults().setFloat(colorThreshold, forKey: "colorThreshold")
        }
    }
}

