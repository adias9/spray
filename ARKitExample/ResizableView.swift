//
//  ResizableView.swift
//  Resizable
//
//  Created by Caroline on 6/09/2014.
//  Copyright (c) 2014 Caroline. All rights reserved.
//

import UIKit

class ResizableView: UITextView, UITextViewDelegate, UIGestureRecognizerDelegate {
    
    var topLeft:DragHandle!
    var topRight:DragHandle!
    var bottomLeft:DragHandle!
    var bottomRight:DragHandle!
    var rotateHandle:DragHandle!
    var previousLocation = CGPoint.zero
    var rotateLine = CAShapeLayer()
    
    var showHandles = true {
        didSet {
            topLeft.isHidden = !showHandles
            topRight.isHidden = !showHandles
            bottomLeft.isHidden = !showHandles
            bottomRight.isHidden = !showHandles
            rotateHandle.isHidden = !showHandles
        }
    }
    
    override func didMoveToSuperview() {
        let resizeFillColor = UIColor.cyan
        let resizeStrokeColor = UIColor.black
        let rotateFillColor = UIColor.orange
        let rotateStrokeColor = UIColor.black
        topLeft = DragHandle(fillColor:resizeFillColor, strokeColor: resizeStrokeColor)
        topRight = DragHandle(fillColor:resizeFillColor, strokeColor: resizeStrokeColor)
        bottomLeft = DragHandle(fillColor:resizeFillColor, strokeColor: resizeStrokeColor)
        bottomRight = DragHandle(fillColor:resizeFillColor, strokeColor: resizeStrokeColor)
        rotateHandle = DragHandle(fillColor:rotateFillColor, strokeColor:rotateStrokeColor)
        
        rotateLine.opacity = 0.0
        rotateLine.lineDashPattern = [3,2]
        
        superview?.addSubview(topLeft)
        superview?.addSubview(topRight)
        superview?.addSubview(bottomLeft)
        superview?.addSubview(bottomRight)
        superview?.addSubview(rotateHandle)
        self.layer.addSublayer(rotateLine)
        
        
        var pan = UIPanGestureRecognizer(target: self, action: #selector(ResizableView.handlePan(_:)))
        topLeft.addGestureRecognizer(pan)
        pan = UIPanGestureRecognizer(target: self, action: #selector(ResizableView.handlePan(_:)))
        topRight.addGestureRecognizer(pan)
        pan = UIPanGestureRecognizer(target: self, action: #selector(ResizableView.handlePan(_:)))
        bottomLeft.addGestureRecognizer(pan)
        pan = UIPanGestureRecognizer(target: self, action: #selector(ResizableView.handlePan(_:)))
        bottomRight.addGestureRecognizer(pan)
        pan = UIPanGestureRecognizer(target: self, action: #selector(ResizableView.handleRotate(_:)))
        rotateHandle.addGestureRecognizer(pan)
        pan = UIPanGestureRecognizer(target: self, action: #selector(ResizableView.handleMove(_:)))
        self.addGestureRecognizer(pan)
        
        self.updateDragHandles()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleHandles(recognizer:)))
        superview?.addGestureRecognizer(tap)
    }

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        
        showHandles = false
        backgroundColor = UIColor.clear
        delegate = self
        font = UIFont(name: "Helvetica", size: 20)
        
        text = "THIS IS A PLACEHOLDER"
        textColor = UIColor.white
        textAlignment = .center
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handleTextSize(recognizer:)))
        addGestureRecognizer(pinch)
    }
        
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        showHandles = true
    }

    @objc func handleHandles(recognizer: UITapGestureRecognizer) {
        if recognizer.view == self {
            showHandles = true
        } else {
            showHandles = false
        }
        
    }
    
    @objc func handleTextSize(recognizer: UIPinchGestureRecognizer) {
        let currentFontSize = self.font?.pointSize
        var newScale = currentFontSize! * recognizer.scale
        if (newScale < 20.0) {
            newScale = 20.0;
        }
        if (newScale > 60.0) {
            newScale = 60.0;
        }
        
        self.font = UIFont(name: "Helvetica", size:  newScale)
        
        recognizer.scale = 1
    }
    
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateDragHandles() {
        topLeft.center = self.transformedTopLeft()
        topRight.center = self.transformedTopRight()
        bottomLeft.center = self.transformedBottomLeft()
        bottomRight.center = self.transformedBottomRight()
        rotateHandle.center = self.transformedRotateHandle()
    }
    
    //MARK: - Gesture Methods
    
    @objc func handleMove(_ gesture:UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self.superview!)
        
        var center = self.center
        center.x += translation.x
        center.y += translation.y
        self.center = center
        
        gesture.setTranslation(CGPoint.zero, in: self.superview!)
        updateDragHandles()
    }
    
    func angleBetweenPoints(_ startPoint:CGPoint, endPoint:CGPoint)  -> CGFloat {
        let a = startPoint.x - self.center.x
        let b = startPoint.y - self.center.y
        let c = endPoint.x - self.center.x
        let d = endPoint.y - self.center.y
        let atanA = atan2(a, b)
        let atanB = atan2(c, d)
        return atanA - atanB
        
    }
    
    func drawRotateLine(_ fromPoint:CGPoint, toPoint:CGPoint) {
        let linePath = UIBezierPath()
        linePath.move(to: fromPoint)
        linePath.addLine(to: toPoint)
        rotateLine.path = linePath.cgPath
        rotateLine.fillColor = nil
        rotateLine.strokeColor = UIColor.orange.cgColor
        rotateLine.lineWidth = 2.0
        rotateLine.opacity = 1.0
    }
    
    @objc func handleRotate(_ gesture:UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            previousLocation = rotateHandle.center
            self.drawRotateLine(CGPoint(x: self.bounds.size.width/2, y: self.bounds.size.height/2), toPoint:CGPoint(x: self.bounds.size.width + diameter, y: self.bounds.size.height/2))
        case .ended:
            self.rotateLine.opacity = 0.0
        default:()
        }
        let location = gesture.location(in: self.superview!)
        let angle = angleBetweenPoints(previousLocation, endPoint: location)
        self.transform = self.transform.rotated(by: angle)
        previousLocation = location
        self.updateDragHandles()
    }
    
    @objc func handlePan(_ gesture:UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        switch gesture.view! {
        case topLeft:
            if gesture.state == .began {
                self.setAnchorPoint(CGPoint(x: 1, y: 1))
            }
            self.bounds.size.width -= translation.x
            self.bounds.size.height -= translation.y
        case topRight:
            if gesture.state == .began {
                self.setAnchorPoint(CGPoint(x: 0, y: 1))
            }
            self.bounds.size.width += translation.x
            self.bounds.size.height -= translation.y
            
        case bottomLeft:
            if gesture.state == .began {
                self.setAnchorPoint(CGPoint(x: 1, y: 0))
            }
            self.bounds.size.width -= translation.x
            self.bounds.size.height += translation.y
        case bottomRight:
            if gesture.state == .began {
                self.setAnchorPoint(CGPoint.zero)
            }
            self.bounds.size.width += translation.x
            self.bounds.size.height += translation.y
        default:()
        }
        
        gesture.setTranslation(CGPoint.zero, in: self)
        updateDragHandles()
        if gesture.state == .ended {
            self.setAnchorPoint(CGPoint(x: 0.5, y: 0.5))
        }
    }
    
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

}

