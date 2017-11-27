//
//  VC+Rotate.swift
//  ARKitExample
//
//  Created by Andreas Dias on 11/9/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import Foundation
import UIKit
import ARKit

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
        if let object = objectInteracting(with: gesture, in: sceneView) {
//            let init_pos = view.center
            if let interactObject = postObject?.childNode(withName: object, recursively: true) {
//                let res_mag = gesture.center(in: view).distanceTo(init_pos)
//                postObject?.eulerAngles.y -= Float(res_mag)
                postObject?.eulerAngles.y -= Float(gesture.rotation)

                
                gesture.rotation = 0
            }
        }
    }
    
    /// A helper method to return the first object that is found under the provided `gesture`s touch locations.
    /// - Tag: TouchTesting
    private func objectInteracting(with gesture: UIGestureRecognizer, in view: ARSCNView) -> String? {
        for index in 0..<gesture.numberOfTouches {
            let touchLocation = gesture.location(ofTouch: index, in: view)
            
            // Look for an object directly under the `touchLocation`.
            if let node = imageNodeName(at: touchLocation) {
                return node
            }
        }
        
        // As a last resort look for an object under the center of the touches.
        return imageNodeName(at: gesture.center(in: view))
    }
    
//    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        // Allow objects to be translated and rotated at the same time.
//        return true
//    }
    
}

extension UIGestureRecognizer {
    func center(in view: UIView) -> CGPoint {
        let first = CGRect(origin: location(ofTouch: 0, in: view), size: .zero)
        
        let touchBounds = (1..<numberOfTouches).reduce(first) { touchBounds, index in
            return touchBounds.union(CGRect(origin: location(ofTouch: index, in: view), size: .zero))
        }
        
        return CGPoint(x: touchBounds.midX, y: touchBounds.midY)
    }
}
