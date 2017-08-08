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

class GifGrid : UIView, UISearchBarDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 1
        layout.minimumInteritemSpacing = 2
        layout.scrollDirection = .horizontal
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = UIColor.white
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()
    let cellId = "cellId"
    var count = 0
    var sources = [String]()
    var sizes = [CGSize]()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        fetchContent()
        
        collectionView.register(GridCell.self, forCellWithReuseIdentifier: cellId)
        addSubview(collectionView)
        
        let selectedIndexPath = IndexPath(item: 0, section: 0)
        collectionView.selectItem(at: selectedIndexPath, animated: false, scrollPosition: UICollectionViewScrollPosition())
        
        let searchBar = UISearchBar()
        searchBar.tintColor = UIColor.green
        searchBar.barTintColor = UIColor.green
        searchBar.delegate = self
        addSubview(searchBar)
        searchBar.bottomAnchor.constraint(equalTo: collectionView.topAnchor).isActive = true
        
        addConstraintsWithFormat("H:|[v0]|", views: collectionView)
        addConstraintsWithFormat("H:|[v0]|", views: searchBar)
        addConstraintsWithFormat("V:|[v0(32)][v1(196)]|", views: searchBar,collectionView)
    }
    
    func fetchContent() {
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
        if let text = searchText {
            let url = URL(string: "http://text2gif.guggy.com/v2/guggify")
            let apiKey = "45P8xNDXBNsnNzh"
            let parameters: [String: String] = [
                "sentence" : text,
                "lang" : "en"
            ]
            let headers: [String: String] = [
                "content-type" : "application/json",
                "apiKey" : apiKey
            ]
            
            Alamofire.request(url!, method: .post, parameters:  parameters, encoding: JSONEncoding.default, headers: headers).responseData(completionHandler: {(responseData) -> Void in
                if (responseData.data != nil) {
                    self.sources.removeAll()
                    self.parseData(data: responseData.data!)
                }
            })
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return count
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if (sizes.count != 0){
            let currentSize = sizes[indexPath.item]
            let aspectRatio = currentSize.width / currentSize.height
//            let newHeight = collectionView.nframe.height / 2 - 2
            let newHeight = collectionView.frame.height
            let newWidth = newHeight * aspectRatio
            return CGSize.init(width: newWidth, height: newHeight)
        }
        let length = collectionView.frame.height / 2 - 2
        return CGSize.init(width: length, height: length)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! GridCell
        
        guard let data = try? Data.init(contentsOf: URL(string: sources[indexPath.item])!) else {
            print("Error with content data")
            return cell
        }
        let content = UIImage.gif(data: data)
        cell.imageView.backgroundColor = UIColor.clear
        cell.imageView.image = content
        
        let info = Content()
        info.data = data
        info.type = .gif
        cell.info = info
      
        return cell
    }
    
    
    func parseData(data : Data) {
        let parsed = JSON(data)
        for (_, elements) in parsed["animated"] {
            let gifPreview = elements["gif"]["preview"]
            let original = gifPreview["url"].string!
            print(original)
            let secured = "https\(original.substring(from: original.index(of: ":")!))"
            sources.append(secured)
            
            let size = CGSize.init(width: gifPreview["dimensions"]["width"].intValue, height: gifPreview["dimensions"]["height"].intValue)
            sizes.append(size)
        }
        count = sources.count
        
        collectionView.reloadData()
        
    }
    
    var searchText : String?
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let text = searchBar.text {
            searchText = text
            fetchContent()
        }
        searchBar.endEditing(true)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var viewController : ViewController?
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as? GridCell
        if let content = cell?.info {
            viewController?.content = content
        }
        viewController?.contentStack.isHidden = true
        viewController?.showPreview()
    }
}
