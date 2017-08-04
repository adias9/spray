//
//  GifGrid.swift
//  ARKitExample
//
//  Created by Andrew Jay Zhou on 8/3/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit
import Photos
import Alamofire
import SwiftyJSON
import Foundation

class GifGrid : LibraryGrid {
    
    var count = 0
    var sources = [String]()
    var sizes = [CGSize]()
    
    override func fetchContent() {
//        let host = "api.giphy.com"
//        let path = "/v1/stickers/search"
//        let q = "doge"
//        let apiKey = "80a8f5bf38594d7eb0bdf8289966b948"
//        let url = "http://\(host)/\(path)?q=\(q)&api_key=\(apiKey)"
//
//        Alamofire.request(url).responseData(completionHandler: {(responseData) -> Void in
//            if (responseData.data != nil) {
//                self.parseData(data: responseData.data!)
//                print(responseData.data!)
//            }
//        })
        
        //Sending a /guggify request with no sentence param will return trending results
        let url = URL(string: "http://text2gif.guggy.com/v2/guggify")
        let apiKey = "45P8xNDXBNsnNzh"
        let parameters: [String: String] = [
            "sentence" : "life is good",
            "lang" : "en"
        ]
        let headers: [String: String] = [
            "content-type" : "application/json",
            "apiKey" : apiKey
        ]
        
        Alamofire.request(url!, method: .post, parameters:  parameters, encoding: JSONEncoding.default, headers: headers).responseData(completionHandler: {(responseData) -> Void in
            if (responseData.data != nil) {
                self.parseData(data: responseData.data!)
            }
        })
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return count
    }
    
    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if (sizes.count != 0){
            let currentSize = sizes[indexPath.item]
            let aspectRatio = currentSize.width / currentSize.height
            let newHeight = frame.height / 2 - 2
            let newWidth = newHeight * aspectRatio
            return CGSize.init(width: newWidth, height: newHeight)
        }
        let length = frame.height / 2 - 2
        return CGSize.init(width: length, height: length)
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! GridCell
        
        let content = UIImage.gif(url: sources[indexPath.item])
        cell.imageView.backgroundColor = UIColor.clear
        cell.imageView.image = content
        
        
        return cell
    }
    
    
    func parseData(data : Data) {
        let parsed = JSON(data)
        for (_, elements) in parsed["animated"] {
            let gifPreview = elements["gif"]["preview"]
            let original = gifPreview["url"].string!
            let secured = "https\(original.substring(from: original.index(of: ":")!))"
            sources.append(secured)
            
            
            let size = CGSize.init(width: gifPreview["dimensions"]["width"].intValue, height: gifPreview["dimensions"]["height"].intValue)
            sizes.append(size)
        }
        count = sources.count
        
        collectionView.reloadData()
    }
        
}
