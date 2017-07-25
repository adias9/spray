/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 Main view controller for the AR experience.
 */

import ARKit
import Foundation
import SceneKit
import UIKit
import Photos
import CoreLocation
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

class ViewController: UIViewController, ARSCNViewDelegate, UIPopoverPresentationControllerDelegate,  CLLocationManagerDelegate, ImagePickerViewControllerDelegate {
    
    var locationManager = CLLocationManager()
    var rootNodeLocation = CLLocation()
    var currentLocation = CLLocation()
    var currentRootID : String = ""
    var handle: AuthStateDidChangeListenerHandle?
    
    // MARK: - Main Setup & View Controller methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Setting.registerDefaults()
        setupScene()
        setupDebug()
        setupUIControls()
        updateSettings()
        resetVirtualObject()
        setupLocationSettings()
        
        // Set tap Gesture using handleTap()
        let tapGesture = UITapGestureRecognizer(target: self, action:
            #selector(self.handleTap(gestureRecognize:)))
        view.addGestureRecognizer(tapGesture)
    }
    
    var obj: UIImage?
    @objc
    func handleTap(gestureRecognize: UITapGestureRecognizer){
        guard let currentFrame = sceneView.session.currentFrame else{
            return
        }
        if(obj == nil) {
            obj = UIImage(named: "sample")
        }
        
        let imagePlane = SCNPlane(width: sceneView.bounds.width / 6000, height: sceneView.bounds.height / 6000)
        imagePlane.firstMaterial?.diffuse.contents = obj
        imagePlane.firstMaterial?.lightingModel = .constant
        let wrapperNode = SCNNode(geometry: imagePlane)
        
        var translation = matrix_identity_float4x4
        translation.columns.3.z = -0.1
        
        var rotation = matrix_identity_float4x4
        rotation.columns.0.x = Float(cos(CGFloat.pi * -3/2))
        rotation.columns.0.y = Float(sin(CGFloat.pi * -3/2))
        rotation.columns.1.x = Float(-sin(CGFloat.pi * -3/2))
        rotation.columns.1.y = Float(cos(CGFloat.pi * -3/2))
        
        wrapperNode.simdTransform = matrix_multiply(matrix_multiply(currentFrame.camera.transform, translation), rotation)
        
        print("simdtransform array \(wrapperNode.simdTransform)")
        
        // TODO: combine the back with the front. add both nodes as child of a picture node, then add the picture node as chid of root
        // TODO: potentially explore using cubes instead. play with the dimensions to make it look like a two sided picture. currently side view disappears
        // TODO: currently the back side is smaller because it was place further. FIX THIS!
        let wrapperNodeBack = SCNNode(geometry: imagePlane)
        var rotationBack = matrix_identity_float4x4
        rotationBack.columns.0.x = Float(cos(CGFloat.pi))
        rotationBack.columns.2.y = Float(sin(CGFloat.pi))
        rotationBack.columns.0.z = Float(-sin(CGFloat.pi))
        rotationBack.columns.2.z = Float(cos(CGFloat.pi))
        wrapperNodeBack.simdTransform = matrix_multiply(matrix_multiply(wrapperNode.simdTransform, translation), rotationBack)
        
        
        sceneView.scene.rootNode.addChildNode(wrapperNode)
        sceneView.scene.rootNode.addChildNode(wrapperNodeBack)
        print(";)")
        
        // MARK: Andreas's Code
        
        // Save Node and Pictures to Database
        var data = Data()
        data = UIImageJPEGRepresentation(obj!, 0.8)!
        
        var databaseRef: DatabaseReference!
        databaseRef = Database.database().reference()
        
        let storageRef = Storage.storage().reference()
        
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpg"
        
        let userID = Auth.auth().currentUser!.uid
        let rootID = self.currentRootID
        let picID = databaseRef.child("/pictures/").childByAutoId().key
        let nodeID = databaseRef.child("/nodes/").childByAutoId().key
        
        let picturesRef = storageRef.child("/pictures/\(picID)")
        
        picturesRef.putData(data, metadata: metaData) { (metadata, error) in
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
                let newDistance = Double(wrapperNode.position.length())
                
                let rootsRef = databaseRef.child("/roots/\(rootID)")
                rootsRef.observeSingleEvent(of: .value, with: { (snapshot) in
                    let currRoot = snapshot.valueInExportFormat() as! NSDictionary
                    
                    var currRadius : Double = 0.0
                    for (key, value) in currRoot {
                        if (key as? String == "radius") {
                            currRadius = value as! Double
                        }
                    }
                    
                    if newDistance > currRadius {
                        let rootChildUpdates: [String: Any] = ["/roots/\(rootID)/radius": newDistance]
                        databaseRef.updateChildValues(rootChildUpdates)
                    }
                })
                
                //store downloadURL at database
                let picture: [String: Any] = ["url": downloadURL, "timestamp": timestamp, "users": [userID], "nodes": [nodeID]]
                let picChildUpdates: [String: Any] = ["/pictures/\(picID)": picture, "/users/\(userID)/lastPicture": picID]
                databaseRef.updateChildValues(picChildUpdates)
                
                let transformArray: [float4]
                for index in 0...3 {
                    if index == 0 {
                        transformArray.append(wrapperNode.simdTransform.columns.0)
                    } else if index == 1 {
                        transformArray.append(wrapperNode.simdTransform.columns.1)
                    } else if index == 2 {
                        transformArray.append(wrapperNode.simdTransform.columns.2)
                    } else {
                        transformArray.append(wrapperNode.simdTransform.columns.3)
                    }
                }
                let node : [String : Any] = ["distance": newDistance,
                                             "transformArray": transformArray,
                                             "timestamp": timestamp,
                                             "pictures": [picID]]
                let nodeChildUpdates: [String: Any] = ["/nodes/\(nodeID)": node, "/roots/\(rootID)/nodes/": nodeID]
                databaseRef.updateChildValues(nodeChildUpdates)
            }
        }
        
