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
    
//    var canvas = UIView()
    var text = Text()
    
    var canvas = Drawing()
    var locationManager = CLLocationManager()
    var rootNodeLocation = CLLocation()
    var currentLocation = CLLocation()
    var currentRootID : String = ""
    var handle: AuthStateDidChangeListenerHandle?
    var deleteMode: Bool = false
    var tapAdd: UITapGestureRecognizer?
    var tapDelete: UITapGestureRecognizer?
    var longPressDelete: UILongPressGestureRecognizer?
    var longPressDarken: UILongPressGestureRecognizer?
    var tapPreviewToStack : UITapGestureRecognizer?
    var content : Content?
    lazy var stdLen: CGFloat = {
        let len = self.sceneView.bounds.height / 3000
        return len
    }()

    let selectionButton = UIButton()
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

        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        
        setupButtonsForEditing()
        
        view.addSubview(addObjectButton)
        addObjectButton.setImage(UIImage(named: "add"), for: .normal)
        addObjectButton.setImage(UIImage(named: "addPressed"), for: .highlighted)
        addObjectButton.addTarget(self, action: #selector(chooseObject), for: .touchUpInside)
        addObjectButton.translatesAutoresizingMaskIntoConstraints = false
        addObjectButton.widthAnchor.constraint(equalToConstant: 64).isActive = true
        addObjectButton.heightAnchor.constraint(equalToConstant: 64).isActive = true
        addObjectButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -15).isActive = true
        addObjectButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
     
    }
    
    let addObjectButton = UIButton()
    let preview = UIImageView()
    
    
    
    @objc func previewToContentStack(gestureRecognize: UITapGestureRecognizer) {
        hidePreview()
        showContentStack()
    }
    
    func showPlaceObjectButton(bool : Bool) {
        contentStackButton.isEnabled = bool
        contentStackHitArea.isEnabled = bool
        contentStackButton.isHidden = !bool
    }

    var contentStackBotAnchor : NSLayoutConstraint?
   
    let contentStack = UIStackView()
    let libraryGrid = LibraryGrid()
    let memeGrid = LibraryGrid()
    let gifGrid = GifGrid()
    let stickerGrid = LibraryGrid()
  

    // MARK: - Gesture Recognizers
    var tapDismissKeyboard : UITapGestureRecognizer?

    func createNode(content: SKScene) {
        guard let currentFrame = sceneView.session.currentFrame else{
            return
        }
        // Image Plane

        let imagePlane = SCNPlane(width: stdLen, height: stdLen)
        imagePlane.firstMaterial?.lightingModel = .constant
        imagePlane.firstMaterial?.diffuse.contents = content
        // Flip content horizontally
        imagePlane.firstMaterial?.diffuse.contentsTransform = SCNMatrix4MakeScale(1,-1,1);
        imagePlane.firstMaterial?.diffuse.wrapT = SCNWrapMode.init(rawValue: 2)!;
        imagePlane.firstMaterial?.isDoubleSided = true


        // Node transform
        let wrapperNode = SCNNode(geometry: imagePlane)
        // 10 cm in front of camera
        var translation = matrix_identity_float4x4
        translation.columns.3.z = -0.1
        // Rotate to correct orientation
        var rotation = matrix_identity_float4x4
        rotation.columns.0.x = Float(cos(CGFloat.pi * -3/2))
        rotation.columns.0.y = Float(sin(CGFloat.pi * -3/2))
        rotation.columns.1.x = Float(-sin(CGFloat.pi * -3/2))
        rotation.columns.1.y = Float(cos(CGFloat.pi * -3/2))
        wrapperNode.simdTransform = matrix_multiply(matrix_multiply(currentFrame.camera.transform, translation), rotation)



        // MARK: Andreas's Code

        // Save Node and Pictures to Database
//        let data = self.content!.data!
//        
//        var databaseRef: DatabaseReference!
//        databaseRef = Database.database().reference()
//
//        let storageRef = Storage.storage().reference()
//
//        let metaData = StorageMetadata()
//        let input : NSData = NSData(data: data)
//        if input.imageFormat == .JPEG {
//            metaData.contentType = "image/jpeg"
//        } else if input.imageFormat == .PNG {
//            metaData.contentType = "image/png"
//        } else if input.imageFormat == .TIFF {
//            metaData.contentType = "image/tiff"
//        } else if input.imageFormat == .GIF {
//            metaData.contentType = "image/gif"
//        } else {
//            print("not acceptable format of media")
//        }
//
//        let userID = Auth.auth().currentUser!.uid
//        let rootID = self.currentRootID
//        let picID = databaseRef.child("/pictures/").childByAutoId().key
//        let nodeID = databaseRef.child("/nodes/").childByAutoId().key
//        //set the name of the node in the scene & add to scene
//        wrapperNode.name = nodeID
        sceneView.scene.rootNode.addChildNode(wrapperNode)
//
//        let picturesRef = storageRef.child("/pictures/\(picID)")
//
//        picturesRef.putData(data, metadata: metaData) { (metadata, error) in
//            if let error = error {
//                // Uh-oh, an error occurred!
//                print(error)
//                return
//            } else {
//                // Metadata contains file metadata such as size, content-type, and download URL.
//                let downloadURL = metadata!.downloadURL()!.absoluteString
//                // format date type to string
//                let date = metadata!.timeCreated!
//                let dateFormatter = DateFormatter()
//                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
//                dateFormatter.locale = Locale(identifier: "en_US")
//                let timestamp = dateFormatter.string(from:date as Date)
//
//
//                // check if node distance is new radius
//                let newDistance = Double(wrapperNode.position.length())
//
//                let rootsRef = databaseRef.child("/roots/\(rootID)")
//                rootsRef.observeSingleEvent(of: .value, with: { (snapshot) in
//                    let currRoot = snapshot.valueInExportFormat() as! NSDictionary
//
//                    var currRadius : Double = 0.0
//                    for (key, value) in currRoot {
//                        if (key as? String == "radius") {
//                            currRadius = value as! Double
//                        }
//                    }
//
//                    if newDistance > currRadius {
//                        let rootChildUpdates: [String: Any] = ["/roots/\(rootID)/radius": newDistance]
//                        databaseRef.updateChildValues(rootChildUpdates)
//                    }
//                })
//
//                //store downloadURL at database
//                let picture: [String: Any] = ["url": downloadURL, "timestamp": timestamp]
//                let picChildUpdates: [String: Any] = ["/pictures/\(picID)": picture, "/users/\(userID)/lastPicture": picID]
//                databaseRef.updateChildValues(picChildUpdates)
//                databaseRef.child("/pictures/\(picID)/nodes/\(nodeID)").setValue(true);
//                databaseRef.child("/pictures/\(picID)/users/\(userID)").setValue(true);
//
//                var transformArray: [[Float]] = [[],[],[],[]]
//                for index in 0...3 {
//                    if index == 0 {
//                        transformArray[0].append(wrapperNode.simdTransform.columns.0.x)
//                        transformArray[0].append(wrapperNode.simdTransform.columns.0.y)
//                        transformArray[0].append(wrapperNode.simdTransform.columns.0.z)
//                        transformArray[0].append(wrapperNode.simdTransform.columns.0.w)
//                    } else if index == 1 {
//                        transformArray[1].append(wrapperNode.simdTransform.columns.1.x)
//                        transformArray[1].append(wrapperNode.simdTransform.columns.1.y)
//                        transformArray[1].append(wrapperNode.simdTransform.columns.1.z)
//                        transformArray[1].append(wrapperNode.simdTransform.columns.1.w)
//                    } else if index == 2 {
//                        transformArray[2].append(wrapperNode.simdTransform.columns.2.x)
//                        transformArray[2].append(wrapperNode.simdTransform.columns.2.y)
//                        transformArray[2].append(wrapperNode.simdTransform.columns.2.z)
//                        transformArray[2].append(wrapperNode.simdTransform.columns.2.w)
//                    } else {
//                        transformArray[3].append(wrapperNode.simdTransform.columns.3.x)
//                        transformArray[3].append(wrapperNode.simdTransform.columns.3.y)
//                        transformArray[3].append(wrapperNode.simdTransform.columns.3.z)
//                        transformArray[3].append(wrapperNode.simdTransform.columns.3.w)
//                    }
//                }
//                print("Transform Array (simd) create: \(wrapperNode.simdTransform)")
//                print("Transform Array create: \(transformArray)")
//
//                let node : [String : Any] = ["distance": newDistance,
//                                             "transformArray": transformArray,
//                                             "picture": picID,
//                                             "root": rootID,
//                                             "user": userID,
//                                             "timestamp": timestamp]
//                let nodeChildUpdates: [String: Any] = ["/nodes/\(nodeID)": node]
//                databaseRef.updateChildValues(nodeChildUpdates)
//                databaseRef.child("/roots/\(rootID)/nodes/\(nodeID)").setValue(true);
//            }
//        }

        //-------------
    }

    // Deleting Object
    var longPressDeleteFired: Bool = false
    

    
    var target: SCNNode?
    

    func deleteIsClicked(localCoordinates: SCNVector3) -> Bool {
        let x = CGFloat(localCoordinates.x)
        let y = CGFloat(localCoordinates.y)

        print("input x: \(x) , comparision range \(stdLen * 0.3) to \(stdLen * 0.5)")
        print("input y: \(y) , comparision range \(stdLen*0.5) to \(stdLen/2)")

        if (x > (stdLen * 0.3) && x < (stdLen * 0.5) && y > (stdLen * 0.3) && (y < stdLen / 0.5)){
             return true
        }
        return false

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
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        session.pause()

        // Remove Auth Listener for User Sign in State
        Auth.auth().removeStateDidChangeListener(handle!)
    }

    // MARK: - Firebase Initialization
