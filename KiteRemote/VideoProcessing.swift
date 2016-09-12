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

extension Size {
    var transpose: Size { return Size(width: height, height: width) }
    
    var w: Int { return Int(width) }
    var h: Int { return Int(height) }
    var N: Int { return w*h }
}


public class DifferenceFilter: BasicOperation {
    public var threshold:Float = 0.0 { didSet { uniformSettings["threshold"] = threshold } }
    
    public init?() {
        let pathPosition = NSBundle.mainBundle().pathForResource("DifferenceThreshold", ofType: "fsh")!
        let url = NSURL(fileURLWithPath: pathPosition)
        
        do {3
            let fragmentShader = try NSString(contentsOfURL: url, encoding: NSUTF8StringEncoding) as String
            super.init(fragmentShader:fragmentShader, numberOfInputs:2)
        }
        catch {
            return nil
        }
        
        ({threshold = 0.1})()
    }
}

public class HighPassTrueColorFilter: OperationGroup {
    public var lowPassStrength: Float = 0.5 { didSet { lowPass.strength = lowPassStrength } }
    public var threshold: Float = 0.5 { didSet { differenceFilter.threshold = threshold } }
    
    let lowPass = LowPassFilter()
    let differenceFilter = DifferenceFilter()! // fail hard
    
    public override init() {
        super.init()
        
        ({lowPassStrength = 0.8
        threshold = 0.1})()
        
        self.configureGroup{input, output in
            input --> self.differenceFilter
            input --> self.lowPass --> self.differenceFilter --> output
        }
    }
}

public class KiteColorFilter: BasicOperation {
    public var red:Float = 0.0 { didSet { uniformSettings["red"] = red } }
    public var redGreen:Float = 0.0 { didSet { uniformSettings["redGreen"] = redGreen } }
    public var redBlue:Float = 0.0 { didSet { uniformSettings["redBlue"] = redBlue } }

    
    public init?() {
        let pathPosition = NSBundle.mainBundle().pathForResource("ColorTresholdShader", ofType: "fsh")!
        let url = NSURL(fileURLWithPath: pathPosition)
        
        do {
            let fragmentShader = try NSString(contentsOfURL: url, encoding: NSUTF8StringEncoding) as String
            super.init(fragmentShader:fragmentShader, numberOfInputs:1)
        }
        catch {
            return nil
        }
        
        ({
            red = 0.1
            redGreen = 1.1
            redBlue = 2.0
        })()
    }
}



class VideoProcessing {
    
    private let camera: Camera?
//    private let size = Size(width: 640, height: 480)
    private let size = Size(width: 480, height: 640)
    private let movieInput: MovieInput?
    
//    private let crosshairGenerator: CrosshairGenerator!
    private let renderView: RenderView!
    
//    private let blend = AlphaBlend()
    
    private let pathPosition = NSBundle.mainBundle().pathForResource("PositionColor", ofType: "fsh")!
    private let pathColor = NSBundle.mainBundle().pathForResource("ThresholdShader", ofType: "fsh")!
//    private let positionFilter: BasicOperation!
//    private let colorFilter: BasicOperation!
//    private let darkenBlend = DarkenBlend()
    private let highPassTrueColorFilter = HighPassTrueColorFilter()
    private let kiteColorFilter = KiteColorFilter()!
    
    
    
//    private let rawOut = RawDataOutput()
    private let positionOut = RawDataOutput()

    private let moviePosition = NSBundle.mainBundle().pathForResource("IMG_0459", ofType: "MOV")!
    
    private let pictureOutput = PictureOutput()
    
    var newPosition: ((CGPoint, Double) -> Void)?
    
