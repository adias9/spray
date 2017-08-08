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
import MobileCoreServices

class ViewController: UIViewController, ARSCNViewDelegate, UIPopoverPresentationControllerDelegate,  CLLocationManagerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate {
    
    var deleteMode: Bool = false
    var tapAdd: UITapGestureRecognizer?
    var tapDelete: UITapGestureRecognizer?
    var longPressDelete: UILongPressGestureRecognizer?
    var longPressDarken: UILongPressGestureRecognizer?
    var tapPreviewToStack : UITapGestureRecognizer?
    var url: NSURL?
    lazy var stdLen: CGFloat = {
        let len = self.sceneView.bounds.height / 3000
        return len
    }()
    
    // MARK: - Main Setup & View Controller methods
    override func viewDidLoad() {
        super.viewDidLoad()

        Setting.registerDefaults()
        setupScene()
        setupDebug()
        setupUIControls()
        setupLocationManager()
		updateSettings()
		resetVirtualObject()
        setupMenuBar()
        setupGestures()
        setupPreview()
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
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
        showContentStack()
    }
    
    func showContentStack() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.contentStack.transform = .identity
            }, completion: nil)
        
        configureGesturesForState(state: .selection)
    }
    
    func hideContentStack() {
        UIView.animate(withDuration: 1.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.contentStack.transform = CGAffineTransform(translationX: 0, y: self.view.frame.height)
        }, completion: nil)
        
        configureGesturesForState(state: .view)
    }
    
    func showPreview() {
        guard let content = self.content else {
            return
        }
        if content.type == .gif {
            if let data = content.data {
                preview.image = UIImage.gif(data: data)
            }
        } else {
            if let data = content.data {
                preview.image = UIImage(data: data)
            }
        }
        
        configureGesturesForState(state: .place)
        showPlaceObjectButton(bool: false)
        preview.isHidden = false
    }
    func hidePreview() {
        preview.isHidden = true
        showPlaceObjectButton(bool: true)
    }
    
    func showPlaceObjectButton(bool : Bool) {
        contentStackButton.isEnabled = bool
        contentStackHitArea.isEnabled = bool
        contentStackButton.isHidden = !bool
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
        case library
        case meme
        case gif
        case sticker
    }

    let contentStack = UIStackView()
    let libraryGrid = LibraryGrid()
    let memeGrid = LibraryGrid()
    let gifGrid = GifGrid()
    let stickerGrid = LibraryGrid()
    func setupMenuBar() {
        let menuBar = MenuBar()
        menuBar.viewController = self
        libraryGrid.viewController = self
        memeGrid.viewController = self
        gifGrid.viewController = self
        stickerGrid.viewController = self
        
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
        container.addSubview(stickerGrid)
        container.addConstraintsWithFormat("H:|[v0]|", views: stickerGrid)
        container.addConstraintsWithFormat("V:|[v0]|", views: stickerGrid)
        
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
        
        contentStack.transform = CGAffineTransform(translationX: 0, y: view.frame.height)
    }
    func showGrid(type : ContentType) {
        let grid = contentStack.subviews[1]
        if type == .library {
            grid.bringSubview(toFront: libraryGrid)
        } else if type == .meme{
            grid.bringSubview(toFront: memeGrid)
        } else if type == .gif{
            grid.bringSubview(toFront: gifGrid)
        } else {
            grid.bringSubview(toFront: stickerGrid)
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
    
    // MARK: - Gesture Recognizers
    var tapDismissKeyboard : UITapGestureRecognizer?
    @objc func dismissKeyboard(tap: UITapGestureRecognizer) {
        let grid = contentStack.arrangedSubviews[1]
        grid.endEditing(true)
    }
    
    var content : Content?
    // Adding Objects
    @objc func placeObject(gestureRecognize: UITapGestureRecognizer){
        guard let obj = content else {
            textManager.showMessage("Please select an output!!")
            return
        }
        
        // Set content
        if (obj.type == .gif) { // content is gif
            guard let data = obj.data else {return}
            let content = SKScene.makeSKSceneFromGif(data: data, size:  CGSize(width: sceneView.frame.width, height: sceneView.frame.height))
            createNode(content: content)
        } else { // content is picture
            guard let data = obj.data else {return}
            let content = SKScene.makeSKSceneFromImage(data: data,
                                                        size: CGSize(width: sceneView.frame.width, height: sceneView.frame.height))
             createNode(content: content)
        }
        
        // ----------------------------------------------------------------------------------------------------
        
//        //file:///var/mobile/Media/PhotoStreamsData/1020202307/100APPLE/IMG_0153.JPG
//        let obj = NSURL(string: "assets-library://asset/asset.JPG?id=EA05C3C1-0FE4-43B9-8A10-2AE932CDDE4D&ext=JPG")
//        let content = SKScene.makeSKSceneFromImage(url: obj!,
//                                                   size: CGSize(width: sceneView.frame.width, height: sceneView.frame.height))
//        createNode(content: content)
        
        
    }
    
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
        
        self.sceneView.scene.rootNode.addChildNode(wrapperNode)
    }
    
    // Deleting Object
    var longPressDeleteFired: Bool = false
    @objc func darkenObject(shortPress: UILongPressGestureRecognizer) {
        var skScene: SKScene?
        
        if shortPress.state == .began {
            let point = shortPress.location(in: view)
            let scnHitTestResults = sceneView.hitTest(point, options: nil)
            if let result = scnHitTestResults.first {
                skScene = result.node.geometry?.firstMaterial?.diffuse.contents as! SKScene
                let darken = SKAction.colorize(with: .black, colorBlendFactor: 0.4, duration: 0)
                skScene!.childNode(withName: "content")?.run(darken)
            }
        }
        
        if shortPress.state == UIGestureRecognizerState.ended{
            if !longPressDeleteFired {
                let point = shortPress.location(in: view)
                let scnHitTestResults = sceneView.hitTest(point, options: nil)
                if let result = scnHitTestResults.first {
                    skScene = result.node.geometry?.firstMaterial?.diffuse.contents as! SKScene
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
    
    var target: SCNNode?
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
    
    // Gesture Recognizer Delegates
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UILongPressGestureRecognizer &&
            otherGestureRecognizer is UILongPressGestureRecognizer {
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
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
		session.pause()
	}
	
    // MARK: - ARKit / ARSCNView
    let session = ARSession()
    var sessionConfig = ARWorldTrackingSessionConfiguration()
    
    
	var use3DOFTracking = false {
		didSet {
			if use3DOFTracking {
//                sessionConfig = ARSessionConfiguration() as! ARWorldTrackingSessionConfiguration
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
            
            
            // create Location Object for picture
            guard let cameraTransform = self.session.currentFrame?.camera.transform, let camLocation = self.userLocation else {
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
            
            tapAdd?.isEnabled = false
            tapDelete?.isEnabled = false
            tapDismissContentStack?.isEnabled = false
            tapDismissKeyboard?.isEnabled = false
            tapPreviewToStack?.isEnabled = false
        } else if state == .selection {
            tapDismissContentStack?.isEnabled = true
            
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
    @IBOutlet weak var contentStackHitArea: UIButton!
    
    @IBOutlet weak var contentStackButton: UIButton!
    
    // MARK: - Image Picker and Delegate
    var tapDismissContentStack : UITapGestureRecognizer?
    @IBAction func chooseObject(_ button: UIButton) {
        showContentStack()
    }
    
    @objc func dismissContentStack(gestureRecognize: UITapGestureRecognizer){
        let point = gestureRecognize.location(in: view)
        let safety = CGFloat(10.0)
        
        if point.y < (contentStack.frame.origin.y - safety) {
            hideContentStack()
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        url = info[UIImagePickerControllerImageURL] as! NSURL
        self.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
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
		use3DOFTracking	= defaults.bool(for: .use3DOFTracking)
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
    
    // MARK: - Location Manager and Delegate
    let locationManager = CLLocationManager()
    var userLocation: CLLocation?
    var rootLocation: CLLocation?
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations[0]
        print(userLocation!)
        // Calculate root node location
//        guard let cameraTransform = session.currentFrame?.camera.transform else {
//            return
//        }
//
//        let cameraPos = SCNVector3.positionFromTransform(cameraTransform)
//        let root = sceneView.scene.rootNode
//        let vectorToRoot = root.position - cameraPos
        
//        let distanceToRoot = vectorToRoot.length()
    }
    
    // setupLocationManager()
    func setupLocationManager(){
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        //later use locationManager.requestAlwaysAuthorization() if needed
        locationManager.startUpdatingLocation()
        // figure out when to stopUpdatingLocation() to preserve battery
        // For now, not startUpdatingHeading() - orientation of picture is fixed, matches camera orientation
    }
}
