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

extension Size {
    
    var transpose: Size {
        get {
            return Size(width: height, height: width)
        }
    }
}


public class DifferenceFilter: BasicOperation {
    public var threshold:Float = 0.0 { didSet { uniformSettings["threshold"] = threshold } }
    
    public init?() {
        let pathPosition = NSBundle.mainBundle().pathForResource("DifferenceThreshold", ofType: "fsh")!
        let url = NSURL(fileURLWithPath: pathPosition)
        
        do {
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
            red = 0.5
            redGreen = 0.7
            redBlue = 4.0
        })()
    }
}



class VideoProcessing {
    
    private let camera: Camera?
    private let size = Size(width: 640, height: 480)
    private let movieInput: MovieInput?
    
    private let crosshairGenerator: CrosshairGenerator!
    private let renderView: RenderView!
    
    private let blend = AlphaBlend()
    
    private let pathPosition = NSBundle.mainBundle().pathForResource("PositionColor", ofType: "fsh")!
    private let pathColor = NSBundle.mainBundle().pathForResource("ThresholdShader", ofType: "fsh")!
    private let positionFilter: BasicOperation!
    private let colorFilter: BasicOperation!
    private let motionDetector = MotionDetector()
    private let highPassFilter = HighPassFilter()
    private let darkenBlend = DarkenBlend()
    private let circleGenerator: CircleGenerator!
    private let highPassTrueColorFilter = HighPassTrueColorFilter()
    private let kiteColorFilter = KiteColorFilter()!
    
    
    
    private let rawOut = RawDataOutput()
    private let positionOut = RawDataOutput()

    private let moviePosition = NSBundle.mainBundle().pathForResource("IMG_0459", ofType: "MOV")!

    
    var newPosition: ((CGPoint, Double) -> Void)?
    
    init(renderView: RenderView, video: Bool) {

        self.renderView = renderView
        renderView.orientation = .LandscapeRight
        
        circleGenerator = CircleGenerator(size: size.transpose)
//        circleGenerator.renderCircleOfRadius(0.1, center: Position(0.5,0.5))
        circleGenerator.renderCircleOfRadius(0.1,
                                             center: Position(0.5,0.5),
                                             circleColor: Color(red: 1, green: 1, blue: 1, alpha: 1),
                                             backgroundColor: Color(red: 0, green: 0, blue: 0, alpha: 1))

        
        crosshairGenerator = CrosshairGenerator(size: size.transpose)
        crosshairGenerator.crosshairWidth = 15
        
        do {
            positionFilter = try BasicOperation(fragmentShaderFile: NSURL(fileURLWithPath: pathPosition))
            colorFilter = try BasicOperation(fragmentShaderFile: NSURL(fileURLWithPath: pathColor))
            
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
        
        
        motionDetector.motionDetectedCallback = {
            (pos: Position, strength: Float) in
            self.crosshairGenerator.renderCrosshairs([pos])
            print(pos)
            
        }
        
        positionOut.dataAvailableCallback = {
            (imageBuffer: [UInt8]) in
            
            let N = Int(self.size.height*self.size.width)
            
            var sumAlpha: Int = 0 // FIXME: Concider using accelerate for sumation.
            var sumRed: Int = 0
            var sumGreen: Int = 0
            for i in 0..<N {
                sumAlpha += Int(imageBuffer[4*i+3])
                sumRed += Int(imageBuffer[4*i+0])
                sumGreen += Int(imageBuffer[4*i+1])
            }
            
            let x = Double(sumRed)/Double(sumAlpha)
            let y = Double(sumGreen)/Double(sumAlpha)
//            let intensity = Float(sumAlpha)/Float(N)
            
            if let newPosition = self.newPosition where !x.isNaN {
                
                let time = NSDate.timeIntervalSinceReferenceDate()
                
                dispatch_async(dispatch_get_main_queue(),{
                    newPosition( CGPoint(x: y, y: x),  time) // transpose
                    
                })
                
            }
            
            self.crosshairGenerator.renderCrosshairs([Position(Float(x),Float(y))])
        }
        
        setColor(CIColor(red: 1.0, green: 0, blue: 0))
        setThreshold(0.2)
        
        
        if let camera = camera {
            camera --> rawOut
//            camera --> colorFilter
//            camera --> positionFilter --> positionOut
//            camera --> highPassFilter --> blend
            camera --> highPassTrueColorFilter --> kiteColorFilter --> renderView

        }

        if let movieInput = movieInput {
            movieInput --> rawOut
            movieInput --> colorFilter
            movieInput --> positionFilter --> positionOut
        }
        
//        colorFilter --> blend
//        crosshairGenerator --> blend --> renderView
//        circleGenerator --> darkenBlend --> renderView
        
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
    
    func getColorForPoint(point: CGPoint, callback: (CIColor -> Void)) {
        
        rawOut.dataAvailableCallback = {
            buffer in
            
            let pickX = Int( Float(point.x) * self.size.width ) // FIXME: potential crash near edges if it can round up
            let pickY = Int( Float(1-point.y) * self.size.height )

            // buffer layout is from lower left corner. First up (vertical - y, then horizontal -x )
            let basePos = (pickX*Int(self.size.height) + pickY) * 4 // 4 colors per pixel
            
            let red = buffer[basePos]
            let green = buffer[basePos+1]
            let blue = buffer[basePos+2]
            
            func toCGF(val: UInt8) -> CGFloat {
                return CGFloat(val)/255
            }
            
            dispatch_async(dispatch_get_main_queue(),{
                callback( CIColor(red: toCGF(red), green: toCGF(green), blue: toCGF(blue) ) )
            })
            
            self.rawOut.dataAvailableCallback = nil // disable callback right away
        }
    }
    
    func setColor(color: CIColor) {
        positionFilter.uniformSettings["red"] = Float(color.red)
        positionFilter.uniformSettings["green"] = Float(color.green)
        positionFilter.uniformSettings["blue"] = Float(color.blue)
        
        colorFilter.uniformSettings["red"] = Float(color.red)
        colorFilter.uniformSettings["green"] = Float(color.green)
        colorFilter.uniformSettings["blue"] = Float(color.blue)
    }
    
    func setThreshold(threshold: Float) {
        highPassTrueColorFilter.threshold = threshold
        highPassFilter.strength = threshold
        motionDetector.lowPassStrength = threshold
        positionFilter.uniformSettings["threshold"] = threshold
        colorFilter.uniformSettings["threshold"] = threshold
    }
}