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

class ManualViewController: UIViewController {
    
    let remote = RemoteBase()
    
    var colorThreshold: Float = 0.5
    var controlAmplitude: Double = 300 // +- 300 mm from
    var controlOffSet = 0
    var controlInput: Int = 0 {
        didSet {
            remote.newPos( controlInput + controlOffSet)
        }
    }
    
    var val = Int16(0)
    
    var t: NSTimer?
    
    @IBOutlet weak var controlSlider: UISlider!
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var connectionStatusLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //remote.connect()
        remote.onData = {
            self.val = $0
            self.topLabel.text = "\(self.val)"
        }
        remote.didConnect = {
            self.connectionStatusLabel.text = $0 ? "Connected" : "Not Connected"
        }
        
        controlInput = 1000
        t = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(self.goTo), userInfo: nil, repeats: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func next(sender: UIButton) {
        if let pagevc = self.parentViewController as? KiteRemotePageViewController {
            pagevc.next(self)
        }
    }
    
    @IBAction func zero(sender: UIButton) {
        controlOffSet += controlInput
        controlSlider.value = 0.5
    }
    
    @IBAction func newSliderValue(sender: UISlider) {
        controlInput = Int( Double(sender.value - 0.5) * 2 * 400/40 * controlAmplitude ) // 200 steps per rev, each rev = 80 mm
    }
    
    @IBAction func newAmplitudeSliderValue(sender: UISlider) {
        controlAmplitude = Double(sender.value) * 600 //
    }
    
    func goTo() {
        remote.sendData(NSData(bytes: Array(count: 1, repeatedValue: self.val), length: 2))
        //controlInput = -controlInput;
    }
    
    @IBAction func plus1(sender: UIButton) {
        remote.sendData(NSData(bytes: Array(count: 1, repeatedValue: self.val), length: 2))
    }
    @IBAction func connect(sender: UIButton) {
        remote.connect()
    }
}

