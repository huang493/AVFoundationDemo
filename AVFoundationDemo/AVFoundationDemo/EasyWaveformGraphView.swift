//
//  EasyWaveformGraphView.swift
//  AVFoundationDemo
//
//  Created by Mike Huang on 2021/12/19.
//

import UIKit

class EasyWaveformGraphView: UIView {
    
    var datas: [CGFloat]? {
        didSet {
            if datas != nil {
                setNeedsDisplay()
            }
        }
    }
    
    override func draw(_ rect: CGRect) {
        
        guard let datas = datas, let context = UIGraphicsGetCurrentContext() else { return }
        context.setLineWidth(2)
        context.setStrokeColor(UIColor.blue.cgColor)
        
        var xOffSet = 0.0
        let xOffPadSet = bounds.width / CGFloat(datas.count)
        let yOffZero = rect.midY
                
        context.move(to: CGPoint(x: xOffSet, y: yOffZero))
        for value in datas {
            
            context.addLine(to: CGPoint(x: xOffSet, y: Double(value)))
            context.strokePath()
            
            xOffSet += xOffPadSet
            context.move(to: CGPoint(x: xOffSet, y: yOffZero))
        }
    }
}
