//
//  CustomProgressView.swift
//  Juker
//
//  Created by Alex Mitchell on 2017-07-04.
//  Copyright © 2017 Alex Mitchell. All rights reserved.
//

import UIKit

class CustomProgressView: UIView {
    
    fileprivate var bezierPath: UIBezierPath!
    fileprivate var progressLayer : CAShapeLayer!
    fileprivate var backgroundLayer : CAShapeLayer!
    
    var progress: Float = 0 {
        didSet(newValue) {
            progressLayer.strokeEnd = CGFloat(newValue)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        
    }
    
    init(frame: CGRect, path: UIBezierPath) {
        super.init(frame: frame)
        bezierPath = path
        setup()
        
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    func setup() {
        progressLayer = CAShapeLayer()
        progressLayer.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height)
        progressLayer.path = bezierPath.cgPath
        progressLayer.lineWidth = 6
        progressLayer.strokeColor = UIColor(red: 0.0/255, green: 183.0/255, blue: 253.0/255, alpha: 1.0).cgColor
        progressLayer.fillColor = nil
        progressLayer.strokeEnd = 0.0
        progressLayer.lineCap = kCALineCapSquare
        
        backgroundLayer = CAShapeLayer()
        backgroundLayer.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height)
        backgroundLayer.path = bezierPath.cgPath
        backgroundLayer.lineWidth = 6
        backgroundLayer.strokeColor = UIColor(colorLiteralRed: 220/255, green: 220/255, blue: 220/255, alpha: 1.0).cgColor
        backgroundLayer.fillColor = nil
        backgroundLayer.lineCap = kCALineCapSquare
        
        self.layer.addSublayer(backgroundLayer)
        self.layer.addSublayer(progressLayer)
    }
    
    

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
//    func setupQuadCurve() {
//        // At some point, will make jukeView a custom UIView Class that will initialize a quadcurve upon setup and attach gesture capabilties
//        
//        let p1 = CGPoint(x: jukeView.bounds.origin.x, y: jukeView.bounds.origin.y + 2)
//        let p2 = CGPoint(x: jukeView.bounds.width, y: jukeView.bounds.origin.y + 2)
//        let controlP = CGPoint(x: jukeView.bounds.width / 2, y: jukeView.bounds.origin.y - 120)
//        addCurve(startPoint: p1, endPoint: p2, controlPoint: controlP)
//    }
//    
//    func addCurve(startPoint: CGPoint, endPoint: CGPoint, controlPoint: CGPoint) {
//        
//        let layer = CAShapeLayer()
//        
//        jukeView.layer.addSublayer(layer)
//        layer.strokeColor = jukeView.layer.backgroundColor
//        layer.fillColor = jukeView.layer.backgroundColor
//        layer.lineWidth = 1
//        
//        let path = UIBezierPath()
//        
//        path.move(to: startPoint)
//        path.addQuadCurve(to: endPoint, controlPoint: controlPoint)
//        layer.path = path.cgPath
//        path.stroke()
//        
//    }

}
