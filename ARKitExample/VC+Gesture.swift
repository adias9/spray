//
//  Gesture.swift
//  ARKitExample
//
//  Created by Andrew Jay Zhou on 8/16/17.
//  Copyright © 2017 Apple. All rights reserved.
//
import ARKit
import Foundation
import SceneKit
import SpriteKit
import UIKit
import Photos
import CoreLocation
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import MobileCoreServices

extension ViewController {
    
    enum State {
        case view
        case selection
        case delete
        case place
        case keyboard
    }
    
    func configureGesturesForState(state : State) {
        if state == .view {
            longPressDarken?.isEnabled = true
            longPressDelete?.isEnabled = true
            
            tapAdd?.isEnabled = false
            tapDelete?.isEnabled = false
            tapDismissContentStack?.isEnabled = false
            tapDismissKeyboard?.isEnabled = false
            tapPreviewToStack?.isEnabled = false
        } else if state == .selection {
//            tapDismissContentStack?.isEnabled = true
            
            //-----
            tapDismissContentStack?.isEnabled = false
            tapDismissKeyboard?.isEnabled = true
            //-----
            
            longPressDarken?.isEnabled = false
            longPressDelete?.isEnabled = false
            tapAdd?.isEnabled = false
            tapDelete?.isEnabled = false
            tapDismissKeyboard?.isEnabled = false
            tapPreviewToStack?.isEnabled = false
        } else if state == .place {
            tapAdd?.isEnabled = true
            longPressDarken?.isEnabled = true
            longPressDelete?.isEnabled = true
            tapPreviewToStack?.isEnabled = true
            
            tapDismissContentStack?.isEnabled = false
            tapDelete?.isEnabled = false
            tapDismissKeyboard?.isEnabled = false
        } else if state == .keyboard {
            tapDismissKeyboard?.isEnabled = true
            
            tapAdd?.isEnabled = false
            tapDismissContentStack?.isEnabled = false
            longPressDarken?.isEnabled = false
            longPressDelete?.isEnabled = false
            tapDelete?.isEnabled = false
            tapPreviewToStack?.isEnabled = false
        } else if state == .delete {
            tapDelete?.isEnabled = true
            
            tapDismissKeyboard?.isEnabled = false
            tapAdd?.isEnabled = false
            tapDismissContentStack?.isEnabled = false
            longPressDarken?.isEnabled = false
            longPressDelete?.isEnabled = false
            tapPreviewToStack?.isEnabled = false
        }
    }
    
