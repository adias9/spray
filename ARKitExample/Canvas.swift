//
//  Canvas.swift
//  ARKitExample
//
//  Created by Andrew Jay Zhou on 8/16/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import Foundation
import UIKit

class Canvas : UIView, UIDragInteractionDelegate, UIDropInteractionDelegate {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let dragInteraction = UIDragInteraction(delegate: self)
        dragInteraction.isEnabled = true
        self.addInteraction(dragInteraction)
        self.addInteraction(UIDropInteraction(delegate: self))
        
//        self.backgroundColor = UIColor.white
//        self.heightAnchor.constraint(equalToConstant: 320).isActive = true
    }
    
    @objc func handlePinchToScale(recognizer: UIPinchGestureRecognizer){
        if let view = recognizer.view {
            view.transform = view.transform.scaledBy(x: recognizer.scale, y: recognizer.scale)
            recognizer.scale = 1
        }
    }
    
    @objc func handleRotate(recognizer : UIRotationGestureRecognizer) {
        if let view = recognizer.view {
            print("before", view.transform)
            view.transform = view.transform.rotated(by: recognizer.rotation)
            print(recognizer.rotation)
            print("after", view.transform)
            recognizer.rotation = 0
        }
    }
  
    
    // MARK :- Drag Delegate
    func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession) -> [UIDragItem] {
        let touchedPoint = session.location(in: self)
        if let touchedImageView = self.hitTest(touchedPoint, with: nil) as? UIImageView {
            let touchedImage = touchedImageView.image
            
            let itemProvider = NSItemProvider(object: touchedImage!)
            let dragItem = UIDragItem(itemProvider: itemProvider)
            dragItem.localObject = touchedImageView
            return [dragItem]
        }
        return []
    }
    func dragInteraction(_ interaction: UIDragInteraction,
                         previewForLifting item: UIDragItem, session: UIDragSession) -> UITargetedDragPreview? {
        print("1")
        let previewView =  item.localObject as! UIImageView
//        previewView.transform = previewView.transform.rotated(by: 60)
        let target = UIDragPreviewTarget.init(container: self, center: previewView.center)//, transform: previewView.transform)
        let preview = UITargetedDragPreview(view: previewView, parameters: UIDragPreviewParameters.init(), target: target)
        
        item.previewProvider = {
            return UIDragPreview(view: item.localObject as! UIView)
        }
        //        return UITargetedDragPreview(view: item.localObject as! UIImageView)
        return preview
    }
    func dragInteraction(_ interaction: UIDragInteraction, prefersFullSizePreviewsFor session: UIDragSession) -> Bool {
        print("7")
        return true
    }
    func dragInteraction(_ interaction: UIDragInteraction, sessionWillBegin session: UIDragSession) {
        print("3")
        for item in session.items {
            item.previewProvider = {() -> UIDragPreview in
                //                let preview = UIImageView()
                //                preview.loadGif(name: "drake")
                //                return UIDragPreview(view: preview)
                return UIDragPreview(view: item.localObject as! UIView)
            }
        }
    }
    func dragInteraction(_ interaction: UIDragInteraction, sessionDidMove session: UIDragSession) {
        print("4")
        for item in session.items {
            item.previewProvider = {
                return UIDragPreview(view: item.localObject as! UIView)
            }
        }
    }
    func dragInteraction(_ interaction: UIDragInteraction, session: UIDragSession, willEndWith operation: UIDropOperation) {
        print("5")
        for item in session.items {
            item.previewProvider = {
                return UIDragPreview(view: item.localObject as! UIView)
            }
        }
    }
    func dragInteraction(_ interaction: UIDragInteraction, session: UIDragSession, didEndWith operation: UIDropOperation) {
        print("6")
        for item in session.items {
            item.previewProvider = {
                return UIDragPreview(view: item.localObject as! UIView)
            }
        }
    }
    func dragInteraction(_ interaction: UIDragInteraction, willAnimateLiftWith animator: UIDragAnimating, session: UIDragSession) {
        print("2")
        session.items.forEach {(dragItem) in
            if let touchedImageView = dragItem.localObject as? UIView {
                touchedImageView.removeFromSuperview()
                //                dragItem.previewProvider = {
                //                    return UIDragPreview(view: touchedImageView)
                //                }
                //                animator.addAnimations {
                //
                //                    dragItem.alpha = 0.5
                //                }
            }
        }
    }
    func dragInteraction(_ interaction: UIDragInteraction, item: UIDragItem, willAnimateCancelWith animator: UIDragAnimating) {
        self.addSubview(item.localObject as! UIView)
    }
    
    
    // MARK :- Drop Delegate
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        for dragItem in session.items{
            dragItem.itemProvider.loadObject(ofClass: UIImage.self, completionHandler: { (obj,err) in
                if let err = err {
                    print("failed to load dragged item: ", err)
                    return
                }
                guard let draggedImage = obj as? UIImage else {return}
                DispatchQueue.main.async {
                    let imageView = UIImageView(image: draggedImage)
                    
                    self.addSubview(imageView)
                    imageView.frame = CGRect(x: 0, y: 0, width: self.frame.width / 4, height: self.frame.height / 4)
                    if let originalImageView = dragItem.localObject as? UIImageView {
                        imageView.transform = originalImageView.transform
                    }
                    
                    let centerPoint = session.location(in: self)
                    imageView.center = centerPoint
                    imageView.isUserInteractionEnabled = true
                    let pinchToScaleGesture = UIPinchGestureRecognizer(target: self, action:
                        #selector(self.handlePinchToScale(recognizer:)))
                    imageView.addGestureRecognizer(pinchToScaleGesture)
                    let rotateGesture = UIRotationGestureRecognizer(target: self, action: #selector(self.handleRotate(recognizer:)))
                    imageView.addGestureRecognizer(rotateGesture)
                }
                
            })
        }
    }
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: UIImage.self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