    init(renderView: RenderView, video: Bool) {

        self.renderView = renderView
        renderView.orientation = .LandscapeRight
        
//        crosshairGenerator = CrosshairGenerator(size: size)
//        crosshairGenerator.crosshairWidth = 15
        
        do {
//            positionFilter = try BasicOperation(fragmentShaderFile: NSURL(fileURLWithPath: pathPosition))
//            colorFilter = try BasicOperation(fragmentShaderFile: NSURL(fileURLWithPath: pathColor))
            
            if video {
                movieInput = try MovieInput(url: NSURL(fileURLWithPath: moviePosition), playAtActualSpeed: true, loop: true)
                camera = nil
                renderView.orientation = .Portrait
            }
            else {
                camera = try Camera(sessionPreset:AVCaptureSessionPreset640x480)
                movieInput = nil
                renderView.orientation = .LandscapeRight

            }
            
        } catch {
            fatalError("Could not initialize rendering pipeline: \(error)")
        }
        
        positionOut.dataAvailableCallback = {
            (imageBuffer: [UInt8]) in
            
            let boxSize = 80
            let Nwidth = self.size.w/boxSize
            let Nheight = self.size.h/boxSize
            
            var sumAlphas: [Int] = Array(count: self.size.N, repeatedValue: 0)
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
            
            
//            var sumAlpha: Int = 0
//            var sumRed: Int = 0
//            var sumGreen: Int = 0
//            for i in 0..<self.size.N {
//                sumAlpha += Int(imageBuffer[4*i+3])
//                sumRed += Int(imageBuffer[4*i+0])
//                sumGreen += Int(imageBuffer[4*i+1])
//            }
//            
//            let x = Double(sumRed)/Double(sumAlpha)
//            let y = Double(sumGreen)/Double(sumAlpha)
//            let intensity = Float(sumAlpha)/Float(N)
            
//            print(sAlpha)
            
            
            // more than 4 pixels
            if let newPosition = self.newPosition where !x.isNaN && sAlpha > 10*255 {
                
                let time = NSDate.timeIntervalSinceReferenceDate()
                
                dispatch_async(dispatch_get_main_queue(),{
                    newPosition( CGPoint(x: y, y: x),  time) // transpose
                    
                })
                
            }
            
//            self.crosshairGenerator.renderCrosshairs([Position(Float(x),Float(y))])
        }
        
        
//        positionOut.dataAvailableCallback = {
//            (imageBuffer: [UInt8]) in
//            
//            let N = Int(self.size.height*self.size.width)
//            
//            var sumAlpha: Int = 0 // FIXME: Concider using accelerate for summation // function only exist for floats
//            var sumRed: Int = 0
//            var sumGreen: Int = 0
//            for i in 0..<N {
//                sumAlpha += Int(imageBuffer[4*i+3])
//                sumRed += Int(imageBuffer[4*i+0])
//                sumGreen += Int(imageBuffer[4*i+1])
//            }
//            
//            let x = Double(sumRed)/Double(sumAlpha)
//            let y = Double(sumGreen)/Double(sumAlpha)
//            //            let intensity = Float(sumAlpha)/Float(N)
//            
//            if let newPosition = self.newPosition where !x.isNaN {
//                
//                let time = NSDate.timeIntervalSinceReferenceDate()
//                
//                dispatch_async(dispatch_get_main_queue(),{
//                    newPosition( CGPoint(x: y, y: x),  time) // transpose
//                    
//                })
//                
//            }
//            
//            self.crosshairGenerator.renderCrosshairs([Position(Float(x),Float(y))])
//        }
        
        
        setColor(CIColor(red: 1.0, green: 0, blue: 0))
        setThreshold(0.2)
        
        
        if let camera = camera {
//            camera --> rawOut
//            camera --> colorFilter
//            camera --> positionFilter --> positionOut
//            camera --> highPassFilter --> blend
            camera --> highPassTrueColorFilter --> kiteColorFilter --> positionOut
            camera --> renderView
            camera --> pictureOutput
        }

//        if let movieInput = movieInput {
//            movieInput --> rawOut
//            movieInput --> colorFilter
//            movieInput --> positionFilter --> positionOut
//        }
        
//        colorFilter --> blend
//        crosshairGenerator --> blend --> renderView
//        circleGenerator --> darkenBlend --> renderView
        
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
    }
    
    func getColorForPoint(point: CGPoint, callback: (CIColor -> Void)) {
        
//        rawOut.dataAvailableCallback = {
//            buffer in
//            
//            let sizeT = self.size.transpose
//            
//            let pickX = Int( Float(point.x) * sizeT.width ) // FIXME: potential crash near edges if it can round up
//            let pickY = Int( Float(1-point.y) * sizeT.height )
//
//            // buffer layout is from lower left corner. First up (vertical - y, then horizontal -x )
//            let basePos = (pickX*Int(sizeT.height) + pickY) * 4 // 4 colors per pixel
//            
//            let red = buffer[basePos]
//            let green = buffer[basePos+1]
//            let blue = buffer[basePos+2]
//            
//            func toCGF(val: UInt8) -> CGFloat {
//                return CGFloat(val)/255
//            }
//            
//            dispatch_async(dispatch_get_main_queue(),{
//                callback( CIColor(red: toCGF(red), green: toCGF(green), blue: toCGF(blue) ) )
//            })
//            
//            self.rawOut.dataAvailableCallback = nil // disable callback right away
//        }
    }
    
    func setColor(color: CIColor) {
//        positionFilter.uniformSettings["red"] = Float(color.red)
//        positionFilter.uniformSettings["green"] = Float(color.green)
//        positionFilter.uniformSettings["blue"] = Float(color.blue)
//        
//        colorFilter.uniformSettings["red"] = Float(color.red)
//        colorFilter.uniformSettings["green"] = Float(color.green)
//        colorFilter.uniformSettings["blue"] = Float(color.blue)
    }
    
    func setThreshold(threshold: Float) {
//        highPassTrueColorFilter.threshold = threshold
//        positionFilter.uniformSettings["threshold"] = threshold
//        colorFilter.uniformSettings["threshold"] = threshold
    }
}