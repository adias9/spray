//
//  Content.swift
//  ARKitExample
//
//  Created by Andrew Jay Zhou on 8/7/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import Foundation
class Content : NSObject {
    
    var data : Data?
    var type : ContentType?
    
    enum ContentType {
        case image
        case gif
    }
}
