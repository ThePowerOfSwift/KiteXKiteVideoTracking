//
//  KitePosition.swift
//  KiteRemote
//
//  Created by Andreas Okholm on 11/07/16.
//  Copyright © 2016 Andreas Okholm. All rights reserved.
//

import UIKit


struct Vector3: CustomStringConvertible {
    let x: Double
    let y: Double
    let z: Double
    
    var description: String {
        return "x: \(x) y: \(y) z: \(z)"
    }
    
    func dot(r: Vector3) -> Double {
        return x * r.x + y * r.y + z * r.z
    }
    
    func cross(r: Vector3) -> Vector3 {
        return Vector3(x: y * r.z - z * r.y,
                       y: z * r.x - x * r.z,
                       z: x * r.y - y * r.x)
    }
    
    var length: Double {
        return sqrt( x*x + y*y + z*z)
    }
    
    var normalized: Vector3 {
        return self * (1/length)
    }
}


func - (left: Vector3, right: Vector3) -> Vector3 {
    return Vector3(x: left.x-right.x, y: left.y-right.y, z: left.z-right.z)
}

func * (left: Vector3, right: Double) -> Vector3 {
    return Vector3(x: left.x*right, y: left.y*right, z: left.z*right)
}


struct KiteKinematics {
    let time: Double
    let position: Vector3
    let velocity: Vector3
    let angularVelocity: Double
}

extension Vector3 {
    var json: [Double] {
        return [x,y,z]
    }
}

extension KiteKinematics {
    var json: NSDictionary {
        let dict = ["t": time,
                    "p": position.json,
                    "v": velocity.json,
                    "av": angularVelocity]
        return dict
    }
    
    var data: NSData {
        var array = [Double](count: 8, repeatedValue: 0)
        array[0] = time
        array[1] = position.x
        array[2] = position.y
        array[3] = position.z
        array[4] = velocity.x
        array[5] = velocity.y
        array[6] = velocity.z
        array[7] = angularVelocity
        
        return NSData(bytes: array, length: 8*sizeof(Double))
    }
}

class Kite {
    var positionLast: Vector3?
    var velocityLast: Vector3?
    var timeLast: Double?
    let alphaMax = Optics.alpha(M_PI_2)
    
    // point relative to video frame
    // assumes that center bottom is straigt downwind
    func calculateBetaPsi(p: CGPoint) -> (Double, Double)? {
        let qx = Double(p.x-0.5)*Optics.shared.fieldOfViewHorizontal
        let qy = Double(p.y)*Optics.shared.fieldOfViewVertical
        
        let alpha = sqrt(pow(qx, 2) + pow(qy, 2))
        
        if (alpha > alphaMax) {
            return nil
        }
        
        let psi = atan2(qy, qx)
        
        let beta = M_PI/2 + alpha - acos(sin(alpha)*Optics.d/Optics.r)
        print(alpha*180/M_PI)
        
        return (beta, psi)
    }
    
    
    func normalizedPosition(beta: Double, psi: Double) -> Vector3 {
        return Vector3(x: cos(psi)*sin(beta), y: cos(beta), z: sin(psi)*sin(beta))
    }
    
    func newPosition(p: CGPoint, time: Double) -> KiteKinematics? {
        var kinematics: KiteKinematics? = nil
        
        guard let (beta, psi) = calculateBetaPsi(p) else {
            return kinematics
        }
        
        let position = normalizedPosition(beta, psi: psi)
        
        if let positionLast = positionLast, timeLast = timeLast {
            //print(velocity(lastPos, new: pos))
            let dT = time - timeLast
            let velocity = (position - positionLast) * (1/dT)
            //print(delta)
            if let velocityLast = velocityLast {
                // project delta and lastDelta onto the plane of pos
                let velocityOnPlane = velocity - positionLast*velocity.dot(positionLast)
                let velocityOnPlaneLast = velocityLast - positionLast*velocityLast.dot(positionLast)
                
//                print("point:            \(p)")
//                print("position          \(position)")
//                print("velocity          \(velocity)")
//                print("velocityN         \(velocity.normalized)")
//                print("subtract:         \(position*velocity.dot(position))")
//                print("velocity on plane \(velocityOnPlane)")
//                print("last vel on plane \(velocityLast)")
                
                var angle = acos(velocityOnPlane.normalized.dot(velocityOnPlaneLast.normalized))
                
                // compare the direction of the cross product of vectors to the normal
                if (velocityOnPlane.normalized.cross(velocityOnPlaneLast.normalized).dot(positionLast) < 0) {
                    angle = -angle
                }
                
                kinematics = KiteKinematics(time: time, position: position*Optics.r, velocity: velocity*Optics.r, angularVelocity: angle/dT)
            }
            velocityLast = velocity
        }
        positionLast = position
        timeLast = time
        return kinematics
    }
}
