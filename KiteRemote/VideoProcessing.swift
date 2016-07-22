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

    private let rawOut = RawDataOutput()
    private let positionOut = RawDataOutput()

    private let moviePosition = NSBundle.mainBundle().pathForResource("IMG_0459", ofType: "MOV")!

    
    var newPosition: ((CGPoint, Double) -> Void)?
    
    init(renderView: RenderView, video: Bool) {

        self.renderView = renderView
        renderView.orientation = .LandscapeRight

        crosshairGenerator = CrosshairGenerator(size: size.transpose)
        crosshairGenerator.crosshairWidth = 15

        do {
            positionFilter = try BasicOperation(fragmentShaderFile: NSURL(fileURLWithPath: pathPosition))
            colorFilter = try BasicOperation(fragmentShaderFile: NSURL(fileURLWithPath: pathColor))
            if video {
                movieInput = try MovieInput(url: NSURL(fileURLWithPath: moviePosition), playAtActualSpeed: false, loop: true)
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
                    
                    newPosition( CGPoint(x: x, y: y),  time)
                    
                })
                
            }
            
            self.crosshairGenerator.renderCrosshairs([Position(Float(x),Float(y))])
        }
        
        setColor(CIColor(red: 1.0, green: 0, blue: 0))
        setThreshold(0.2)
        
        
        if let camera = camera {
            camera --> rawOut
            camera --> colorFilter
            camera --> positionFilter --> positionOut
        }

        if let movieInput = movieInput {
            movieInput --> rawOut
            movieInput --> colorFilter
            movieInput --> positionFilter --> positionOut
        }
        
        colorFilter --> blend
        crosshairGenerator --> blend --> renderView
        
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
        positionFilter.uniformSettings["threshold"] = threshold
        colorFilter.uniformSettings["threshold"] = threshold
    }
}