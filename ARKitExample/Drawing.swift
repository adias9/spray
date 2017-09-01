//
//  Drawing.swift
//  ARKitExample
//
//  Created by Andrew Jay Zhou on 8/17/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit

class Drawing : UIView, ColorSliderDelegate {
    
    var lines : [Line] = []
    var lastPoint : CGPoint?
    var currentLine: Line?
    var text : Text?
    var isActive: Bool = true
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = true
        backgroundColor = UIColor.clear
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isActive {
            currentLine = Line()
            currentLine?.color = color
            lines.append(currentLine!)
            lastPoint = touches.first?.location(in: self)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isActive {
            let newPoint = touches.first?.location(in: self)
            currentLine?.appendSegment(start: lastPoint!, end: newPoint!)
            lastPoint = newPoint
            
            
            self.setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        context?.setLineCap(.round)
        context?.setLineWidth(5)
        for line in lines {
            // draw the line
            for segment in line.segments {
                context?.beginPath()
                context?.move(to: segment.start!)
                context?.addLine(to: segment.end!)
                context?.setStrokeColor(line.color)
                context?.strokePath()
            }
        }
    }
    
    func undo() {
        if !lines.isEmpty {
            lines.remove(at: lines.count - 1)
            setNeedsDisplay()
        }
    }
    
    func reset() {
        lines.removeAll()
        setNeedsDisplay()
    }
    
    // Update color when ColorSlider color is changed
    private var color : CGColor = UIColor.red.cgColor
    func updateColor(_ color: UIColor?) {
        self.color = (color?.cgColor)!
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
