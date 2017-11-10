//
//  VC+Rotate.swift
//  ARKitExample
//
//  Created by Andreas Dias on 11/9/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit

extension ViewController {
    @objc
    func didRotate(_ gesture: UIRotationGestureRecognizer) {
        guard gesture.state == .changed else { return }
        
        /*
         - Note:
         For looking down on the object (99% of all use cases), we need to subtract the angle.
         To make rotation also work correctly when looking from below the object one would have to
         flip the sign of the angle depending on whether the object is above or below the camera...
         */
        let postObject = sceneView.scene.rootNode.childNode(withName: "distinct_cube", recursively: true)
        
        postObject?.eulerAngles.y -= Float(gesture.rotation)
        
        gesture.rotation = 0
    }
}
