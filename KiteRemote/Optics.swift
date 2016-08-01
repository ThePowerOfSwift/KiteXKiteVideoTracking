//
//  Optics.swift
//  KiteRemote
//
//  Created by Andreas Okholm on 01/08/16.
//  Copyright © 2016 Andreas Okholm. All rights reserved.
//

import Foundation

class Optics {
    
    static let shared = Optics()
    
    let focalLength = 4.02 // mm
    let sensorDiagonal = 6.0 // mm
    
    let fieldOfViewVertical: Double
    let fieldOfViewHorizontal: Double
    
    init() {
//         c = sqrt(a*a + b*b)
//         a = 4/3 * b
//         c*c = 4*4/3*3 b*b + b*b
//         c*c = (1 +  16/9) b*b
        let c = atan(sensorDiagonal/2/focalLength)*2 // *180/M_PI // diagonal FOV
        let b = pow(c*c / (1 + 16/9),  (1/2))
        let a = 4/3*b
        
        fieldOfViewVertical = b
        fieldOfViewHorizontal = a
    }
    
    static let r: Double = 45
    static let d: Double = 45
    
    static func alpha(beta: Double) -> Double {
        let Q = M_PI - beta
        let q: Double = sqrt(r*r + d*d - 2*r*d*cos(Q)) // cos rule
        return asin( r * sin(Q) / q) // sin rule sin(alpha) / r = sin(Q) / q
    }
}