//    func setupFirebase() {
//        // Sign in User with Firebase Auth
//        print("User Auth")
//        if Auth.auth().currentUser != nil {
//            print("User is already logged in anonymously with uid:" + Auth.auth().currentUser!.uid)
//        } else {
//            do {
//                try Auth.auth().signOut();
//                print("signed out")
//            } catch {
//                print("Error signing out")
//            }
//            Auth.auth().signInAnonymously() { (user, error) in
//                if error != nil {
//                    print("This is the error msg:")
//                    print(error!)
//                    print("Here ends the error msg.")
//                    return
//                }
//
//                if user!.isAnonymous {
//                    print("User has logged in anonymously with uid:" + user!.uid)
//                }
//            }
//
//
//            // Code to set the user's displayName
//            //            let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
//            //            let displayName = "adias"
//            //            changeRequest?.displayName = displayName
//            //            changeRequest?.commitChanges { (error) in
//            //                if error != nil {
//            //                    print(error!)
//            //                    return
//            //                }
//            //                 print("The user's displayName has been added")
//            //            }
//        }
//
//        print("getcurrentLocation in setupFirebase: \(currentLocation)")
//        print("getrootNodeLocation in setupFirebase: \(rootNodeLocation)")
//
//
//        // Initialize Firebase Database
//        let databaseRef = Database.database().reference()
//
//        // Format Date into String
//        let rootTime = rootNodeLocation.timestamp
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
//        dateFormatter.locale = Locale(identifier: "en_US")
//        let timestamp = dateFormatter.string(from:rootTime as Date)
//
//        // Add root to Roots
//        let dbRoot: [String: Any] = [
//            "latitude": rootNodeLocation.coordinate.latitude,
//            "longitude": rootNodeLocation.coordinate.longitude,
//            "altitude": rootNodeLocation.altitude,
//            "horizontalAccuracy": rootNodeLocation.horizontalAccuracy,
//            "verticalAccuracy": rootNodeLocation.verticalAccuracy,
//            "timestamp": timestamp,
//            "radius":  0.0,
//        ]
//        currentRootID = databaseRef.child("roots").childByAutoId().key
//        databaseRef.child("roots/\(currentRootID)/").setValue(dbRoot)
//        databaseRef.child("/roots/\(currentRootID)/users/\(Auth.auth().currentUser!.uid)").setValue(true);
//
//        let userChildUpdates: [String: Any] = ["/users/\(Auth.auth().currentUser!.uid)/lastRoot": currentRootID]
//        databaseRef.updateChildValues(userChildUpdates)
//    }
//
//    // MARK: - Populate Nearby Areas with Existent Nodes
//    private func getRadiansFrom(degrees: Double) -> Double {
//        return degrees * .pi / 180
//    }
//
//    private func getMagnitudeOf() {
//
//    }
//
//    private func getSCNVectorComponentsBetween(currLocation: CLLocation, prevLocation: CLLocation) -> (Double, Double, Double) {
//
//        let distance = currLocation.distance(from: prevLocation)
//        let altitude = currLocation.altitude - prevLocation.altitude
//
//        let lat1 = self.getRadiansFrom(degrees: currLocation.coordinate.latitude)
//        let lon1 = self.getRadiansFrom(degrees: currLocation.coordinate.longitude)
//
//        let lat2 = self.getRadiansFrom(degrees: prevLocation.coordinate.latitude)
//        let lon2 = self.getRadiansFrom(degrees: prevLocation.coordinate.longitude)
//
//        let dLon = lon2 - lon1
//
//        let y = sin(dLon) * cos(lat2)
//        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
//        let radiansBearing = atan2(y, x)
//
//        let xcom = distance * cos(radiansBearing)
//        let ycom = distance * sin(radiansBearing)
//
//        let zcom = currLocation.altitude - prevLocation.altitude
//
//        return (xcom, zcom, ycom)
//    }

    // Since I did not use cloning here I'm not sure that the original stays intact for multiple usage.
