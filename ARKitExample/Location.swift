//
//  Location.swift
//  ARKitExample
//
//  Created by Andrew Jay Zhou on 7/11/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import Foundation
import ARKit
import SceneKit
import CoreLocation

class Location {
    var pic: Picture?
    var camLocation: CLLocation
    var camTransform: matrix_float4x4
    var vecToPic: SCNVector3
    
    var viewController: ViewController?
    
    init(picture: Picture, cameraLocation: CLLocation, cameraTransform: matrix_float4x4){
        self.pic = picture
        self.camLocation = cameraLocation
        self.camTransform = cameraTransform
        
        let cameraPos = SCNVector3.positionFromTransform(cameraTransform)
        self.vecToPic = pic!.position - cameraPos
    }
    
    // Supply location information
    func cameraLocation() -> CLLocation { return self.camLocation}
    
    func cameraTransform() -> matrix_float4x4 { return self.camTransform }
    
    func vectorToPicture() -> SCNVector3 { return self.vecToPic }
    
    func picture() -> Picture { return self.pic! }
    
    
    // Update locaiton information
    func updateLocation(picture: Picture, cameraLocation: CLLocation, cameraTransform: matrix_float4x4) {
        self.pic = picture
        self.camLocation = cameraLocation
        self.camTransform = cameraTransform
        
        let cameraPos = SCNVector3.positionFromTransform(cameraTransform)
        self.vecToPic = picture.position - cameraPos
    }
    
    
}
