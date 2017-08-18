//
//  Text.swift
//  ARKitExample
//
//  Created by Andrew Jay Zhou on 8/17/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit

class Text: UILabel {
    
    let editView = UITextView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.red
        text = "I'm Andrew, and I'm awesome"
        font = UIFont(name: "Helvetica", size: 20)
        textAlignment = .center
     
        let pinchToScale = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinchToScale(recognizer:)))
        let rotate = UIRotationGestureRecognizer(target: self, action: #selector(self.handleRotate(recognizer:)))
        addGestureRecognizer(pinchToScale)
        addGestureRecognizer(rotate)

    }
    
    @objc func handlePinchToScale(recognizer: UIPinchGestureRecognizer) {
        if let view = recognizer.view {
            view.transform = view.transform.scaledBy(x: recognizer.scale, y: recognizer.scale)
            recognizer.scale = 1
        }
        
    }
    
    @objc func handleRotate(recognizer: UIRotationGestureRecognizer) {
        if let view = recognizer.view {
            view.transform = view.transform.rotated(by: recognizer.rotation)
            recognizer.rotation = 0
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // Logic for dragging text label
//    var drag: Bool = false
//
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        for touch in touches {
//            if touch.view == text { drag = true}
//        }
//    }
//
//    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//        let point = touches.first?.location(in: self)
//        if drag { text!.center = point! }
//    }
//
//    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        drag = false
//    }
}
