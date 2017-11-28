/*
 See LICENSE folder for this sample’s licensing information.

 Abstract:
 Main view controller for the AR experience.
 */

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

class ViewController: UIViewController, ARSCNViewDelegate, UIPopoverPresentationControllerDelegate,  CLLocationManagerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate {

    var cubeUpdateRef: DatabaseReference!
    var cubeUpdateHandlerArr: [UInt] = [UInt]()
    var locationManager = CLLocationManager()
    var rootNodeLocation = CLLocation()
    var currentLocation = CLLocation()
    var currentRootID : String = ""
    var deleteMode: Bool = false
    var longPressDelete: UILongPressGestureRecognizer?
    var longPressDarken: UILongPressGestureRecognizer?
    var tapPreviewToStack : UITapGestureRecognizer?
    var content : Content?
    var cube: Cube?
    lazy var stdLen: CGFloat = {
        let len = self.sceneView.bounds.height / 3000
        return len
    }()
    /// Properties that keeps track of the location where the drop operation was performed & the transform
    var dropPoint = CGPoint.zero
    var dropPointTransform = CGAffineTransform.identity
    
    let profButton : UIButton = {
        let button = UIButton(frame: CGRect(x: 100, y: 100, width: 300, height: 300))
//        let button = UIButton()
        button.setBackgroundImage(UIImage.init(named: "prof"), for: UIControlState.normal)
        button.contentMode = .scaleAspectFit
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(clickProf), for: .touchUpInside)
        return button
    }()
    
    @objc func clickProf() {
        let profileStoryboard: UIStoryboard = UIStoryboard(name: "Profile", bundle: nil)
        let profileViewController = profileStoryboard.instantiateViewController(withIdentifier: "ProfileViewController")
        present(profileViewController, animated: true, completion: nil)
    }

    // MARK: - Main Setup & View Controller methods
    override func viewDidLoad() {
        super.viewDidLoad()

        Setting.registerDefaults()
        setupScene()
        setupDebug()
        setupUIControls()
        setupLocationSettings()
		updateSettings()
		resetVirtualObject()
        setupMenuBar()
        setupGestures()
        setupPreview()
        
        view.addSubview(profButton)
        profButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 15).isActive = true
        profButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 15).isActive = true

        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        // ---
        settingsButton.isHidden = true
