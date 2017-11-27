//
//  ViewController+Drop.swift
//  ARKitExample
//
//  Created by Andreas Dias on 10/19/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit

extension ViewController : UIDropInteractionDelegate {
    
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: UIImage.self) && session.items.count == 1
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        let dropLocation = session.location(in: view)
        
        let operation: UIDropOperation
        
        if sceneView.frame.contains(dropLocation) {
            if let sourceImageView = session.localDragSession?.localContext as? UIImageView, sourceImageView == sceneView {
                // if the local context is the same UIImageView as we would want to place the image if it was dropped here, then we don't accept it.
                operation = .forbidden
            } else {
                operation = .copy
            }
        } else {
            operation = .cancel
        }
        
        return UIDropProposal(operation: operation)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        dropPoint = session.location(in: interaction.view!)
        if let dropName = imageNodeName(at: dropPoint) {
            if dropName.range(of:"pix") != nil {

                for dragItem in session.items {
                    loadImage(dragItem.itemProvider, nodeName: dropName)
                }
                hidePreview()
            }
        }
    }
    
    func imageNodeName(at point: CGPoint) -> String? {
        let scnHitTestResults = sceneView.hitTest(point, options: nil)
        if let result = scnHitTestResults.first {
            return result.node.name
        }
        return nil
    }
}
