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
    
    let baseLink = BaseLink(type: .Camera)
    var videoProcessing: VideoProcessing!

    var colorThreshold = UserDefaults.standard.float(forKey: "colorThreshold")

    @IBOutlet weak var colorView: UIView!
    
    @IBOutlet weak var controlView: ControlView!
    @IBOutlet weak var renderView: RenderView!
    @IBOutlet weak var velocity: UILabel!
    @IBOutlet weak var angular: UILabel!
    @IBOutlet weak var threshold: UILabel!
    
    @IBOutlet weak var stateSwitch: UISwitch!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        controlView.baseLink = baseLink
        controlView.nextVC = {
            if let pagevc = self.parent as? KiteRemotePageViewController {
                pagevc.next(self)
            }
        }
        
        // Do any additional setup after loading the view, typically from a nib.
        videoProcessing = VideoProcessing(renderView: renderView, video: false)
        videoProcessing.newPosition = { (position, time) in
            
            var array = [Double](repeating: 0, count: 3)
            array[0] = time
            array[1] = Double(position.x)
            array[2] = (1 - Double(position.y)) * 3/4
            
            self.baseLink.sendData(Data(bytes: UnsafeRawPointer(array), count: 3 * MemoryLayout<Double>.size))
            
        }
        
        videoProcessing.pictureOutBlock = { data in
            self.baseLink.sendData(data)
        }
        
        baseLink.trackingState = { (state: Bool) in
            self.stateSwitch.isOn = state
            if state {
                self.videoProcessing.start()
            } else {
                self.videoProcessing.stop()
            }
        }
        baseLink.startTimer()
        
        
        baseLink.captureImage = {
            self.videoProcessing.saveImage()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func switchStateChanged(_ sender: UISwitch) {
        if sender.isOn {
            videoProcessing.start()
        } else {
            videoProcessing.stop()
        }
    }
}

