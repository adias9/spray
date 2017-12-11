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
import SDWebImage

extension ViewController {
    
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
                            let dbCubeUrl = picDict.value(forKey: "url") as! String
                            let nodeName = pixName + sideName
                            self.updatePic(nodeName: nodeName, picID: dbCubePicture, picURL: dbCubeUrl)
                        }
                    })
                    count += 1
                    if count == 64 {
                        self.dismissCubeLoadingScreen()
                    }
                    cubeUpdateHandlerArr.append(pixUpdateHandler)
                }
            }
        } else {
            // this happens when school or sub_cube not initialized
            dismissCubeLoadingScreen()
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
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    private func updatePic(nodeName: String, picID: String, picURL: String) {
        
        let reference = Storage.storage().reference().child("pictures/\(picID)")
        
        reference.getMetadata { metadata, error in
            if let error = error {
                // Uh-oh, an error occurred!
                print("Error: \(error)")
            } else {
                let type = metadata?.contentType
                let imageView = UIImageView.init()
                imageView.sd_setImage(with: URL(string: picURL), placeholderImage: UIImage(named: "picto.png"), completed: { (image, error, cacheType, imageURL) in
                    DispatchQueue.main.async {
                        if type == "image/gif" {
                            // in the future should use URL here instead of image returned from SD_SETIMAGE
                            let sk = SKScene.makeSKSceneFromGif(url: NSURL(string: picURL)!, size:  CGSize(width: self.sceneView.frame.width, height: self.sceneView.frame.height))
                            self.editGIFImageNode(skscene: sk, nodeName: nodeName)
                        } else {
                            self.editImageNode(content: imageView, nodeName: nodeName)
                        }
                    }
                })
            }
        }
    }
    
    func stopUpdatingCubeImages() {
        if cubeUpdateHandlerArr.count != 0 {
            for i in 0...(cubeUpdateHandlerArr.count - 1) {
                cubeUpdateRef.removeObserver(withHandle: cubeUpdateHandlerArr[i])
            }
        }
    }
    
}
