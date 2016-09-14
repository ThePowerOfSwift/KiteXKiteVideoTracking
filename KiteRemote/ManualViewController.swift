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
    
    let baseLink = BaseLink(type: .Control)
    
    var count: Int64 = 0
    
    var colorThreshold: Float = 0.5
    var controlAmplitude: Double = 300 // +- 300 mm from
    var controlOffSet = 0
    var controlInput: Int = 0 {
        didSet {
            let pos = Int16( controlInput + controlOffSet )
            baseLink.sendData(Data(bytes: UnsafeRawPointer(Array(repeating: pos, count: 1)), count: 2))
        }
    }
    
    @IBOutlet weak var controlView: ControlView!
    @IBOutlet weak var controlSlider: UISlider!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        controlView.baseLink = baseLink
        controlView.nextVC = {
            if let pagevc = self.parent as? KiteRemotePageViewController {
                pagevc.next(self)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func zero(_ sender: UIButton) {
        controlOffSet += controlInput
        controlSlider.value = 0.5
    }
    
    @IBAction func newSliderValue(_ sender: UISlider) {
        controlInput = Int( Double(sender.value - 0.5) * 2 * 400/40 * controlAmplitude ) // 200 steps per rev, each rev = 80 mm
    }
    
    @IBAction func newAmplitudeSliderValue(_ sender: UISlider) {
        controlAmplitude = Double(sender.value) * 600 //
    }
}

