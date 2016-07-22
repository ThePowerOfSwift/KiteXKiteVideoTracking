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
}

class Kite {
    let d: Double = 20
    let r: Double = 20
    var positionLast: Vector3?
    var velocityLast: Vector3?
    var timeLast: Double?
    
    let FOV_horizontal = 61.7/180*M_PI // deg
    //let FOV_horizontal = 61.7/180*M_PI // deg
    let aspectRatio = 1.33
    
    // point relative to video frame
    // assumes that center bottom is straigt downwind
    func calculateBetaPsi(p: CGPoint) -> (Double, Double) {
        let qx = Double(p.x-0.5)*FOV_horizontal
        let qy = Double(p.y)/aspectRatio*FOV_horizontal
        
        let alpha = sqrt(pow(qx, 2) + pow(qy, 2))
        let psi = atan2(qy, qx)
        
        let beta = M_PI/2 + alpha - acos(sin(alpha)*d/r)
        
        return (beta, psi)
    }
    
    
    func normalizedPosition(beta: Double, psi: Double) -> Vector3 {
        return Vector3(x: cos(psi)*sin(beta), y: cos(beta), z: sin(psi)*sin(beta))
    }
    
    func newPosition(p: CGPoint, time: Double) -> KiteKinematics? {
        let (beta, psi) = calculateBetaPsi(p)
        let position = normalizedPosition(beta, psi: psi)
        var kinematics: KiteKinematics!
        
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
                
                kinematics = KiteKinematics(time: time, position: position*r, velocity: velocity*r, angularVelocity: angle/dT)
            }
            velocityLast = velocity
        }
        positionLast = position
        timeLast = time
        return kinematics
    }
}