//    func addPrevNodesToScene() {
//        let databaseRef = Database.database().reference()
//        let rootsRef = databaseRef.child("/roots/")
//
//        rootsRef.observe(.value, with: { (snapshot) in
//            if snapshot.exists() {
//                let enumerator = snapshot.children
//                while let dbRoot = enumerator.nextObject() as? DataSnapshot {
//                    let rootDict = dbRoot.valueInExportFormat() as! NSDictionary
//
//                    print("dbRoot: \(dbRoot)")
//                    print("dbRoot.key: \(dbRoot.key)")
//
//                    var dbLatitude : Double = 0.0
//                    var dbLongitude : Double = 0.0
//                    var dbAltitude : Double = 0.0
//                    var dbHorizontalAccuracy : Double = 0.0
//                    var dbVerticalAccuracy : Double = 0.0
//                    var dbTimestamp : Date = Date.distantPast
//                    var dbRadius : Double = 0.0
//                    var dbNodes : NSDictionary = ["":true]
//                    for (key, value) in rootDict {
//                        if (key as? String == "latitude") {
//                            dbLatitude = value as! Double
//                        } else if (key as? String == "longitude") {
//                            dbLongitude = value as! Double
//                        } else if (key as? String == "altitude") {
//                            dbAltitude = value as! Double
//                        } else if (key as? String == "horizontalAccuracy") {
//                            dbHorizontalAccuracy = value as! Double
//                        } else if (key as? String == "verticalAccuracy") {
//                            dbVerticalAccuracy = value as! Double
//                        } else if (key as? String == "timestamp") {
//                            let dateFormatter = DateFormatter()
//                            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
//                            dateFormatter.locale = Locale(identifier: "en_US")
//                            let timestamp = dateFormatter.date(from: value as! String)
//                            dbTimestamp = timestamp!
//                        } else if (key as? String == "radius") {
//                            dbRadius = value as! Double
//                        } else if (key as? String == "nodes") {
//                            dbNodes = value as! NSDictionary
//                        } else {
//                        }
//                    }
//
//                    let prevRootCoordinates = CLLocationCoordinate2D.init(latitude: dbLatitude, longitude: dbLongitude)
//                    print("this is prevRootCoordinates: \(prevRootCoordinates)")
//                    let prevRootLocation = CLLocation.init(coordinate: prevRootCoordinates, altitude: dbAltitude, horizontalAccuracy: dbHorizontalAccuracy, verticalAccuracy: dbVerticalAccuracy, timestamp: dbTimestamp)
//                    print("this is prevRootLocation: \(prevRootLocation)")
//
//                    if (dbRoot.key != self.currentRootID) {
//                        // Add Posted Scene if within 20 meters from furthest node of a previous scene & if a session had a picture added
//                        // & if root hasn't already been added
//                        if (self.currentLocation.distance(from: prevRootLocation) <= (dbRadius + 20) && dbRadius != 0) {
//                            databaseRef.child("/roots/\(self.currentRootID)/addedRoots").observeSingleEvent(of: .value, with: { (snapshot) in
//                                print("snapshot value: \(snapshot.valueInExportFormat()!)")
//                                var hasRootBeenSeen = false
//                                if let addedRootsDict = snapshot.valueInExportFormat()! as? NSDictionary {
//                                    print("addedRootsDict: \(addedRootsDict)")
//                                    print("addedRootsDict.object: \(addedRootsDict.object(forKey: dbRoot.key)!)")
//                                    if addedRootsDict[dbRoot.key] != nil {
//                                        hasRootBeenSeen = true
//                                    } else {
//                                        hasRootBeenSeen = false
//                                    }
//                                } else {
//                                    hasRootBeenSeen = false
//                                }
//                                if (!hasRootBeenSeen) {
//                                    print("I'm within 20 meters")
//                                    do {
//                                        let prevRootNode = SCNNode()
//
//                                        let group = DispatchGroup()
//
//                                        for (nodeID, _) in dbNodes {
//                                            group.enter()
//                                            print("got in node loop with nodeID: \(nodeID)")
//                                            let nodeRef = databaseRef.child("/nodes/\(nodeID)")
//                                            nodeRef.observeSingleEvent(of: .value, with: { (snapshot) in
//                                                if snapshot.exists() {
//                                                    let nodeDict = snapshot.valueInExportFormat() as! NSDictionary
//
//                                                    print("nodeDict: \(nodeDict)")
//
//                                                    var dbNodeTransformDict : NSDictionary = [:]
//                                                    var dbNodePicture : String = ""
//                                                    for (key, value) in nodeDict {
//                                                        if (key as? String == "transformArray") {
//                                                            dbNodeTransformDict = value as! NSDictionary
//                                                        } else if (key as? String == "picture") {
//                                                            dbNodePicture = value as! String
//                                                        } else {
//
//                                                        }
//                                                    }
//
//
//                                                    let picRef = databaseRef.child("/pictures/\(dbNodePicture)/url")
//                                                    picRef.observeSingleEvent(of: .value, with :{ (snapshot) in
//                                                        if snapshot.exists() {
//                                                            let imagePlane = SCNPlane(width: self.stdLen, height: self.stdLen)
//                                                            let picUrl = snapshot.valueInExportFormat() as! String
//
//                                                            // initialize this correctly and make sure of corner cases
//                                                            var skimage = SKScene()
//
//                                                            do {
//                                                                let input : NSData = try NSData(contentsOf: URL(string: picUrl)!)
//                                                                if input.imageFormat == .JPEG || input.imageFormat == .PNG || input.imageFormat == .TIFF {
//                                                                    skimage = SKScene.makeSKSceneFromImage(url: NSURL(string: picUrl)!, size: CGSize(width: self.sceneView.frame.width, height: self.sceneView.frame.height))
//                                                                } else if input.imageFormat == .GIF {
//                                                                    skimage = SKScene.makeSKSceneFromGif(url: NSURL(string: picUrl)!, size: CGSize(width: self.sceneView.frame.width, height: self.sceneView.frame.height))
//                                                                } else {
//                                                                    print("not acceptable format of image")
//                                                                }
//                                                            } catch {
//                                                                print("Error in converting picurl to NSData")
//                                                            }
//
//                                                            imagePlane.firstMaterial?.diffuse.contents = skimage
//                                                            imagePlane.firstMaterial?.lightingModel = .constant
//                                                            imagePlane.firstMaterial?.diffuse.contentsTransform = SCNMatrix4MakeScale(1,-1,1);
//                                                            imagePlane.firstMaterial?.diffuse.wrapT = SCNWrapMode.init(rawValue: 2)!;
//                                                            imagePlane.firstMaterial?.isDoubleSided = true
//
//                                                            let childNode = SCNNode(geometry: imagePlane)
//                                                            var transformArray : simd_float4x4
//
//                                                            var columns = [float4].init()
//                                                            for key in 0...3 {
//                                                                let tempDict = dbNodeTransformDict.value(forKey: "\(key)") as! NSDictionary
//                                                                print("tempDict: \(tempDict)")
//                                                                var temp = [Float].init()
//                                                                temp.append((tempDict.value(forKey: "0") as! NSNumber).floatValue)
//                                                                print("temp0: \(temp)")
//                                                                print(tempDict.value(forKey: "1")!)
//                                                                temp.append((tempDict.value(forKey: "1") as! NSNumber).floatValue)
//                                                                print("temp1: \(temp)")
//                                                                temp.append((tempDict.value(forKey: "2") as! NSNumber).floatValue)
//                                                                print("temp2: \(temp)")
//                                                                temp.append((tempDict.value(forKey: "3") as! NSNumber).floatValue)
//                                                                print("temp3: \(temp)")
//                                                                let floatFour = float4.init(temp)
//                                                                columns.append(floatFour)
//                                                            }
//                                                            transformArray = simd_float4x4.init(columns)
//                                                            print("Transform Array addPrev: \(transformArray)")
//                                                            childNode.simdTransform = transformArray
//                                                            childNode.name = "\(nodeID)"
//                                                            prevRootNode.addChildNode(childNode)
//                                                            group.leave()
//                                                        } else {
//                                                            print("snapshot of pictures does not exist")
//                                                        }
//                                                    })
//                                                } else {
//                                                    print("snapshot of nodes does not exist")
//                                                }
//                                            })
//                                        }
//                                        group.notify(queue: .main) {
//                                            let components = self.getSCNVectorComponentsBetween(currLocation: self.rootNodeLocation, prevLocation: prevRootLocation)
//                                            print("check if components are switched")
//                                            print("components: \(components)")
//                                            let childPosition = SCNVector3(components.0, components.1, components.2)
//                                            print("childPosition: \(childPosition)")
//                                            prevRootNode.position = childPosition
//
//                                            self.sceneView.scene.rootNode.addChildNode(prevRootNode)
//                                            // Add this to seen
//                                            databaseRef.child("/roots/\(self.currentRootID)/addedRoots/\(dbRoot.key)").setValue(true)
//                                        }
//                                    } catch {
//                                        print(error)
//                                    }
//                                }
//                            })
//                        }
//                    }
//                }
//            } else {
//                print("Error in retrieving snapshot")
//            }
//        })
//    }

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
        locationManager.startUpdatingLocation()
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
//                setupFirebase()
            }
            // Start checking for Nodes
