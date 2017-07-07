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

class Picture: SCNNode {
    
    var fileName: String = ""
    var width: CGFloat = 0.2
    var height: CGFloat = 0.2
    var sceneView: ARSCNView?
    var modelLoaded: Bool = false
    
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
        let picture = UIImage(named: fileName)
        
        // Change size of image here
        // ViewController.sceneView.bounds.width / 7000
        let imagePlane = SCNPlane(width: width,height: height)
        imagePlane.firstMaterial?.diffuse.contents = picture
        imagePlane.firstMaterial?.lightingModel = .constant
        
        // create wrapper node for image
        let wrapperNode = SCNNode()
        wrapperNode.geometry = imagePlane
        self.addChildNode(wrapperNode)
        
        modelLoaded = true
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

