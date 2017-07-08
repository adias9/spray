//
//  Picture.swift
//  Chameleon
//
//  Created by Andrew Jay Zhou on 7/5/17.
//  Copyright © 2017 Andrew Jay Zhou. All rights reserved.
//

import Foundation
import ARKit
import SceneKit

class Picture: SCNNode, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var fileName: String = ""
    var width: CGFloat = 0.2
    var height: CGFloat = 0.2
    var sceneView: ARSCNView?
    var modelLoaded: Bool = false
    var image: UIImage?
    
    var viewController: ViewController?
    
    override init() {
        super.init()
        self.name = "Picture root node"
    }
    
    init(fileName: String, width: CGFloat, height: CGFloat){
        super.init()
        self.name = "Picture root node"
        self.fileName = fileName
        self.width = width
        self.height = height
    }
    
    // do not know what this is, but I think I need to add this
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func load(){
        // Create an image plane using a pre-selected picture
        importImageFromGallery()
        print("here1")
        //        guard let picture = image else{
        //            print("found error")
        //            return
        //        }
        //        print("here2")
        //        // Change size of image here
        //        // ViewController.sceneView.bounds.width / 7000
        //        let imagePlane = SCNPlane(width: width,height: height)
        //        imagePlane.firstMaterial?.diffuse.contents = picture
        //        imagePlane.firstMaterial?.lightingModel = .constant
        //        print("here3")
        //
        //        // Create wrapper node for image
        //        let wrapperNode = SCNNode()
        //        wrapperNode.geometry = imagePlane
        //        print("here4")
        //        // Change rotation and orientation
        //        wrapperNode.rotation = SCNVector4.init(1, 0, 0, CGFloat.pi * 3/2)
        //        guard let currentFrame = viewController?.session.currentFrame else {
        //            return
        //        }
        //        wrapperNode.simdEulerAngles.y = currentFrame.camera.eulerAngles.y
        //        // Add as child node
        //        self.addChildNode(wrapperNode)
        //
        //        modelLoaded = true
    }
    
    func importImageFromGallery(){
        let image = UIImagePickerController()
        image.delegate = self
        
        image.sourceType = UIImagePickerControllerSourceType.photoLibrary
        
        image.allowsEditing = true
        self.viewController?.present(image, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        print("here")
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage{
            self.image = image
        } else {
            // check if displaying error message correctly
            viewController?.textManager.showMessage("No Image Found!!")
            return
        }
        print("here2")
        // Change size of image here
        // ViewController.sceneView.bounds.width / 7000
        let imagePlane = SCNPlane(width: width,height: height)
        imagePlane.firstMaterial?.diffuse.contents = image
        imagePlane.firstMaterial?.lightingModel = .constant
        print("here3")
        
        // Create wrapper node for image
        let wrapperNode = SCNNode()
        wrapperNode.geometry = imagePlane
        print("here4")
        // Change rotation and orientation
        wrapperNode.rotation = SCNVector4.init(1, 0, 0, CGFloat.pi * 3/2)
        guard let currentFrame = viewController?.session.currentFrame else {
            return
        }
        print("here5")
        wrapperNode.simdEulerAngles.y = currentFrame.camera.eulerAngles.y
        // Add as child node
        self.addChildNode(wrapperNode)
        
        modelLoaded = true
        print("here6")
        
        self.viewController?.dismiss(animated: true, completion: nil)
    }
    
    
    func unload(){
        for child in self.childNodes {
            child.removeFromParentNode()
        }
        
        modelLoaded = false
    }
    
    func translateBasedOnScreenPos(_ pos: CGPoint, instantly: Bool, infinitePlane: Bool) {
        
        guard let controller = viewController else {
            return
        }
        
        let result = controller.worldPositionFromScreenPosition(pos, objectPos: self.position, infinitePlane: infinitePlane)
        
        controller.moveVirtualObjectToPosition(result.position, instantly, !result.hitAPlane)
    }
    
}

extension Picture {
    
    static func isNodePartOfPicture (_ node: SCNNode) -> Bool {
        if node.name == "Picture root node" {
            return true
        }
        
        if node.parent != nil {
            return isNodePartOfPicture(node.parent!)
        }
        
        return false
    }
    
    //    static let availableObjects: [VirtualObject] = [
    //        Candle(),
    //        Cup(),
    //        Vase(),
    //        Lamp(),
    //        Chair()
    //    ]
}

// MARK: - Protocols for Pictures

protocol ReactsToScale {
    func reactToScale()
}

extension SCNNode {
    
    func reactsToScale() -> ReactsToScale? {
        if let canReact = self as? ReactsToScale {
            return canReact
        }
        
        if parent != nil {
            return parent!.reactsToScale()
        }
        
        return nil
    }
}