//        restartExperienceButton.isHidden = true
//        screenshotButton.isHidden = true
        
        // ---
    }

    let preview = UIImageView()
    func setupPreview() {
        preview.backgroundColor = UIColor.black
        view.addSubview(preview)

        let viewWidth = view.frame.width
        let viewHeight = view.frame.height
        let previewWidth = CGFloat(80)
        let previewHeight = CGFloat(80 )
        let bottomMargin = CGFloat(15)

        view.addConstraintsWithFormat("H:|-\((viewWidth - previewWidth)/2)-[v0]-\((viewWidth - previewWidth)/2)-|", views: preview)
        view.addConstraintsWithFormat("V:|-\(viewHeight - bottomMargin - previewHeight)-[v0]-\(bottomMargin)-|", views: preview)

        preview.isHidden = true
        preview.isUserInteractionEnabled = true
    }
    @objc func previewToContentStack(gestureRecognize: UITapGestureRecognizer) {
        hidePreview()
        
        // edit the image
        let data = UIImagePNGRepresentation(preview.image!)!
        if content?.type == .image {
            openPhotoEditor(data: data)
        }
        
        showContentStack()
    }

    func showContentStack() {
        contentStack.isHidden = false
        configureGesturesForState(state: .selection)
    }

    func showPreview() {
//        guard let content = self.content else {
//            return
//        }
//        if content.type == .gif {
//            if let data = content.data {
//                preview.image = UIImage.gif(data: data)
//            }
//        } else {
//            if let data = content.data {
//                preview.image = UIImage(data: data)
//            }
//        }

        configureGesturesForState(state: .place)
        contentStackButton.isEnabled = false
        contentStackHitArea.isEnabled = false
        preview.isHidden = false
    }
    func hidePreview() {
        preview.isHidden = true
        contentStackButton.isEnabled = true
        contentStackHitArea.isEnabled = true
    }

    var contentStackBotAnchor : NSLayoutConstraint?
    @objc func keyboardWillShow(notification: NSNotification) {
        configureGesturesForState(state: .keyboard)
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue{
            print(keyboardSize)
            if let constraint = contentStackBotAnchor {
            let topLeftPos = view.frame.height - contentStack.frame.origin.y
            if topLeftPos == contentStack.frame.height{
//                stack.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = false
////                stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -keyboardSize.height).isActive = true
//                self.stack.frame.origin.y -= keyboardSize.height
                UIView.animate(withDuration: 1.5, animations: {
//                    constraint.constant = -keyboardSize.height
                    // TODO: SoftCode this
                    constraint.constant = -226.0
                    self.view.layoutIfNeeded()
                })
            }
            }
        }
    }
    @objc func keyboardWillHide(notification: NSNotification) {
        configureGesturesForState(state: .selection)
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue{
            if let constraint = contentStackBotAnchor{
            let topLeftPos = view.frame.height - contentStack.frame.origin.y
            if topLeftPos != contentStack.frame.height{
//                self.contentStack.frame.origin.y += keyboardSize.height
////                stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -keyboardSize.height).isActive = false
//                contentStack.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
                UIView.animate(withDuration: 1.5, animations: {
                    constraint.constant = 0
                    self.view.layoutIfNeeded()
                })
            }
            }
        }
    }

    enum ContentType {
        case plain
        case library
        case meme
        case gif
    }

    let contentStack = UIStackView()
    let plainGrid = PlainGrid()
    let libraryGrid = LibraryGrid()
    let memeGrid = MemeGrid()
    let gifGrid = GifGrid()
    func setupMenuBar() {
        let menuBar = MenuBar()
        menuBar.viewController = self
        libraryGrid.viewController = self
        memeGrid.viewController = self
        gifGrid.viewController = self
        plainGrid.viewController = self

        let container = UIView()
        container.addSubview(libraryGrid)
        container.addConstraintsWithFormat("H:|[v0]|", views: libraryGrid)
        container.addConstraintsWithFormat("V:|[v0]|", views: libraryGrid)
        container.addSubview(memeGrid)
        container.addConstraintsWithFormat("H:|[v0]|", views: memeGrid)
        container.addConstraintsWithFormat("V:|[v0]|", views: memeGrid)
        container.addSubview(gifGrid)
        container.addConstraintsWithFormat("H:|[v0]|", views: gifGrid)
        container.addConstraintsWithFormat("V:|[v0]|", views: gifGrid)
        container.addSubview(plainGrid)
        container.addConstraintsWithFormat("H:|[v0]|", views: plainGrid)
        container.addConstraintsWithFormat("V:|[v0]|", views: plainGrid)

        contentStack.addArrangedSubview(menuBar)
        contentStack.addArrangedSubview(container)

        view.addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStackBotAnchor = contentStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        contentStackBotAnchor!.isActive = true
        contentStack.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        contentStack.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        contentStack.axis = .vertical
        contentStack.spacing = 0

        contentStack.isHidden = true
    }
    func showGrid(type : ContentType) {
        let grid = contentStack.subviews[1]
        if type == .plain {
            grid.bringSubview(toFront: plainGrid)
        } else if type == .library {
            grid.bringSubview(toFront: libraryGrid)
        } else if type == .meme {
            grid.bringSubview(toFront: memeGrid)
        } else {
            grid.bringSubview(toFront: gifGrid)
        }
    }

    let minimumZoom: CGFloat = 1.0
    let maximumZoom: CGFloat = 3.0
    var lastZoomFactor: CGFloat = 1.0
    func setupGestures() {
        // Add drop interaction
        let dropInteraction = UIDropInteraction(delegate: self)
        sceneView.addInteraction(dropInteraction)
        
        // Add drag interaction
        let dragInteraction = UIDragInteraction(delegate: self)
        dragInteraction.isEnabled = true
        preview.addInteraction(dragInteraction)
        
        // Add cube rotation
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(didRotate(_:)))
        rotationGesture.delegate = self
        rotationGesture.isEnabled = true
        sceneView.addGestureRecognizer(rotationGesture)

        // Add zoom to camera
        let zoomGesture = UIPinchGestureRecognizer(target: self, action: #selector(didPinch(_:)))
        zoomGesture.delegate = self
        sceneView.addGestureRecognizer(zoomGesture)
        
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

    // MARK: - Gesture Recognizers
    var tapDismissKeyboard : UITapGestureRecognizer?
    @objc func dismissKeyboard(tap: UITapGestureRecognizer) {
        let grid = contentStack.arrangedSubviews[1]
        grid.endEditing(true)
    }
    
    // Load Prev Obj
    func loadImage(_ itemProvider: NSItemProvider, nodeName: String) {
        itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
            DispatchQueue.global(qos: .background).async {
                //let image = object as! UIImage
                let content = self.content!
                self.newPictureView(content: content, nodeName: nodeName)
            }
        }
    }
    
    func newPictureView(content: Content, nodeName: String) {
        
        // Set content and for now no gif
        if (content.type == .gif) { // content is gif
            guard let data = content.data else {return}
            let sk = SKScene.makeSKSceneFromGif(data: data, size:  CGSize(width: sceneView.frame.width, height: sceneView.frame.height))
            editNode(content: sk, nodeName: nodeName)
            
            DispatchQueue.global(qos: .background).async {
                // save node in backend
                self.saveNode(nodeName: nodeName)
            }
        } else {
            // content is picture
            guard let data = content.data else {return}
            let sk = SKScene.makeSKSceneFromImage(data: data,
                                                           size: CGSize(width: sceneView.frame.width, height: sceneView.frame.height))
            editNode(content: sk, nodeName: nodeName)
            
            DispatchQueue.global(qos: .background).async {
                // save node in backend
                self.saveNode(nodeName: nodeName)
            }
        }
    }
    
    // fading objects on dragging and dropping
    func fade(items: [UIDragItem], alpha: CGFloat) {
        for item in items {
            if let nodeName = item.localObject as? String {
                let childNode = sceneView.scene.rootNode.childNode(withName: nodeName, recursively: true)!
                let view = childNode.geometry?.firstMaterial?.diffuse.contents as? UIImageView
                view?.alpha = alpha
            }
        }
    }

    func editNode(content: SKScene, nodeName: String) {
        let pix = SCNPlane(width: 2/4, height: 2/4)
        pix.firstMaterial?.diffuse.contents = content
        pix.firstMaterial?.lightingModel = .constant
        
        let targetNode = sceneView.scene.rootNode.childNode(withName: nodeName, recursively: true)
        targetNode?.geometry = pix
    }
    
    func saveNode(nodeName: String) {

        // Save Node and Pictures to Database
        let data = content?.data
        
        var databaseRef: DatabaseReference!
        databaseRef = Database.database().reference()

        let storageRef = Storage.storage().reference()

        let metaData = StorageMetadata()
        let input : NSData = NSData(data: data!)
        if input.imageFormat == .JPEG {
            metaData.contentType = "image/jpeg"
        } else if input.imageFormat == .PNG {
            metaData.contentType = "image/png"
        } else if input.imageFormat == .TIFF {
            metaData.contentType = "image/tiff"
        } else if input.imageFormat == .GIF {
            metaData.contentType = "image/gif"
        } else {
            print("not acceptable format of media")
        }

        let userID = Auth.auth().currentUser!.uid
        let rootID = self.currentRootID
        let picID = databaseRef.child("/pictures/").childByAutoId().key
        let nodeID = databaseRef.child("/nodes/").childByAutoId().key

        //come back
        
        let picturesRef = storageRef.child("/pictures/\(picID)")

        picturesRef.putData(data!, metadata: metaData) { (metadata, error) in
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

                //store downloadURL at database
                let picture: [String: Any] = ["url": downloadURL, "timestamp": timestamp]
                let picChildUpdates: [String: Any] = ["/pictures/\(picID)": picture,
                                                      "/users/\(userID)/lastPicture": picID,
                                                      "/users/\(userID)/pictures/\(picID)": true]
                databaseRef.updateChildValues(picChildUpdates)
                databaseRef.child("/pictures/\(picID)/nodes/\(nodeID)").setValue(true);
                databaseRef.child("/pictures/\(picID)/users/\(userID)").setValue(true);
                
                let node : [String : Any] = ["cube_pos": nodeName,
                                             "picture": picID,
                                             "root": rootID,
                                             "user": userID,
                                             "timestamp": timestamp]
                let nodeChildUpdates: [String: Any] = ["/nodes/\(nodeID)": node]
                databaseRef.updateChildValues(nodeChildUpdates)
                databaseRef.child("/roots/\(rootID)/nodes/\(nodeID)").setValue(true);
                
                // assumes only four sides for side Index
                let sideIndex = nodeName.index(nodeName.endIndex, offsetBy: -1)
                let pixIndex = nodeName.index(nodeName.startIndex, offsetBy: 3)
                let pixIndex2 = nodeName.index(nodeName.startIndex, offsetBy: 5)
                let side = nodeName[sideIndex]
                var pix = String(nodeName[pixIndex ..< pixIndex2])
                if pix.contains("s") {
                    pix = String(nodeName[pixIndex])
                }
                let pixPic : [String: Any] = ["picture": picID]
                if let school = self.cube?.school, let sub_cube = self.cube?.sub_cube {
                    let cubeChildUpdates: [String: Any] = ["/cubes/\(school)/\(sub_cube)/side\(side)/pix\(pix)": pixPic]
                    databaseRef.updateChildValues(cubeChildUpdates)
                }
            }
        }
    }

    // Deleting Object
    var longPressDeleteFired: Bool = false
    @objc func darkenObject(shortPress: UILongPressGestureRecognizer) {
        var skScene: SKScene?

        if shortPress.state == .began {
            let point = shortPress.location(in: view)
            let scnHitTestResults = sceneView.hitTest(point, options: nil)
            if let result = scnHitTestResults.first {
                print(result.node.name!)
                if result.node.name != "distinct_cube" && result.node.name?.range(of:"pix") == nil && result.node.name?.range(of:"side") == nil {
                    skScene = result.node.geometry?.firstMaterial?.diffuse.contents as? SKScene
                    let darken = SKAction.colorize(with: .black, colorBlendFactor: 0.4, duration: 0)
                    skScene!.childNode(withName: "content")?.run(darken)
                }
            }
        }

        if shortPress.state == UIGestureRecognizerState.ended{
            if !longPressDeleteFired {
                let point = shortPress.location(in: view)
                let scnHitTestResults = sceneView.hitTest(point, options: nil)
                if let result = scnHitTestResults.first {
                    if result.node.name != "distinct_cube" && result.node.name?.range(of:"pix") == nil && result.node.name?.range(of:"side") == nil {
                        skScene = result.node.geometry?.firstMaterial?.diffuse.contents as? SKScene
                        let darken = SKAction.colorize(with: .black, colorBlendFactor: 0, duration: 0)
                        skScene!.childNode(withName: "content")?.run(darken)
                    }
                }
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Prevent the screen from being dimmed after a while.
        UIApplication.shared.isIdleTimerDisabled = true

        // Start the ARSession.
        restartPlaneDetection()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        DispatchQueue.main.async {
            self.stopUpdatingCubeImages()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        session.pause()

    }

    // MARK: - Firebase Initialization
    func setupFirebase() {

        // Initialize Firebase Database
        let databaseRef = Database.database().reference()

        // Format Date into String
        let rootTime = rootNodeLocation.timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        dateFormatter.locale = Locale(identifier: "en_US")
        let timestamp = dateFormatter.string(from:rootTime as Date)
        
        determineSchool(coordinate: rootNodeLocation)

        // Add root to Roots
        let dbRoot: [String: Any] = [
            "latitude": rootNodeLocation.coordinate.latitude,
            "longitude": rootNodeLocation.coordinate.longitude,
            "altitude": rootNodeLocation.altitude,
            "horizontalAccuracy": rootNodeLocation.horizontalAccuracy,
            "verticalAccuracy": rootNodeLocation.verticalAccuracy,
            "timestamp": timestamp,
            "radius":  0.0,
        ]
        currentRootID = databaseRef.child("roots").childByAutoId().key
        databaseRef.child("roots/\(currentRootID)/").setValue(dbRoot)
        databaseRef.child("/roots/\(currentRootID)/users/\(Auth.auth().currentUser!.uid)").setValue(true);

        let userChildUpdates: [String: Any] = ["/users/\(Auth.auth().currentUser!.uid)/lastRoot": currentRootID]
        databaseRef.updateChildValues(userChildUpdates)
        self.locationManager.stopUpdatingLocation()
    }
    
    func determineSchool(coordinate: CLLocation) {
        let berkeleyLOC = CLLocation.init(latitude: 37.8719, longitude: -122.2585)
        let stanfordLOC = CLLocation.init(latitude: 37.4275, longitude: -122.1697)
        let princetonLOC = CLLocation.init(latitude: 40.3440, longitude: -74.6514)
        
        if (coordinate.distance(from: berkeleyLOC) / 1609.344) <= 3 {
            cube = Cube()
            cube?.school = "Berkeley"
            cube?.sub_cube = "sproul"
        } else if (coordinate.distance(from: stanfordLOC) / 1609.344) <= 3 {
            cube = Cube()
            cube?.school = "Stanford"
            cube?.sub_cube = "tresidder"
        } else if (coordinate.distance(from: princetonLOC) / 1609.344) <= 3 {
            cube = Cube()
            cube?.school = "Princeton"
            cube?.sub_cube = "frist"
        } else {
            
        }
    }
    
    // MARK: - Add Object to Post Images To
    // Drop down 3d object to scene
    func generateRandomColor() -> UIColor {
        let hue : CGFloat = CGFloat(arc4random() % 256) / 256 // use 256 to get full range from 0.0 to 1.0
        let saturation : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5 // from 0.5 to 1.0 to stay away from white
        let brightness : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5 // from 0.5 to 1.0 to stay away from black
        
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
    }
    
    func addPostObjectToScene() {
        
        //change this to box
        let box = SCNBox(width: 2.0, height: 2.0, length: 2.0, chamferRadius: 0)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red:0.00, green:0.25, blue:0.50, alpha:1.0)  //UIImage(named: "brick.jpg")
        box.materials = [material]
        let cubeNode = SCNNode(geometry: box)
        cubeNode.name = "distinct_cube"
        // place the cube askew to show 3D
        cubeNode.rotation = SCNVector4(0, 1, 0, (Float.pi * 1/4))
        cubeNode.position = SCNVector3(0, 0, -4.0)
        sceneView.scene.rootNode.addChildNode(cubeNode)
        
        // add four side of children (image planes?, skscnenes?)
        let side = SCNPlane(width: 2.0, height: 2.0)
        side.materials = [material]
        for i in 1...4 {
            let sideNode = SCNNode(geometry: side)
            sideNode.name = "side" + String(i)
            // this position shud be relative to parent
            if i == 1 {
                sideNode.position.z = 1.0 + 0.01
            } else if i == 2 {
                sideNode.position.x = -1.0 - 0.01
                sideNode.rotation.y = 1
                sideNode.rotation.w = Float(CGFloat.pi * 3/2)
            } else if i == 3 {
                sideNode.position.z = -1.0 - 0.01
                sideNode.rotation.y = 1
                sideNode.rotation.w = Float(CGFloat.pi)
            } else {
                sideNode.position.x = 1.0 + 0.01
                sideNode.rotation.y = 1
                sideNode.rotation.w = Float(CGFloat.pi * 1/2)
            }
            cubeNode.addChildNode(sideNode)
            for j in 1...16 {
                let pix = SCNPlane(width: (2/4), height: (2/4))
                
                pix.firstMaterial?.diffuse.contents = self.generateRandomColor()
                pix.firstMaterial?.lightingModel = .constant
                
                // add Node for each square
                let pixNode = SCNNode(geometry: pix)
                pixNode.name = "pix" + String(j) + sideNode.name!
                pixNode.position.z = 0.01
                if j == 1 {
                    pixNode.position.x = -(6/8)
                    pixNode.position.y = (6/8)
                } else if j == 2 {
                    pixNode.position.x = -(2/8)
                    pixNode.position.y = (6/8)
                } else if j == 3 {
                    pixNode.position.x = (2/8)
                    pixNode.position.y = (6/8)
                } else if j == 4 {
                    pixNode.position.x = (6/8)
                    pixNode.position.y = (6/8)
                } else if j == 5 {
                    pixNode.position.x = -(6/8)
                    pixNode.position.y = (2/8)
                } else if j == 6 {
                    pixNode.position.x = -(2/8)
                    pixNode.position.y = (2/8)
                } else if j == 7 {
                    pixNode.position.x = (2/8)
                    pixNode.position.y = (2/8)
                } else if j == 8 {
                    pixNode.position.x = (6/8)
                    pixNode.position.y = (2/8)
                } else if j == 9 {
                    pixNode.position.x = -(6/8)
                    pixNode.position.y = -(2/8)
                } else if j == 10 {
                    pixNode.position.x = -(2/8)
                    pixNode.position.y = -(2/8)
                } else if j == 11 {
                    pixNode.position.x = (2/8)
                    pixNode.position.y = -(2/8)
                } else if j == 12 {
                    pixNode.position.x = (6/8)
                    pixNode.position.y = -(2/8)
                } else if j == 13 {
                    pixNode.position.x = -(6/8)
                    pixNode.position.y = -(6/8)
                } else if j == 14 {
                    pixNode.position.x = -(2/8)
                    pixNode.position.y = -(6/8)
                } else if j == 15 {
                    pixNode.position.x = (2/8)
                    pixNode.position.y = -(6/8)
                } else {
                    pixNode.position.x = (6/8)
                    pixNode.position.y = -(6/8)
                }
                
                sideNode.addChildNode(pixNode)
            }
        }
    
        
//        let modelScene = SCNScene(named: "Models.scnassets/test/test.dae")!
//        print(modelScene.rootNode.childNodes)
//        let nodeModel = modelScene.rootNode.childNode(withName: "pCube1", recursively: true)!
//
//        // 10 cm in front of camera
//        var translation = matrix_identity_float4x4
//        translation.columns.3.z = -3.0
//        //rotate chair upright
//        var rotation = matrix_identity_float4x4
//        rotation.columns.0.x = Float(cos(CGFloat.pi * -3/2))
//        rotation.columns.0.y = Float(sin(CGFloat.pi * -3/2))
//        rotation.columns.1.x = Float(-sin(CGFloat.pi * -3/2))
//        rotation.columns.1.y = Float(cos(CGFloat.pi * -3/2))
//        nodeModel.simdTransform = matrix_multiply(matrix_multiply(currentFrame.camera.transform, translation), rotation)
//        sceneView.scene.rootNode.addChildNode(nodeModel)
    }


    // MARK: - Location Functions
    func setupLocationSettings() {
        locationManager.requestWhenInUseAuthorization()
        let authorizationStatus = CLLocationManager.authorizationStatus()
        if authorizationStatus != CLAuthorizationStatus.authorizedWhenInUse && authorizationStatus != CLAuthorizationStatus.authorizedAlways {
            // User has not authorized access to location information.
            return
        }
        // Do not start services that aren't available.
        if !CLLocationManager.locationServicesEnabled() {
            // Location services is not available.
            return
        }
        // Configure and start the service.

        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.activityType = CLActivityType.fitness

        //Start getting User Location
        DispatchQueue.main.async {
            self.locationManager.startUpdatingLocation()
        }
        print("getcurrentLocation in location settings: \(currentLocation)")
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        // check if it is accurate within 5 meters
        if (locations[locations.count-1].horizontalAccuracy < 0 || locations[locations.count-1].horizontalAccuracy > 100) {
            return;
        }
        let interval : TimeInterval = locations[locations.count-1].timestamp.timeIntervalSinceNow;
        //check against absolute value of the interval and if it was at most 29 seconds ago
        if (abs(interval)<30) {
            currentLocation = locations[locations.count-1] as CLLocation
            print("getcurrentLocation in locationmanager: \(currentLocation)")

            if rootNodeLocation.coordinate.latitude == 0 && rootNodeLocation.coordinate.longitude == 0 {
                rootNodeLocation = locations[locations.count-1] as CLLocation
                // Setup the firebase
                DispatchQueue.main.async {
                    self.setupFirebase()
                }
            }
            
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error while updating location:" + error.localizedDescription)
    }

    // MARK: - ARKit / ARSCNView
    let session = ARSession()
    var sessionConfig = ARWorldTrackingConfiguration()


    var use3DOFTracking = false {
        didSet {
            if use3DOFTracking {
                sessionConfig = ARWorldTrackingConfiguration()
            }
            sessionConfig.isLightEstimationEnabled = UserDefaults.standard.bool(for: .ambientLightEstimation)
//            sessionConfig.worldAlignment = .gravityAndHeading
            session.run(sessionConfig)

        }
    }
    var use3DOFTrackingFallback = false
    @IBOutlet var sceneView: ARSCNView!
    var screenCenter: CGPoint?

    func setupScene() {
        // set up sceneView
        sceneView.delegate = self
        sceneView.session = session
        sceneView.antialiasingMode = .multisampling4X
        sceneView.automaticallyUpdatesLighting = false
            // TODO: play with frames per second
        sceneView.preferredFramesPerSecond = 60
        sceneView.contentScaleFactor = 1.3
        //sceneView.showsStatistics = true

        enableEnvironmentMapWithIntensity(25.0)

        DispatchQueue.main.async {
            self.screenCenter = self.sceneView.bounds.mid
        }

        if let camera = sceneView.pointOfView?.camera {
            camera.wantsHDR = true
            camera.wantsExposureAdaptation = true
            camera.exposureOffset = -1
            camera.minimumExposure = -1
        }
    }

    func enableEnvironmentMapWithIntensity(_ intensity: CGFloat) {
        if sceneView.scene.lightingEnvironment.contents == nil {
            if let environmentMap = UIImage(named: "Models.scnassets/sharedImages/environment_blur.exr") {
                sceneView.scene.lightingEnvironment.contents = environmentMap
            }
        }
        sceneView.scene.lightingEnvironment.intensity = intensity
    }

    // MARK: - ARSCNViewDelegate

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        refreshFeaturePoints()

        DispatchQueue.main.async {
            self.hitTestVisualization?.render()

            // If light estimation is enabled, update the intensity of the model's lights and the environment map
            if let lightEstimate = self.session.currentFrame?.lightEstimate {
                self.enableEnvironmentMapWithIntensity(lightEstimate.ambientIntensity / 40)
            } else {
                self.enableEnvironmentMapWithIntensity(25)
            }
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
        }
    }

    var trackingFallbackTimer: Timer?

    var cubeNotSetup: Bool = true
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        textManager.showTrackingQualityInfo(for: camera.trackingState, autoHide: !self.showDebugVisuals)

        switch camera.trackingState {
        case .notAvailable:
            textManager.escalateFeedback(for: camera.trackingState, inSeconds: 5.0)
        case .limited:
            if use3DOFTrackingFallback {
                // After 10 seconds of limited quality, fall back to 3DOF mode.
                trackingFallbackTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false, block: { _ in
                    self.use3DOFTracking = true
                    self.trackingFallbackTimer?.invalidate()
                    self.trackingFallbackTimer = nil
                })
            } else {
                textManager.escalateFeedback(for: camera.trackingState, inSeconds: 10.0)
            }
        case .normal:
            textManager.cancelScheduledMessage(forType: .trackingStateEscalation)
            if use3DOFTrackingFallback && trackingFallbackTimer != nil {
                trackingFallbackTimer!.invalidate()
                trackingFallbackTimer = nil
            }
            // Add cube to scene
            DispatchQueue.global(qos: .background).async {
                if self.cubeNotSetup {
                    self.showCubeLoadingScreen()
                    self.startUpdatingCubeImages()
                    self.cubeNotSetup = false
                }
                DispatchQueue.global().async {
                    if self.sceneView.scene.rootNode.childNode(withName: "distinct_cube", recursively: true) == nil {
                        self.addPostObjectToScene()
                    }
                }
            }
        }
    }

    func session(_ session: ARSession, didFailWithError error: Error) {

        guard let arError = error as? ARError else { return }

        let nsError = error as NSError
        var sessionErrorMsg = "\(nsError.localizedDescription) \(nsError.localizedFailureReason ?? "")"
        if let recoveryOptions = nsError.localizedRecoveryOptions {
            for option in recoveryOptions {
                sessionErrorMsg.append("\(option).")
            }
        }

        let isRecoverable = (arError.code == .worldTrackingFailed)
        if isRecoverable {
            sessionErrorMsg += "\nYou can try resetting the session or quit the application."
        } else {
            sessionErrorMsg += "\nThis is an unrecoverable error that requires to quit the application."
        }

        displayErrorMessage(title: "We're sorry!", message: sessionErrorMsg, allowRestart: isRecoverable)
    }

    func sessionWasInterrupted(_ session: ARSession) {
        textManager.blurBackground()
        textManager.showAlert(title: "Session Interrupted", message: "The session will be reset after the interruption has ended.")
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        textManager.unblurBackground()
        session.run(sessionConfig, options: [.resetTracking, .removeExistingAnchors])
        restartExperience(self)
        textManager.showMessage("RESETTING SESSION")
    }

    // MARK: - Ambient Light Estimation

    func toggleAmbientLightEstimation(_ enabled: Bool) {

        if enabled {
            if !sessionConfig.isLightEstimationEnabled {
                // turn on light estimation
                sessionConfig.isLightEstimationEnabled = true
                session.run(sessionConfig)
            }
        } else {
            if sessionConfig.isLightEstimationEnabled {
                // turn off light estimation
                sessionConfig.isLightEstimationEnabled = false
                session.run(sessionConfig)
            }
        }
    }


    // MARK: - Picture Manipulation
    var obj: SCNNode?
    func displayVirtualObjectTransform() {

        guard let object = obj, let cameraTransform = session.currentFrame?.camera.transform else {
            return
        }

        // Output the current translation, rotation & scale of the virtual object as text.

        let cameraPos = SCNVector3.positionFromTransform(cameraTransform)
        let vectorToCamera = cameraPos - object.position
        let distanceToUser = vectorToCamera.length()

        var angleDegrees = Int(((object.eulerAngles.y) * 180) / Float.pi) % 360
        if angleDegrees < 0 {
            angleDegrees += 360
        }

        let distance = String(format: "%.2f", distanceToUser)
        let scale = String(format: "%.2f", object.scale.x)
        textManager.showDebugMessage("Distance: \(distance) m\nRotation: \(angleDegrees)°\nScale: \(scale)x")
    }

    var dragOnInfinitePlanesEnabled = false



    // Use average of recent virtual object distances to avoid rapid changes in object scale.
    var recentVirtualObjectDistances = [CGFloat]()

    func setNewVirtualObjectPosition(_ pos: SCNVector3) {

        guard let object = obj, let cameraTransform = session.currentFrame?.camera.transform else {
            return
        }

        recentVirtualObjectDistances.removeAll()

        let cameraWorldPos = SCNVector3.positionFromTransform(cameraTransform)
        var cameraToPosition = pos - cameraWorldPos

        // Limit the distance of the object from the camera to a maximum of 10 meters.
        cameraToPosition.setMaximumLength(10)

        object.position = cameraWorldPos + cameraToPosition

        if object.parent == nil {
            sceneView.scene.rootNode.addChildNode(object)
        }
    }

    var picture: Picture?

    func resetVirtualObject() {
//        obj?.unload()
        obj?.removeFromParentNode()
        picture = nil

        addObjectButton.setImage(#imageLiteral(resourceName: "add"), for: [])
        addObjectButton.setImage(#imageLiteral(resourceName: "addPressed"), for: [.highlighted])

        // Reset selected object id for row highlighting in object selection view controller.
        UserDefaults.standard.set(-1, for: .selectedObjectID)
    }

    func updateVirtualObjectPosition(_ pos: SCNVector3, _ filterPosition: Bool) {
        //        guard let object = element else {
        //            return
        //        }
        //
        //        guard let cameraTransform = session.currentFrame?.camera.transform else {
        //            return
        //        }
        //
        //        let cameraWorldPos = SCNVector3.positionFromTransform(cameraTransform)
        //        var cameraToPosition = pos - cameraWorldPos
        //
        //        // Limit the distance of the object from the camera to a maximum of 10 meters.
        //        cameraToPosition.setMaximumLength(10)
        //
        //        // Compute the average distance of the object from the camera over the last ten
        //        // updates. If filterPosition is true, compute a new position for the object
        //        // with this average. Notice that the distance is applied to the vector from
        //        // the camera to the content, so it only affects the percieved distance of the
        //        // object - the averaging does _not_ make the content "lag".
        //        let hitTestResultDistance = CGFloat(cameraToPosition.length())
        //
        //        recentVirtualObjectDistances.append(hitTestResultDistance)
        //        recentVirtualObjectDistances.keepLast(10)
        //
        //        if filterPosition {
        //            let averageDistance = recentVirtualObjectDistances.average!
        //
        //            cameraToPosition.setLength(Float(averageDistance))
        //            let averagedDistancePos = cameraWorldPos + cameraToPosition
        //
        //            object.position = averagedDistancePos
        //        } else {
        //            object.position = cameraWorldPos + cameraToPosition
        //        }
    }

    // MARK: - Virtual Object Loading

    var isLoadingObject: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.settingsButton.isEnabled = !self.isLoadingObject
                self.addObjectButton.isEnabled = !self.isLoadingObject
                self.screenshotButton.isEnabled = !self.isLoadingObject
                self.restartExperienceButton.isEnabled = !self.isLoadingObject
            }
        }
    }

    @IBOutlet weak var addObjectButton: UIButton!

    var objLocation: Location?
    func loadVirtualObject(at index: Int) {
        resetVirtualObject()

        // Show progress indicator
        let spinner = UIActivityIndicatorView()
        spinner.center = addObjectButton.center
        spinner.bounds.size = CGSize(width: addObjectButton.bounds.width - 5, height: addObjectButton.bounds.height - 5)
        addObjectButton.setImage(#imageLiteral(resourceName: "buttonring"), for: [])
        sceneView.addSubview(spinner)
        spinner.startAnimating()

        // Load the content asynchronously.
        DispatchQueue.global().async {
            self.isLoadingObject = true
            // hard coded
            let object = Picture.init(fileName: "sample", width: 0.2, height: 0.2)
            object.viewController = self
            self.obj = object
            object.load()


            // MARK ERROR - FIX THIS
            // create Location Object for picture
            guard let cameraTransform = self.session.currentFrame?.camera.transform, let camLocation = self.currentLocation as CLLocation? else {
                return
            }
            self.objLocation = Location.init(picture: object, cameraLocation: camLocation, cameraTransform: cameraTransform)
            print("create Location")
            print(self.objLocation!.cameraLocation())

            DispatchQueue.main.async {

                // Remove progress indicator
                spinner.removeFromSuperview()

                // Update the icon of the add object button
                //                let buttonImage = UIImage.composeButtonImage(from: object.thumbImage)
                //                let pressedButtonImage = UIImage.composeButtonImage(from: object.thumbImage, alpha: 0.3)
                //                self.addObjectButton.setImage(buttonImage, for: [])
                //                self.addObjectButton.setImage(pressedButtonImage, for: [.highlighted])
                self.isLoadingObject = false
            }
        }
    }

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

            tapDismissContentStack?.isEnabled = false
            tapDismissKeyboard?.isEnabled = false
            tapPreviewToStack?.isEnabled = false
        } else if state == .selection {
            tapDismissContentStack?.isEnabled = true

            longPressDarken?.isEnabled = false
            longPressDelete?.isEnabled = false
            tapDismissKeyboard?.isEnabled = false
            tapPreviewToStack?.isEnabled = false
        } else if state == .place {
            longPressDarken?.isEnabled = true
            longPressDelete?.isEnabled = true
            tapPreviewToStack?.isEnabled = true

            tapDismissContentStack?.isEnabled = false
            tapDismissKeyboard?.isEnabled = false
        } else if state == .keyboard {
            tapDismissKeyboard?.isEnabled = true

            tapDismissContentStack?.isEnabled = false
            longPressDarken?.isEnabled = false
            longPressDelete?.isEnabled = false
            tapPreviewToStack?.isEnabled = false
        } else if state == .delete {

            tapDismissKeyboard?.isEnabled = false
            tapDismissContentStack?.isEnabled = false
            longPressDarken?.isEnabled = false
            longPressDelete?.isEnabled = false
            tapPreviewToStack?.isEnabled = false
        }
    }
    @IBOutlet weak var contentStackHitArea: UIButton!

    @IBOutlet weak var contentStackButton: UIButton!

    // MARK: - Image Picker and Delegate
    var tapDismissContentStack : UITapGestureRecognizer?
    @IBAction func chooseObject(_ button: UIButton) {
        contentStack.isHidden = false

        configureGesturesForState(state: .selection)
    }

    @objc func dismissContentStack(gestureRecognize: UITapGestureRecognizer){
        let point = gestureRecognize.location(in: view)
        let safety = CGFloat(10.0)

        if point.y < (contentStack.frame.origin.y - safety) {
            configureGesturesForState(state: .view)

            contentStack.isHidden = true
        }
    }


    // MARK: - Plane Detection

    func restartPlaneDetection() {

        // configure session
        if let worldSessionConfig = sessionConfig as? ARWorldTrackingConfiguration {
            //            worldSessionConfig.planeDetection = .horizontal
            print(worldSessionConfig.planeDetection)
            session.run(worldSessionConfig, options: [.resetTracking, .removeExistingAnchors])
        }

        // reset timer
        if trackingFallbackTimer != nil {
            trackingFallbackTimer!.invalidate()
            trackingFallbackTimer = nil
        }

        textManager.scheduleMessage("FIND A SURFACE TO PLACE AN OBJECT",
                                    inSeconds: 7.5,
                                    messageType: .planeEstimation)
    }

    // MARK: - Hit Test Visualization

    var hitTestVisualization: HitTestVisualization?

    var showHitTestAPIVisualization = UserDefaults.standard.bool(for: .showHitTestAPI) {
        didSet {
            UserDefaults.standard.set(showHitTestAPIVisualization, for: .showHitTestAPI)
            if showHitTestAPIVisualization {
                hitTestVisualization = HitTestVisualization(sceneView: sceneView)
            } else {
                hitTestVisualization = nil
            }
        }
    }

    // MARK: - Debug Visualizations

    @IBOutlet var featurePointCountLabel: UILabel!

    func refreshFeaturePoints() {
        guard showDebugVisuals else {
            return
        }

        // retrieve cloud
        guard let cloud = session.currentFrame?.rawFeaturePoints else {
            return
        }

        DispatchQueue.main.async {
            self.featurePointCountLabel.text = "Features: \(cloud)".uppercased()
        }
    }

    var showDebugVisuals: Bool = UserDefaults.standard.bool(for: .debugMode) {
        didSet {
            featurePointCountLabel.isHidden = !showDebugVisuals
            debugMessageLabel.isHidden = !showDebugVisuals
            messagePanel.isHidden = !showDebugVisuals

            if showDebugVisuals {
                sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
            } else {
                sceneView.debugOptions = []
            }

            // save pref
            UserDefaults.standard.set(showDebugVisuals, for: .debugMode)
        }
    }

    func setupDebug() {
        // Set appearance of debug output panel
        messagePanel.layer.cornerRadius = 3.0
        messagePanel.clipsToBounds = true
    }

    // MARK: - UI Elements and Actions

    @IBOutlet weak var messagePanel: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var debugMessageLabel: UILabel!

    var textManager: TextManager!

    func setupUIControls() {
        textManager = TextManager(viewController: self)

        // hide debug message view
		debugMessageLabel.isHidden = true

		featurePointCountLabel.text = ""
		debugMessageLabel.text = ""
		messageLabel.text = ""
    }

	@IBOutlet weak var restartExperienceButton: UIButton!
	var restartExperienceButtonIsEnabled = true

	@IBAction func restartExperience(_ sender: Any) {

		guard restartExperienceButtonIsEnabled, !isLoadingObject else {
			return
		}

		DispatchQueue.main.async {
			self.restartExperienceButtonIsEnabled = false

			self.textManager.cancelAllScheduledMessages()
			self.textManager.dismissPresentedAlert()
			self.textManager.showMessage("STARTING A NEW SESSION")
			self.use3DOFTracking = false

            self.resetVirtualObject()
			self.restartPlaneDetection()

			self.restartExperienceButton.setImage(#imageLiteral(resourceName: "restart"), for: [])

			// Disable Restart button for five seconds in order to give the session enough time to restart.
			DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: {
				self.restartExperienceButtonIsEnabled = true
			})
		}
	}

	@IBOutlet weak var screenshotButton: UIButton!

	@IBAction func takeScreenshot() {
        guard screenshotButton.isEnabled else {
            return
        }

        let takeScreenshotBlock = {
            UIImageWriteToSavedPhotosAlbum(self.sceneView.snapshot(), nil, nil, nil)
            DispatchQueue.main.async {
                // Briefly flash the screen.
                let flashOverlay = UIView(frame: self.sceneView.frame)
                flashOverlay.backgroundColor = UIColor.white
                self.sceneView.addSubview(flashOverlay)
                UIView.animate(withDuration: 0.25, animations: {
                    flashOverlay.alpha = 0.0
                }, completion: { _ in
                    flashOverlay.removeFromSuperview()
                })
            }
        }

        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            takeScreenshotBlock()
        case .restricted, .denied:
            let title = "Photos access denied"
            let message = "Please enable Photos access for this application in Settings > Privacy to allow saving screenshots."
            textManager.showAlert(title: title, message: message)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ (authorizationStatus) in
                if authorizationStatus == .authorized {
                    takeScreenshotBlock()
                }
            })
        }


