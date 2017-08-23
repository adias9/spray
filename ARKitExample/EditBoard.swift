//
//  EditBoard.swift
//  ARKitExample
//
//  Created by Andrew Jay Zhou on 8/17/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit

class EditBoard : UIView{
    
    let length : CGFloat = UIScreen.main.bounds.width * 0.93
    let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.black.withAlphaComponent(0.8)
        widthAnchor.constraint(equalToConstant: length).isActive = true
        heightAnchor.constraint(equalToConstant: length).isActive = true
        
        clipsToBounds = true
        imageView.isHidden = true
        let pinchToScale = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinchToScale(recognizer:)))
        imageView.addGestureRecognizer(pinchToScale)
        imageView.isUserInteractionEnabled = true
        
    }
    
    var offsetFromImageCenter: CGPoint = CGPoint(x: 0, y: 0)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // get point of which I touch the image
        if let imageTouchPoint = touches.first?.location(in: self) {
            offsetFromImageCenter = imageView.center - imageTouchPoint
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let point = touches.first?.location(in: self) {
            imageView.center = point + offsetFromImageCenter
        }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        offsetFromImageCenter = CGPoint(x: 0, y: 0)
    }
    
    func setBackground(content: Content) {
        if (content.type == .gif){
            imageView.image = UIImage.gif(data: content.data!)
        } else {
            imageView.image = UIImage(data: content.data!)
        }
        imageView.isHidden = false
        imageView.contentMode = .scaleAspectFill
        
        
        addSubview(imageView)
        addConstraintsWithFormat("H:|[v0]|", views: imageView)
        addConstraintsWithFormat("V:|[v0]|", views: imageView)
        
        
    }
    
    func reset() {
        imageView.image = nil
        drawView.reset()
    }
    
    @objc func handlePinchToScale(recognizer: UIPinchGestureRecognizer) {
        if let view = recognizer.view {
            view.transform = view.transform.scaledBy(x: recognizer.scale, y: recognizer.scale)
            recognizer.scale = 1
        }
    }
    
    
    // MARK :- Drawing
    let drawView = Drawing()
    
    var drawState: DrawState = .inactive
    enum DrawState {
        case drawing
        case paused
        case inactive
    }
    
    func beginDrawing() {
        addSubview(drawView)
        addConstraintsWithFormat("H:|[v0]|", views: drawView)
        addConstraintsWithFormat("V:|[v0]|", views: drawView)
        drawView.isActive = true
        drawState = .drawing
    }
    
    func pauseDrawing() {
        if (drawState == .inactive) {return}
        
        drawView.isActive = false
        drawState = .paused
    }
    
    func resumeDrawing() {
        if (drawState == .inactive) {return}
        
        drawView.isActive = true
        drawState = .drawing
    }
    
    func undoDrawing() {
        drawView.undo()
    }

    
    // MARK :- Texts
    let texts: [ResizableView] = []
    
    func addText() {
        let text = ResizableView()
        text.frame = CGRect.init(x: 0, y: 0, width: 124, height: 62)
        text.center = self.center
        text.text = "SAMPLE"
        addSubview(text)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
