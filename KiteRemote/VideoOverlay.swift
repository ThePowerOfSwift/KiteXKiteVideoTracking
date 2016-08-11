//
//  VideoOverlay.swift
//  KiteRemote
//
//  Created by Andreas Okholm on 01/08/16.
//  Copyright © 2016 Andreas Okholm. All rights reserved.
//

// Dot with border, which you can control completely in Storyboard
import UIKit
@IBDesignable

class VideoOverlay:UIView
{
//    let fieldOfViewVertical: CGFloat = 48.2/180*CGFloat(M_PI) // rad
//    let r: Double = 45 // m
//    let d: Double = 45 // m
    
    @IBInspectable var ringColor: UIColor = UIColor.orangeColor()
        {
        didSet {} //print("bColor was set here") }
    }
    @IBInspectable var ringThickness: CGFloat = 4
        {
        didSet {} // print("ringThickness was set here") }
    }
    
    @IBInspectable var isSelected: Bool = true
    
    override func drawRect(rect: CGRect)
    {
        self.clipsToBounds = true
        
        let betas = Double(0).stride(through: M_PI_2, by: M_PI_2/9)
        
        betas.forEach { beta in
            let a = Optics.alpha(beta)
            
            let pointsPerAngle = rect.height/CGFloat(Optics.shared.fieldOfViewVertical)
            
            let radiusView = CGFloat(a)*pointsPerAngle
            
            let circlePath = UIBezierPath(
                arcCenter: CGPoint(x:rect.width/2,y:rect.height),
                radius: CGFloat( radiusView ),
                startAngle: CGFloat(M_PI),
                endAngle:CGFloat(0),
                clockwise: true)
            
            let shapeLayer = CAShapeLayer()
            shapeLayer.path = circlePath.CGPath
            
            shapeLayer.fillColor = UIColor.clearColor().CGColor
            shapeLayer.strokeColor = UIColor.redColor().CGColor
            shapeLayer.lineWidth = ringThickness
            
            layer.addSublayer(shapeLayer)
        }
    }
}