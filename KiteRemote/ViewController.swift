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

class ViewController: UIViewController {
    
    let remote = RemoteBase()
    var videoProcessing: VideoProcessing!

    var colorThreshold: Float = 0.5

    @IBOutlet weak var colorView: UIView!
    
    @IBOutlet weak var renderView: RenderView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        videoProcessing = VideoProcessing(renderView: renderView)
        
        let tabGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        renderView.addGestureRecognizer(tabGesture)
        let slideGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan(_:)))
        renderView.addGestureRecognizer(slideGesture)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func newSliderValue(sender: UISlider) {
        remote.newPos( Int( (sender.value - 0.5) * 1600*10 ) )
    }
    
    
    func handleTap(sender: UITapGestureRecognizer) {
        
        if sender.state == .Ended {
            let touchPoint = sender.locationOfTouch(0, inView: renderView)
            
            let normalizedPoint = CGPoint(x: touchPoint.x / renderView.frame.size.width, y: touchPoint.y / renderView.frame.size.height)
            
            videoProcessing.getColorForPoint(normalizedPoint) {
                color in
                print(color)
                self.colorView.backgroundColor = UIColor(CIColor: color)
                self.videoProcessing.setColor(color)
            }
            
//            let tpVideo = CGPoint(
//                x: round( touchPoint.x / renderView.frame.size.width * videoSize.width ),
//                y: round( videoSize.height - touchPoint.y / renderView.frame.size.height * videoSize.height ) )
//            
//            let c = rawOut.colorAtLocation(tpVideo)
//            func norm(val: GLubyte) -> Float {
//                return Float(val)/255
//            }
//            let color = UIColor(colorLiteralRed: norm(c.red), green: norm(c.green), blue: norm(c.blue), alpha: norm(c.alpha))
//            colorView.backgroundColor = color
//            
//            var thresholdColor = GPUVector3() // thresholdColor
//            thresholdColor.one = norm(c.red)
//            thresholdColor.two = norm(c.green)
//            thresholdColor.three = norm(c.blue)
//            
//            colorFilter.setFloatVec3(thresholdColor, forUniformName: "inputColor")
//            positionColorFilter.setFloatVec3(thresholdColor, forUniformName: "inputColor")
        }
    }
    
    
    func handlePan(sender: UIPanGestureRecognizer) {
        let change = Float(sender.translationInView(renderView).x/100)
        
        if sender.state == .Changed {
            videoProcessing.setThreshold(colorThreshold+change)
        }
        
        if sender.state == .Ended {
            colorThreshold = colorThreshold+change
            videoProcessing.setThreshold(colorThreshold)
        }
    }


}

