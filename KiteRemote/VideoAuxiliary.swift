//
//  VideoAuxiliary.swift
//  KiteRemote
//
//  Created by Andreas Okholm on 12/09/16.
//  Copyright © 2016 Andreas Okholm. All rights reserved.
//

import Foundation
import GPUImage

extension Size {
    var transpose: Size { return Size(width: height, height: width) }
    
    var w: Int { return Int(width) }
    var h: Int { return Int(height) }
    var N: Int { return w*h }
}


open class DifferenceFilter: BasicOperation {
    open var threshold:Float = 0.0 { didSet { uniformSettings["threshold"] = threshold } }
    
    public init?() {
        let pathPosition = Bundle.main.path(forResource: "DifferenceThreshold", ofType: "fsh")!
        let url = URL(fileURLWithPath: pathPosition)
        
        do {
            let fragmentShader = try NSString(contentsOf: url, encoding: String.Encoding.utf8.rawValue) as String
            super.init(fragmentShader:fragmentShader, numberOfInputs:2)
        }
        catch {
            return nil
        }
        
        ({threshold = 0.1})()
    }
}

open class HighPassTrueColorFilter: OperationGroup {
    open var lowPassStrength: Float = 0.5 { didSet { lowPass.strength = lowPassStrength } }
    open var threshold: Float = 0.5 { didSet { differenceFilter.threshold = threshold } }
    
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

open class KiteColorFilter: BasicOperation {
    open var red:Float = 0.0 { didSet { uniformSettings["red"] = red } }
    open var redGreen:Float = 0.0 { didSet { uniformSettings["redGreen"] = redGreen } }
    open var redBlue:Float = 0.0 { didSet { uniformSettings["redBlue"] = redBlue } }
    
    
    public init?() {
        let pathPosition = Bundle.main.path(forResource: "ColorTresholdShader", ofType: "fsh")!
        let url = URL(fileURLWithPath: pathPosition)
        
        do {
            let fragmentShader = try NSString(contentsOf: url, encoding: String.Encoding.utf8.rawValue) as String
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