//            addPrevNodesToScene()
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
//                sessionConfig = ARConfiguration() as! ARWorldTrackingConfiguration
            }
            sessionConfig.isLightEstimationEnabled = UserDefaults.standard.bool(for: .ambientLightEstimation)
            sessionConfig.worldAlignment = .gravityAndHeading
            sessionConfig.worldAlignment = ARSessionConfiguration.WorldAlignment.gravityAndHeading
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
                self.restartExperienceButton.isHidden = true
            }
        }
    }

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

  
    @IBOutlet weak var contentStackHitArea: UIButton!

    @IBOutlet weak var contentStackButton: UIButton!

    let editBoard = EditBoard()
    // MARK: - Image Picker and Delegate
    var tapDismissContentStack : UITapGestureRecognizer?
    @objc func chooseObject(_ button: UIButton) {
        showContentStack()
        
        let length = UIScreen.main.bounds.width * 0.90
        let wMargin = (UIScreen.main.bounds.width - length) / 2
        let hMargin = 3 * wMargin
        view.addSubview(editBoard)
        view.addConstraintsWithFormat("H:|-\(wMargin)-[v0(\(length))]-\(wMargin)-|", views: editBoard)
        view.addConstraintsWithFormat("V:|-\(hMargin)-[v0(\(length))]|", views: editBoard)
       
        var translation = CGAffineTransform(translationX: 0, y: UIScreen.main.bounds.height - hMargin)
        var scale = CGAffineTransform(scaleX: 0.2, y: 0.2)
        editBoard.transform = scale.concatenating(translation)
        

        UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseOut, animations: {
            translation = CGAffineTransform(translationX: 0, y: -50)
            scale = CGAffineTransform(scaleX: 1.5, y: 1.5)
            self.addObjectButton.transform = scale.concatenating(translation)
            self.addObjectButton.alpha = 0
        }, completion: nil)
        UIView.animate(withDuration:
            0.5, delay: 0, options: .curveEaseOut, animations: {
                self.editBoard.transform = .identity
        }, completion: nil)
    }


    // MARK: - Plane Detection

    func restartPlaneDetection() {

        // configure session
        if let worldSessionConfig = sessionConfig as? ARWorldTrackingSessionConfiguration {
            //            worldSessionConfig.planeDetection = .horizontal
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
            self.featurePointCountLabel.text = "Features: \(cloud.__count)".uppercased()
        }
    }

    
    var showDebugVisuals: Bool = UserDefaults.standard.bool(for: .debugMode) {
        didSet {
            featurePointCountLabel.isHidden = !showDebugVisuals
            debugMessageLabel.isHidden = !showDebugVisuals
            messagePanel.isHidden = !showDebugVisuals
            messagePanel.isHidden = true
            messageLabel.isHidden = true
            debugMessageLabel.isHidden = true

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
        messagePanel.isHidden = true
        messageLabel.isHidden = true
        debugMessageLabel.isHidden = true
        
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
        restartExperienceButton.isHidden = true
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
//        guard screenshotButton.isEnabled else {
//            return
//        }
//
//        let takeScreenshotBlock = {
//            UIImageWriteToSavedPhotosAlbum(self.sceneView.snapshot(), nil, nil, nil)
//            DispatchQueue.main.async {
//                // Briefly flash the screen.
//                let flashOverlay = UIView(frame: self.sceneView.frame)
//                flashOverlay.backgroundColor = UIColor.white
//                self.sceneView.addSubview(flashOverlay)
//                UIView.animate(withDuration: 0.25, animations: {
//                    flashOverlay.alpha = 0.0
//                }, completion: { _ in
//                    flashOverlay.removeFromSuperview()
//                })
//            }
//        }
//
//        switch PHPhotoLibrary.authorizationStatus() {
//        case .authorized:
//            takeScreenshotBlock()
//        case .restricted, .denied:
//            let title = "Photos access denied"
//            let message = "Please enable Photos access for this application in Settings > Privacy to allow saving screenshots."
//            textManager.showAlert(title: title, message: message)
//        case .notDetermined:
//            PHPhotoLibrary.requestAuthorization({ (authorizationStatus) in
//                if authorizationStatus == .authorized {
//                    takeScreenshotBlock()
//                }
//            })
//        }


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
    
    // MARK: - Temporary Placement
    let drawButton = UIButton()
    let undoButton = UIButton()
    let textButton = UIButton()
    let clearButton = UIButton()
    let finishButton = UIButton()


    
}
