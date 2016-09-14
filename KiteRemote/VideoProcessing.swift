//
//  VideoProcessing.swift
//  KiteRemote
//
//  Created by Andreas Okholm on 08/07/16.
//  Copyright © 2016 Andreas Okholm. All rights reserved.
//

import Foundation
import GPUImage
import AVFoundation
import Accelerate

class VideoProcessing {
    
    fileprivate let camera: Camera?
    fileprivate let size = Size(width: 480, height: 640)
    fileprivate let movieInput: MovieInput?
    
    fileprivate let crosshairGenerator: CrosshairGenerator!
    fileprivate let renderView: RenderView!
    
    fileprivate let blend = AlphaBlend()
    
    fileprivate let pathPosition = Bundle.main.path(forResource: "PositionColor", ofType: "fsh")!
    fileprivate let pathColor = Bundle.main.path(forResource: "ThresholdShader", ofType: "fsh")!
    fileprivate let highPassTrueColorFilter = HighPassTrueColorFilter()
    fileprivate let kiteColorFilter = KiteColorFilter()!
    
    fileprivate let positionOut = RawDataOutput()

    fileprivate let moviePosition = Bundle.main.path(forResource: "IMG_0459", ofType: "MOV")!
    
    fileprivate let pictureOutput = PictureOutput()
    
    var pictureOutBlock: ((Data) -> Void)?
    
    var newPosition: ((CGPoint, Double) -> Void)?
    
    init(renderView: RenderView, video: Bool) {

        self.renderView = renderView
        renderView.orientation = .landscapeRight
        
        crosshairGenerator = CrosshairGenerator(size: size)
        crosshairGenerator.crosshairWidth = 15
        
        do {
            if video {
                movieInput = try MovieInput(url: NSURL(fileURLWithPath: moviePosition) as URL, playAtActualSpeed: true, loop: true)
                camera = nil
                renderView.orientation = .portrait
            }
            else {
                camera = try Camera(sessionPreset:AVCaptureSessionPreset640x480)
                movieInput = nil
                renderView.orientation = .landscapeRight
            }
            
        } catch {
            fatalError("Could not initialize rendering pipeline: \(error)")
        }
        
        positionOut.dataAvailableCallback = {
            (imageBuffer: [UInt8]) in
            
            let boxSize = 80
            let Nwidth = self.size.w/boxSize
            let Nheight = self.size.h/boxSize
            
            var sumAlphas: [Int] = Array(repeating: 0, count: self.size.N)
            var sumIndex = 0
            
            var sumAlphaMax = 0
            var maxIndexI = 0
            var maxIndexJ = 0
            
            // buffer layout is from lower left corner, y first, then x
            for i in 0..<Nwidth { // cycle left to right (in own coordinate space)
                for j in 0..<Nheight { // bottom to top
                    var boxIndex = (j * boxSize * self.size.w + i * boxSize) * 4
                    
                    for _ in 0..<boxSize {
                        for _ in 0..<boxSize {
                            sumAlphas[sumIndex] += Int(imageBuffer[boxIndex + 3])
                            boxIndex += 4
                        }
                        
                        boxIndex += (self.size.w - boxSize) * 4
                    }
                    
                    if (sumAlphas[sumIndex] > sumAlphaMax) {
                        sumAlphaMax = sumAlphas[sumIndex]
                        maxIndexI = i
                        maxIndexJ = j
                    }
                    
                    sumIndex += 1
                }
            }
            
            // lets investigate the 3x3 box sourounding the box with most activity
            maxIndexI = max( min(maxIndexI,Nwidth-2), 1) - 1
            maxIndexJ = max( min(maxIndexJ,Nheight-2), 1) - 1
            

            var boxIndex = (maxIndexJ * boxSize * self.size.w + maxIndexI * boxSize) * 4
            let bigBoxSize = boxSize * 3
            
            var sAlpha: Int = 0
            var sRed: Int = 0
            var sGreen: Int = 0
            
            for _ in 0..<bigBoxSize {
                for _ in 0..<bigBoxSize {
                    sRed += Int(imageBuffer[boxIndex])
                    sGreen += Int(imageBuffer[boxIndex + 1])
                    sAlpha += Int(imageBuffer[boxIndex + 3])
                    boxIndex += 4
                }
                
                boxIndex += (self.size.w - bigBoxSize) * 4
            }
            
            let x = Double(sRed)/Double(sAlpha)
            let y = Double(sGreen)/Double(sAlpha)
            
            // more than 10 pixels
            if let newPosition = self.newPosition , !x.isNaN && sAlpha > 10*255 {
                
                self.crosshairGenerator.renderCrosshairs([Position(Float(x),Float(y))])
                
                let time = NSDate.timeIntervalSinceReferenceDate
                
                
                DispatchQueue.main.async {
                    newPosition( CGPoint(x: y, y: x),  time) // transpose

                }
            }
            
            
        }
        
        if let camera = camera {
            camera --> highPassTrueColorFilter --> kiteColorFilter --> positionOut
            camera --> blend
            camera --> pictureOutput
        }

//        if let movieInput = movieInput {
//            movieInput --> rawOut
//            movieInput --> colorFilter
//            movieInput --> positionFilter --> positionOut
//        }
        
        crosshairGenerator --> blend --> renderView
        pictureOutput.onlyCaptureNextFrame = true
        
    }
    
    func start() {
        if let movieInput = movieInput {
            movieInput.start()
        }
        
        if let camera = camera {
            camera.startCapture()
        }
    }
    
    func stop() {

        if let movieInput = movieInput {
            movieInput.cancel()
        }
        
        if let camera = camera {
            camera.stopCapture()
        }

    }
    
    func saveImage() {
                
        pictureOutput.imageAvailableCallback = {image in
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        }
        
        if let pictureOutBlock = pictureOutBlock {
            pictureOutput.encodedImageFormat = .png
            pictureOutput.encodedImageAvailableCallback = { data in
                DispatchQueue.main.async(execute: {
                    pictureOutBlock(data)
                })

            }
        }
    }
}