    func setupGestures() {
        tapDelete = UITapGestureRecognizer(target: self, action:
            #selector(self.deleteNode(tap:)))
        view.addGestureRecognizer(tapDelete!)
        
        tapAdd = UITapGestureRecognizer(target: self, action:
            #selector(self.placeObject(gestureRecognize:)))
        view.addGestureRecognizer(tapAdd!)
        
        longPressDelete = UILongPressGestureRecognizer(target: self, action: #selector(initiateDeletion(longPress:)))
        longPressDelete!.minimumPressDuration = 1.5 //*undarken
        view.addGestureRecognizer(longPressDelete!)
        longPressDelete!.delegate = self
        
        longPressDarken = UILongPressGestureRecognizer(target:self, action: #selector(darkenObject(shortPress:)))
        longPressDarken!.minimumPressDuration = 0.2
        view.addGestureRecognizer(longPressDarken!)
        longPressDarken!.delegate = self
        
        tapDismissContentStack = UITapGestureRecognizer(target: self, action: #selector(self.dismissContentStack(gestureRecognize:)))
        view.addGestureRecognizer(tapDismissContentStack!)
        tapDismissContentStack!.cancelsTouchesInView = false
        
        tapDismissKeyboard = UITapGestureRecognizer.init(target: self, action: #selector(dismissKeyboard(tap:)))
        view.addGestureRecognizer(tapDismissKeyboard!)
        tapDismissKeyboard?.isEnabled = false
        
        tapPreviewToStack = UITapGestureRecognizer(target: self, action:
            #selector(self.previewToContentStack(gestureRecognize:)))
        preview.addGestureRecognizer(tapPreviewToStack!)
        
        
        configureGesturesForState(state: .view)
    }
    
    @objc func dismissKeyboard(tap: UITapGestureRecognizer) {
        let grid = contentStack.arrangedSubviews[contentStack.subviews.count - 1]
        grid.endEditing(true)
   
        editBoard.endEditing(true)
    }
    
    
    @objc func placeObject(gestureRecognize: UITapGestureRecognizer){
//        guard let obj = content else {
//            textManager.showMessage("Please select an output!!")
//            return
//        }
        if isGif {
            let cont = SKScene.makeSKSceneFromGif(data: (content?.data)!, size: CGSize(width: sceneView.frame.width, height: sceneView.frame.height))
            createNode(content: cont)
        }else {
            let cont = SKScene.makeSKSceneFromImage(image: input!,
                                                       size: CGSize(width: sceneView.frame.width, height: sceneView.frame.height))
            createNode(content: cont)
        }
        // Set content
//        if (obj.type == .gif) { // content is gif
//            guard let data = obj.data else {return}
//            let content = SKScene.makeSKSceneFromGif(data: data, size:  CGSize(width: sceneView.frame.width, height: sceneView.frame.height))
//            createNode(content: content)
//        } else { // content is picture
//            guard let data = obj.data else {return}
//            let content = SKScene.makeSKSceneFromImage(data: data,
//                                                       size: CGSize(width: sceneView.frame.width, height: sceneView.frame.height))
//            createNode(content: content)
//        }
        
        // ----------------------------------------------------------------------------------------------------
        
        //        //file:///var/mobile/Media/PhotoStreamsData/1020202307/100APPLE/IMG_0153.JPG
        //        let obj = NSURL(string: "assets-library://asset/asset.JPG?id=EA05C3C1-0FE4-43B9-8A10-2AE932CDDE4D&ext=JPG")
        //        let content = SKScene.makeSKSceneFromImage(url: obj!,
        //                                                   size: CGSize(width: sceneView.frame.width, height: sceneView.frame.height))
        //        createNode(content: content)
        
    }
    
    @objc func darkenObject(shortPress: UILongPressGestureRecognizer) {
        var skScene: SKScene?
        
        if shortPress.state == .began {
            let point = shortPress.location(in: view)
            let scnHitTestResults = sceneView.hitTest(point, options: nil)
            if let result = scnHitTestResults.first {
                skScene = result.node.geometry?.firstMaterial?.diffuse.contents as? SKScene
                let darken = SKAction.colorize(with: .black, colorBlendFactor: 0.4, duration: 0)
                skScene!.childNode(withName: "content")?.run(darken)
            }
        }
        
        if shortPress.state == UIGestureRecognizerState.ended{
            if !longPressDeleteFired {
                let point = shortPress.location(in: view)
                let scnHitTestResults = sceneView.hitTest(point, options: nil)
                if let result = scnHitTestResults.first {
                    skScene = result.node.geometry?.firstMaterial?.diffuse.contents as? SKScene
                    let darken = SKAction.colorize(with: .black, colorBlendFactor: 0, duration: 0)
                    skScene!.childNode(withName: "content")?.run(darken)
                }
            }
        }
    }
    
    @objc func initiateDeletion(longPress:UILongPressGestureRecognizer) {
        if longPress.state == .began {
            longPressDeleteFired = true
            
            // hit test
            let point = longPress.location(in: view)
            let scnHitTestResults = sceneView.hitTest(point, options: nil)
            if let result = scnHitTestResults.first {
                let geometry = result.node.geometry! as! SCNPlane
                
                // Add delete button
                let skScene = geometry.firstMaterial?.diffuse.contents as! SKScene
                let delete = SKSpriteNode.init(imageNamed: "delete.png")
                delete.name = "delete"
                delete.size = CGSize.init(width: skScene.frame.width * 0.15, height: skScene.frame.width * 0.15)
                delete.position = CGPoint.init(x: skScene.frame.width * 0.90, y: skScene.frame.height * 0.90)
                delete.isUserInteractionEnabled = true
                skScene.addChild(delete)
                
                
                configureGesturesForState(state: .delete)
                
                // Delete - Tap gesture recognizer change
                //                tapDelete = UITapGestureRecognizer(target: self, action:
                //                    #selector(self.deleteNode(tap:)))
                target = result.node
                //                view.addGestureRecognizer(tapDelete!)
                
                // Vibrate phone
                AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
            }
        }
        
        //*undarken
        if longPress.state == .ended {
            let point = longPress.location(in: view)
            let scnHitTestResults = sceneView.hitTest(point, options: nil)
            if let result = scnHitTestResults.first {
                let geometry = result.node.geometry! as! SCNPlane
                let skScene = geometry.firstMaterial?.diffuse.contents as! SKScene
                let darken = SKAction.colorize(with: .black, colorBlendFactor: 0.4, duration: 0)
                skScene.childNode(withName: "content")?.run(darken)
            }
        }
    }

    @objc func deleteNode(tap: UITapGestureRecognizer) {
        guard let node = target else {
            return
        }
        let skScene = node.geometry?.firstMaterial?.diffuse.contents as! SKScene
        let deleteButton = skScene.childNode(withName: "delete")
        
        let point = tap.location(in: view)
        skScene.view?.hitTest(point, with: nil)
        
        let scnHitTestResults = sceneView.hitTest(point, options: nil)
        if let result = scnHitTestResults.first {
            
            let currentNode = result.node
            if (currentNode == node && deleteIsClicked(localCoordinates: result.localCoordinates)){
                deleteButton?.removeFromParent()
                currentNode.removeFromParentNode()
                if preview.isHidden {
                    configureGesturesForState(state: .view)
                } else {
                    configureGesturesForState(state: .place)
                }
                
                longPressDeleteFired = false
                
                // MARK: Andreas' code to delete a node from db
                
                let nodeID : String = currentNode.name!
                print("Node Id: \(nodeID)")
                
                // Code to remove node from db
                let storageRef = Storage.storage().reference()
                let databaseRef = Database.database().reference()
                let outsideGroup = DispatchGroup()
                
                //access node
                databaseRef.child("/nodes/\(nodeID)/").observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists() {
                        outsideGroup.enter()
                        // remove node from root
                        let nodeDict = snapshot.value as! NSDictionary
                        
                        var rootID : String = ""
                        var userID : String = ""
                        var picID : String = ""
                        var nodeDist : Double = 0.0
                        for (key, value) in nodeDict {
                            if (key as? String == "root") {
                                rootID = value as! String
                            } else if (key as? String == "user") {
                                userID = value as! String
                            } else if (key as? String == "picture") {
                                picID = value as! String
                            }else if (key as? String == "distance") {
                                nodeDist = value as! Double
                            } else {
                            }
                        }
                        
                        databaseRef.child("/roots/\(rootID)").observeSingleEvent(of: .value, with: { (snapshot) in
                            let rootDict = snapshot.value as! NSDictionary
                            var dbNodes : NSDictionary = ["":true]
                            var dbRadius : Double = 0.0
                            for (key, value) in rootDict {
                                if (key as? String == "nodes") {
                                    dbNodes = value as! NSDictionary
                                } else if (key as? String == "radius") {
                                    dbRadius = value as! Double
                                }
                            }
                            
                            let group = DispatchGroup()
                            
                            // Update the radius of the root
                            if dbNodes.count == 1 {
                                databaseRef.child("/roots/\(rootID)/radius").setValue(0.0)
                            } else if nodeDist != dbRadius {
                                // Don't need to change the radius if this node is not the max radius
                            } else {
                                var nodeRadius = 0.0
                                
                                for (nodeID,_) in dbNodes {
                                    group.enter()
                                    databaseRef.child("/nodes/\(nodeID)").observeSingleEvent(of: .value, with: { (snapshot) in
                                        let allNodesDict = snapshot.value as! NSDictionary
                                        
                                        var givenNodeDist : Double = 0.0
                                        for (key, value) in allNodesDict {
                                            if (key as? String == "distance") {
                                                givenNodeDist = value as! Double
                                                break
                                            }
                                        }
                                        if givenNodeDist > nodeRadius {
                                            nodeRadius = givenNodeDist
                                        }
                                        group.leave()
                                    })
                                }
                                // Set the new radius of root
                                group.notify(queue: .main) {
                                    databaseRef.child("/roots/\(rootID)/radius").setValue(nodeRadius)
                                }
                            }
                            
                            // remove the node from the root
                            databaseRef.child("/roots/\(rootID)/nodes/\(nodeID)").removeValue { error,_  in
                                if error != nil {
                                    print("error \(error!)")
                                }
                            }
                        })
                        
                        // remove node from user
                        databaseRef.child("/users/\(userID)/lastPicture").removeValue { error,_ in
                            if error != nil {
                                print("error \(error!)")
                            }
                        }
                        
                        // remove pic
                        databaseRef.child("/pictures/\(picID)").removeValue { error,_ in
                            if error != nil {
                                print("error \(error!)")
                            }
                        }
                        
                        // remove pic from storage
                        let picRef = storageRef.child("/pictures/").child(picID)
                        picRef.delete { error in
                            if let error = error {
                                print("Error occurred: \(error)")
                            } else {
                                // File deleted successfully
                            }
                        }
                        outsideGroup.leave()
                        
                        outsideGroup.notify(queue: .main) {
                            // remove node
                            databaseRef.child("/nodes/\(nodeID)").removeValue { error,_ in
                                if error != nil {
                                    print("error \(error!)")
                                }
                                print("removed Node")
                            }
                        }
                    } else {
                        print("removenode snapshot empty")
                    }
                })
                
            } else {
                // Cancel deletion process if user taps out
                deleteButton?.removeFromParent()
                if preview.isHidden {
                    configureGesturesForState(state: .view)
                } else {
                    configureGesturesForState(state: .place)
                }
                // Undarken
                let undarken = SKAction.colorize(with: .black, colorBlendFactor: 0, duration: 0)
                skScene.childNode(withName: "content")?.run(undarken)
                longPressDeleteFired = false
            }
        } else {
            // Cancel deletion process if user taps out
            deleteButton?.removeFromParent()
            if preview.isHidden {
                configureGesturesForState(state: .view)
            } else {
                configureGesturesForState(state: .place)
            }
            // Undarken
            let undarken = SKAction.colorize(with: .black, colorBlendFactor: 0, duration: 0)
            skScene.childNode(withName: "content")?.run(undarken)
            longPressDeleteFired = false
        }
    }
    
    @objc func dismissContentStack(gestureRecognize: UITapGestureRecognizer){
        let point = gestureRecognize.location(in: view)
        let safety = CGFloat(10.0)
        
        if point.y < (contentStack.frame.origin.y - safety) {
            hideContentStack()
        }
    }
    
    // MARK :- Delegates
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UILongPressGestureRecognizer &&
            otherGestureRecognizer is UILongPressGestureRecognizer {
            return true
        }
        return false
    }

    
}
