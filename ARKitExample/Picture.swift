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
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

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
        // *** uncomment below code for choosing picture ***
//        importImageFromGallery()
//                guard let picture = image else{
//                    print("found error")
//                    return
//                }

        // *** comment out the line below later - its hard coded
        let picture = UIImage(named: "sample")
                print("here2")
                // Change size of image here
                // ViewController.sceneView.bounds.width / 7000
                let imagePlane = SCNPlane(width: width,height: height)
                imagePlane.firstMaterial?.diffuse.contents = picture
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
                wrapperNode.simdEulerAngles.y = currentFrame.camera.eulerAngles.y
                // Add as child node
                self.addChildNode(wrapperNode)

                modelLoaded = true
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

        // Change size of image here
        // ViewController.sceneView.bounds.width / 7000
        let imagePlane = SCNPlane(width: width,height: height)
        imagePlane.firstMaterial?.diffuse.contents = image
        imagePlane.firstMaterial?.lightingModel = .constant

        // Create wrapper node for image
        let wrapperNode = SCNNode()
        wrapperNode.geometry = imagePlane

        // Change rotation and orientation
        wrapperNode.rotation = SCNVector4.init(1, 0, 0, CGFloat.pi * 3/2)
        guard let currentFrame = viewController?.session.currentFrame else {
            return
        }
        wrapperNode.simdEulerAngles.y = currentFrame.camera.eulerAngles.y

        // Add as child node
        self.addChildNode(wrapperNode)

        modelLoaded = true


        self.viewController?.dismiss(animated: true, completion: nil)

        // MARK: Andreas's Code

        // Save Node and Pictures to Database
        var data = Data()
        data = UIImageJPEGRepresentation(image!, 0.8)!

        var databaseRef: DatabaseReference!
        databaseRef = Database.database().reference()

        let storageRef = Storage.storage().reference()

        let metaData = StorageMetadata()
        metaData.contentType = "image/jpg"

        let userID = Auth.auth().currentUser!.uid
        let sessionID = viewController!.currentSessionID
        let picID = databaseRef.child("/pictures/").childByAutoId().key
        let nodeID = databaseRef.child("/nodes/").childByAutoId().key

        let picturesRef = storageRef.child("/pictures/\(picID)")

        let uploadTask = picturesRef.putData(data, metadata: metaData) { (metadata, error) in
            if let error = error {
                // Uh-oh, an error occurred!
                print(error)
                return
            } else {
                // Metadata contains file metadata such as size, content-type, and download URL.
                let downloadURL = metadata!.downloadURL()!.absoluteString
                // format date type to string
                let date = metadata!.timeCreated!
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
                dateFormatter.locale = Locale(identifier: "en_US")
                let timestamp = dateFormatter.string(from:date as Date)
                // check if node distance is new radius
                let newDistance = 5.0
//                CHANGE THIS TO THE ACTUAL NODE'S DISTANCE BASED ON VARIABLE NAME
//                    object.position.length()

                let sessionsRef = databaseRef.child("/sessions/\(sessionID)")
                sessionsRef.observeSingleEvent(of: .value, with: { (snapshot) in
                    let currSession = snapshot.valueInExportFormat() as! NSDictionary

                    var currRadius : Double = 0.0
                    for (key, value) in currSession {
                        if (key as? String == "radius") {
                            currRadius = value as! Double
                        }
                    }

                    if newDistance > currRadius {
                        let sessionChildUpdates: [String: Any] = ["/sessions/\(sessionID)/radius": newDistance]
                        databaseRef.updateChildValues(sessionChildUpdates)
                    }
                })

                //store downloadURL at database
                let picture: [String: Any] = ["url": downloadURL, "timestamp": timestamp, "users": [userID], "nodes": [nodeID]]
                let picChildUpdates: [String: Any] = ["/pictures/\(picID)": picture, "/users/\(userID)/lastPicture": picID]
                databaseRef.updateChildValues(picChildUpdates)
                let node : [String : Any] = ["distance": newDistance, "timestamp": timestamp, "pictures": [picID]]
                let nodeChildUpdates: [String: Any] = ["/nodes/\(nodeID)": node, "/sessions/\(sessionID)/nodes/": nodeID]
                databaseRef.updateChildValues(nodeChildUpdates)
            }
        }

        //-------------

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
