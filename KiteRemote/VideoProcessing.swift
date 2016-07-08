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

class VideoProcessing {
    
    let camera: Camera!
    
    let videoSize = CGSize(width: 640, height: 480)
    let size = Size(width: 640, height: 480)
    
    
    let crosshairGenerator: CrosshairGenerator!
    let renderView: RenderView!
    
    let blend = AlphaBlend()
    
    let pathPosition = NSBundle.mainBundle().pathForResource("PositionColor", ofType: "fsh")!
    let pathColor = NSBundle.mainBundle().pathForResource("ThresholdShader", ofType: "fsh")!
    let positionFilter: BasicOperation!
    let colorFilter: BasicOperation!

    
    let rawOut = RawDataOutput()
    let positionOut = RawDataOutput()
    
    init(renderView: RenderView) {

        self.renderView = renderView
        crosshairGenerator = CrosshairGenerator(size: size)
        crosshairGenerator.crosshairWidth = 15
        
        do {
            positionFilter = try BasicOperation(fragmentShaderFile: NSURL(fileURLWithPath: pathPosition))
            colorFilter = try BasicOperation(fragmentShaderFile: NSURL(fileURLWithPath: pathColor))
            
            camera = try Camera(sessionPreset:AVCaptureSessionPreset640x480)
            renderView.orientation = .LandscapeRight
//            camera --> filter --> renderView
        } catch {
            fatalError("Could not initialize rendering pipeline: \(error)")
        }
        
        
        positionOut.dataAvailableCallback = {
            (imageBuffer: [UInt8]) in
            
            let N = Int(self.size.height*self.size.width)
            
            var sumAlpha: Int = 0
            var sumRed: Int = 0
            var sumGreen: Int = 0
            for i in 0..<N {
                sumAlpha += Int(imageBuffer[4*i+3])
                sumRed += Int(imageBuffer[4*i+0])
                sumGreen += Int(imageBuffer[4*i+1])
            }
            
            let x = Float(sumRed)/Float(sumAlpha)
            let y = Float(sumGreen)/Float(sumAlpha)
            let intensity = Float(sumAlpha)/Float(N)
            
//            print("Position (x,y): \(x),\(y), intensity: \(intensity)")
            
            self.crosshairGenerator.renderCrosshairs([Position(x,y)])
        }
        
        setColor(CIColor(red: 1.0, green: 0, blue: 0))
        setThreshold(0.2)
        
        camera --> rawOut
        camera --> colorFilter
        camera --> positionFilter --> positionOut
        
        colorFilter --> blend
        crosshairGenerator --> blend --> renderView
        
        camera.startCapture()
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
            
            self.rawOut.dataAvailableCallback = nil
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