        //-------------
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
        
        session.pause()
        
        // Remove Auth Listener for User Sign in State
        Auth.auth().removeStateDidChangeListener(handle!)
    }
    
    // MARK: - Firebase Initialization
    func setupFirebase() {
        // Sign in User with Firebase Auth
        print("User Auth")
        if Auth.auth().currentUser != nil {
            print("User is already logged in anonymously with uid:" + Auth.auth().currentUser!.uid)
        } else {
            do {
                try Auth.auth().signOut();
                print("signed out")
            } catch {
                print("Error signing out")
            }
            Auth.auth().signInAnonymously() { (user, error) in
                if error != nil {
                    print("This is the error msg:")
                    print(error!)
                    print("Here ends the error msg.")
                    return
                }
                
                if user!.isAnonymous {
                    print("User has logged in anonymously with uid:" + user!.uid)
                }
            }
            
            
            // Code to set the user's displayName
            //            let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
            //            let displayName = "adias"
            //            changeRequest?.displayName = displayName
            //            changeRequest?.commitChanges { (error) in
            //                if error != nil {
            //                    print(error!)
            //                    return
            //                }
            //                 print("The user's displayName has been added")
            //            }
        }
        
        print("getcurrentLocation in setupFirebase: \(currentLocation)")
        print("getrootNodeLocation in setupFirebase: \(currentLocation)")
        
        
        // Initialize Firebase Database
        let databaseRef = Database.database().reference()
        
        // Format Date into String
        let rootTime = rootNodeLocation.timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        dateFormatter.locale = Locale(identifier: "en_US")
        let timestamp = dateFormatter.string(from:rootTime as Date)
        
        // Add root to Roots
        let dbRoot: [String: Any] = [
            "latitude": rootNodeLocation.coordinate.latitude,
            "longitude": rootNodeLocation.coordinate.longitude,
            "altitude": rootNodeLocation.altitude,
            "horizontalAccuracy": rootNodeLocation.horizontalAccuracy,
            "verticalAccuracy": rootNodeLocation.verticalAccuracy,
            "timestamp": timestamp,
            "radius":  0.0,
            "users": [Auth.auth().currentUser!.uid],
            "nodes": [],
        ]
        currentRootID = databaseRef.child("roots").childByAutoId().key
        databaseRef.child("roots/\(currentRootID)/").setValue(dbRoot)
        
        let userChildUpdates: [String: Any] = ["/users/\(Auth.auth().currentUser!.uid)/lastRoot": currentRootID]
        databaseRef.updateChildValues(userChildUpdates)
    }
    
    // MARK: - Populate Nearby Areas with Existent Nodes
    private func getRadiansFrom(degrees: Double) -> Double {
        return degrees * .pi / 180
    }
    
    private func getSCNVectorComponentsBetween(currLocation: CLLocation, prevLocation: CLLocation) -> (Double, Double, Double) {
        let lat1 = self.getRadiansFrom(degrees: currLocation.coordinate.latitude)
        let lon1 = self.getRadiansFrom(degrees: currLocation.coordinate.longitude)
        
        let lat2 = self.getRadiansFrom(degrees: prevLocation.coordinate.latitude)
        let lon2 = self.getRadiansFrom(degrees: prevLocation.coordinate.longitude)
        
        let dLon = lon2 - lon1
        
        let z = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        
        let y = currLocation.altitude - prevLocation.altitude
        
        return (x, y, z)
    }
    
    private func ArraystoTransform() {
        
    }
    
    // Since I did not use cloning here I'm not sure that the original stays intact for multiple usage.
    func addPrevNodesToScene() {
        let databaseRef = Database.database().reference()
        let storageRef = Storage.storage()
        let rootsRef = databaseRef.child("/roots/")
        
        rootsRef.observe(.value, with: { (snapshot) in
            if snapshot.exists() {
                let enumerator = snapshot.children
                while let dbRoot = enumerator.nextObject() as? DataSnapshot {
                    let rootDict = dbRoot.valueInExportFormat() as! NSDictionary
                    
                    var dbLatitude : Double = 0.0
                    var dbLongitude : Double = 0.0
                    var dbAltitude : Double = 0.0
                    var dbHorizontalAccuracy : Double = 0.0
                    var dbVerticalAccuracy : Double = 0.0
                    var dbTimestamp : Date = Date.distantPast
                    var dbRadius : Double = 0.0
                    var dbNodes : Array = [""]
                    for (key, value) in rootDict {
                        if (key as? String == "latitude") {
                            dbLatitude = value as! Double
                        } else if (key as? String == "longtitude") {
                            dbLongitude = value as! Double
                        } else if (key as? String == "altitude") {
                            dbAltitude = value as! Double
                        } else if (key as? String == "horizontalAccuracy") {
                            dbHorizontalAccuracy = value as! Double
                        } else if (key as? String == "verticalAccuracy") {
                            dbVerticalAccuracy = value as! Double
                        } else if (key as? String == "timestamp") {
                            dbTimestamp = value as! Date
                        } else if (key as? String == "radius") {
                            dbRadius = value as! Double
                        } else if (key as? String == "nodes") {
                            dbNodes = value as! Array
                        } else {
                            
                        }
                    }
                    
                    let prevRootCoordinates = CLLocationCoordinate2D.init(latitude: dbLatitude, longitude: dbLongitude)
                    let prevRootLocation = CLLocation.init(coordinate: prevRootCoordinates, altitude: dbAltitude, horizontalAccuracy: dbHorizontalAccuracy, verticalAccuracy: dbVerticalAccuracy, timestamp: dbTimestamp)
                    
                    // Add Posted Scene if within 20 meters from furthest node of a previous scene
                    if (self.currentLocation.distance(from: prevRootLocation) <= (dbRadius + 20)) {
                        do {
                            let prevRootNode = SCNNode()
                            
                            for nodeID in dbNodes {
                                let nodeRef = databaseRef.child("/nodes/\(nodeID)")
                                nodeRef.observeSingleEvent(of: .value, with: { (snapshot) in
                                    let nodeDict = snapshot.valueInExportFormat() as! NSDictionary
                                    
                                    simd_float4x4([[-0.108311, -0.0339218, -0.993538, 0.0], [-0.589323, 0.807076, 0.0366915, 0.0], [0.800616, 0.589489, -0.107404, 0.0], [11.403, -3.58662, -40.9786, 1.0]])
                                    
                                    var dbNodeTransformArray : Array = [[Float]]
                                    var dbNodePictures : Array = [""]
                                    for (key, value) in rootDict {
                                        if (key as? String == "transformArray") {
                                            dbNodeTransformArray = value as! Array
                                        } else if (key as? String == "pictures") {
                                            dbNodePictures = value as! Array
                                        } else {
                                            
                                        }
                                    }
                                    
                                    let imagePlane = SCNPlane(width: self.sceneView.bounds.width / 6000, height: self.sceneView.bounds.height / 6000)
                                    let picRef = databaseRef.child("/pictures/\(dbNodePictures[0])/url")
                                    picRef.observeSingleEvent(of: .value, with :{ (snapshot) in
                                        let skimage = makeSKSceneFromImage(image: snapshot.valueInExportFormat() as! NSURL, size: CGSize)
                                        imagePlane.firstMaterial?.diffuse.contents = skimage
                                    })
                                    imagePlane.firstMaterial?.lightingModel = .constant
                                    imagePlane.firstMaterial?.diffuse.contentsTransform = SCNMatrix4MakeScale(1,-1,1);
                                    imagePlane.firstMaterial?.diffuse.wrapT = SCNWrapMode.init(rawValue: 2)!;
                                    imagePlane.firstMaterial?.isDoubleSided = true
                                    imagePlane.cornerRadius = self.sceneView.bounds.height / (3000 * 10)
                                    
                                    let childNode = SCNNode(geometry: imagePlane)
                                    var transformArray : simd_float4x4
                                        
                                    let columns = [float4].init()
                                    for array in dbNodeTransformArray {
                                        var temp = [Float].init()
                                        for value in array {
                                            temp.append(value)
                                        }
                                        let floatFour = float4.init(temp)
                                        columns.append(floatFour)
                                    }
                                    transformArray = simd_float4x4.init(columns)
                                    
                                    childNode.simdTransform = transformArray
                                    
                                    prevRootNode.addChildNode(childNode)
                                })
                            }
                            let components = self.getSCNVectorComponentsBetween(currLocation: self.currentLocation, prevLocation: prevRootLocation)
                            let childPosition = SCNVector3(components.0, components.1, components.2)
                            prevRootNode.position = childPosition
                            
                            self.sceneView.scene.rootNode.addChildNode(prevRootNode)
                        } catch {
                            print(error)
                        }
                    }
                }
            } else {
                print("Error in retrieving snapshot")
            }
        })
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
                setupFirebase()
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
    var sessionConfig = ARWorldTrackingSessionConfiguration()
    
    
    var use3DOFTracking = false {
        didSet {
            if use3DOFTracking {
                sessionConfig = ARSessionConfiguration() as! ARWorldTrackingSessionConfiguration
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
    
    func displayVirtualObjectTransform() {
        
        guard let object = picture, let cameraTransform = session.currentFrame?.camera.transform else {
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
        
        guard let object = picture, let cameraTransform = session.currentFrame?.camera.transform else {
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
    
    func resetVirtualObject() {
        picture?.unload()
        picture?.removeFromParentNode()
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
    
    var picture: Picture?
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
            self.picture = object
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
    
    @IBAction func chooseObject(_ button: UIButton) {
        //        // Abort if we are about to load another object to avoid concurrent modifications of the scene.
        //        if isLoadingObject { return }
        //
        //        textManager.cancelScheduledMessage(forType: .contentPlacement)
        //
        //        let rowHeight = 45
        ////        let popoverSize = CGSize(width: 250, height: rowHeight * VirtualObject.availableObjects.count)
        //        let popoverSize = CGSize(width: 250, height: rowHeight * 1)
        //        let objectViewController = VirtualObjectSelectionViewController(size: popoverSize)
        //        objectViewController.delegate = self
        //        objectViewController.modalPresentationStyle = .popover
        //        objectViewController.popoverPresentationController?.delegate = self
        //        self.present(objectViewController, animated: true, completion: nil)
        //
        //        objectViewController.popoverPresentationController?.sourceView = button
        //        objectViewController.popoverPresentationController?.sourceRect = button.bounds
        
        let imagePickerVC = ImagePickerViewController()
        imagePickerVC.delegate = self
        imagePickerVC.modalPresentationStyle = .popover
        imagePickerVC.popoverPresentationController?.delegate = self
        self.present(imagePickerVC, animated: true, completion: nil)
        
        imagePickerVC.popoverPresentationController?.sourceView = button
        imagePickerVC.popoverPresentationController?.sourceRect = button.bounds
    }
    func imagePickerViewController(_: ImagePickerViewController, didSelectImage image: UIImage) {
        obj = image
        print(obj?.size)
        print("----------------------------------------------------------------------------------------------------------------!!")
    }
    func imagePickerViewControllerDidCancel(_: ImagePickerViewController){
        print("----------------------------------------------------------------------------------------------------------------!!")
    }
    
    
    // MARK: - Plane Detection
    
    func restartPlaneDetection() {
        
        // configure session
        if let worldSessionConfig = sessionConfig as? ARWorldTrackingSessionConfiguration {
            //            worldSessionConfig.planeDetection = .horizontal
            print("lalala")
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
            self.featurePointCountLabel.text = "Features: \(cloud.count)".uppercased()
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

