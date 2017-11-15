//
//  Extensions.swift
//  ARKitExample
//
//  Created by Andrew Jay Zhou on 8/2/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit
import SpriteKit
import FirebaseDatabase

extension UIView {
    func addConstraintsWithFormat(_ format: String, views: UIView...) {
        var viewsDictionary = [String: UIView]()
        for (index, view) in views.enumerated() {
            let key = "v\(index)"
            view.translatesAutoresizingMaskIntoConstraints = false
            viewsDictionary[key] = view
        }
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: format, options: NSLayoutFormatOptions(), metrics: nil, views: viewsDictionary))
    }
}

let imageCache = NSCache<NSString, UIImage>()

class CustomImageView : UIImageView {
    
    var imageUrlString: String?
    
    func loadImageUsingUrlString(urlString: String) {
        
        imageUrlString = urlString
        
        var outputImage = UIImage()
        do {
            let input : NSData = try NSData(contentsOf: URL(string: urlString)!)
            if input.imageFormat == .JPEG || input.imageFormat == .PNG || input.imageFormat == .TIFF {
                outputImage = UIImage.init(data: input as Data)!
            } else if input.imageFormat == .GIF {
                outputImage = UIImage.gif(data: input as Data)!
            } else {
                print("not acceptable format of image")
            }
        } catch {
            print("Error in converting picurl to NSData")
        }
        
        if let imageFromCache = imageCache.object(forKey: urlString as NSString) {
            self.image = imageFromCache
            return
        }
        let imageToCache = outputImage
        
        if self.imageUrlString == urlString {
            self.image = imageToCache
        }
        
        imageCache.setObject(imageToCache, forKey: urlString as NSString)
    }
}
