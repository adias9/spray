//
//  VC+CubeManager.swift
//  ARKitExample
//
//  Created by Andreas Dias on 11/9/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseStorage
import SpriteKit

extension ViewController {
    
    // update this later to only update square that gets changed and not the whole cube each time
    func startUpdatingCubeImages() {
        if let school = cube?.school, let sub_cube = cube?.sub_cube {
            cubeUpdateRef = Database.database().reference().child("/cubes/\(school)/\(sub_cube)")
            
            var count = 0
            for i in 1...4 {
                for j in 1...16 {
                    let sideName = "side" + String(i)
                    let pixName = "pix" + String(j)
                    let pixUpdateHandler = cubeUpdateRef.child("\(sideName)/\(pixName)").observe(.value, with: { (snapshot) in
                        if snapshot.exists() {
                            
                            // fetch the side and individual pictures needing to be changed
                            let picDict = snapshot.valueInExportFormat() as! NSDictionary
                            
                            let dbCubePicture = picDict.value(forKey: "picture") as! String
                            let nodeName = pixName + sideName
                            self.updatePic(nodeName: nodeName, picName: dbCubePicture)
                        }
                        count += 1
                        if count == 64 {
                            self.dismissCubeLoadingScreen()
                        }
                    })
                    cubeUpdateHandlerArr.append(pixUpdateHandler)
                }
            }
        } else {
            self.dismissCubeLoadingScreen()
        }
    }
    
    func showCubeLoadingScreen() {
        let alert = UIAlertController(title: nil, message: "Loading Cube...", preferredStyle: .alert)
        
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        loadingIndicator.startAnimating();
        
        alert.view.addSubview(loadingIndicator)
        self.present(alert, animated: true, completion: nil)
    }
    
    func dismissCubeLoadingScreen() {
        dismiss(animated: false, completion: nil)
    }
    
    private func updatePic(nodeName: String, picName: String) {
        let databaseRef = Database.database().reference()
        let picRef = databaseRef.child("/pictures/\(picName)/url")
        picRef.observeSingleEvent(of: .value, with :{ (snapshot) in
            if snapshot.exists() {
                // need to get actual pic not just db rep get picture from database ref
                let picUrl = snapshot.valueInExportFormat() as! String
        
                var skimage = SKScene()
                do {
                    let input : NSData = try NSData(contentsOf: URL(string: picUrl)!)
                    if input.imageFormat == .JPEG || input.imageFormat == .PNG || input.imageFormat == .TIFF {
                        skimage = SKScene.makeSKSceneFromImage(url: NSURL(string: picUrl)!, size: CGSize(width: self.sceneView.frame.width, height: self.sceneView.frame.height))
                    } else if input.imageFormat == .GIF {
                        skimage = SKScene.makeSKSceneFromGif(url: NSURL(string: picUrl)!, size: CGSize(width: self.sceneView.frame.width, height: self.sceneView.frame.height))
                    } else {
                        print("not acceptable format of image")
                    }
                } catch {
                    print("Error in converting picurl to NSData")
                }
                
                DispatchQueue.global().async {
                    self.editNode(content: skimage, nodeName: nodeName)
                }
            }
        })
    }
    
    func stopUpdatingCubeImages() {
        if cubeUpdateHandlerArr.count != 0 {
            for i in 0...(cubeUpdateHandlerArr.count - 1) {
                cubeUpdateRef.removeObserver(withHandle: cubeUpdateHandlerArr[i])
            }
        }
    }
    
}