//       sceneView.scene.rootNode.
//        print(lastNode.name)

	}

	// MARK: - Settings

	@IBOutlet weak var settingsButton: UIButton!

	@IBAction func showSettings(_ button: UIButton) {
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		guard let settingsViewController = storyboard.instantiateViewController(withIdentifier: "settingsViewController") as? SettingsViewController else {
			return
		}

		let barButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissSettings))
		settingsViewController.navigationItem.rightBarButtonItem = barButtonItem
		settingsViewController.title = "Options"

		let navigationController = UINavigationController(rootViewController: settingsViewController)
		navigationController.modalPresentationStyle = .popover
		navigationController.popoverPresentationController?.delegate = self
		navigationController.preferredContentSize = CGSize(width: sceneView.bounds.size.width - 20, height: sceneView.bounds.size.height - 50)
		self.present(navigationController, animated: true, completion: nil)

		navigationController.popoverPresentationController?.sourceView = settingsButton
		navigationController.popoverPresentationController?.sourceRect = settingsButton.bounds

	}

    @objc
    func dismissSettings() {
        self.dismiss(animated: true, completion: nil)
        updateSettings()
    }

    private func updateSettings() {
        let defaults = UserDefaults.standard

        showDebugVisuals = defaults.bool(for: .debugMode)
        toggleAmbientLightEstimation(defaults.bool(for: .ambientLightEstimation))
        dragOnInfinitePlanesEnabled = defaults.bool(for: .dragOnInfinitePlanes)
        showHitTestAPIVisualization = defaults.bool(for: .showHitTestAPI)
        use3DOFTracking    = defaults.bool(for: .use3DOFTracking)
        use3DOFTrackingFallback = defaults.bool(for: .use3DOFFallback)
    }

    // MARK: - Error handling

    func displayErrorMessage(title: String, message: String, allowRestart: Bool = false) {
        // Blur the background.
        textManager.blurBackground()

        if allowRestart {
            // Present an alert informing about the error that has occurred.
            let restartAction = UIAlertAction(title: "Reset", style: .default) { _ in
                self.textManager.unblurBackground()
                self.restartExperience(self)
            }
            textManager.showAlert(title: title, message: message, actions: [restartAction])
        } else {
            textManager.showAlert(title: title, message: message, actions: [])
        }
    }

    // MARK: - UIPopoverPresentationControllerDelegate
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        updateSettings()
    }
}
