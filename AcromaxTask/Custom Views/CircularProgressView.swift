//
//  CircularProgressView.swift
//  ProgressExample
//
//  Created by Hashaam Siddiq on 9/5/17.
//  Copyright © 2017 Hashaam. All rights reserved.
//

import UIKit

@IBDesignable class CircularProgressView: UIView {
    
    private var shapeLayer = CAShapeLayer()
    private var radius = CGFloat(50.0)
    
    @IBInspectable var strokeColor: UIColor = UIColor.red {
        didSet {
            shapeLayer.strokeColor = strokeColor.cgColor
        }
    }
    
    @IBInspectable var progress: CGFloat {
        get {
            return shapeLayer.strokeEnd
        }
        set {
            if newValue > 1.0 {
                shapeLayer.strokeEnd = 1.0
            } else if newValue < 0.0 {
                shapeLayer.strokeEnd = 0.0
            } else {
                shapeLayer.strokeEnd = newValue
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }
    
    func configure() {
        
        shapeLayer = CAShapeLayer()
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = strokeColor.cgColor
        shapeLayer.lineWidth = 2.0
        shapeLayer.frame = bounds
        shapeLayer.strokeStart = 0.0
        shapeLayer.strokeEnd = 0.0
        
        layer.addSublayer(shapeLayer)
        
        backgroundColor = .white
        
    }
    
    func shapePath() -> UIBezierPath {
        return UIBezierPath(arcCenter: CGPoint(x: bounds.midX, y: bounds.midY), radius: radius, startAngle: -CGFloat.pi / 2.0, endAngle: 3 * CGFloat.pi / 2.0, clockwise: true)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        radius = bounds.midX
        shapeLayer.frame = bounds
        shapeLayer.path = shapePath().cgPath
    }
    
}
