//
//  LibraryGrid.swift
//  ARKitExample
//
//  Created by Andrew Jay Zhou on 8/2/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit
import Photos
import Alamofire
import SwiftyJSON

class LibraryGrid: UIView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
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
    let assets = {
       return PHAsset.fetchAssets(with: .image, options: nil)
    }()
    let manager = PHImageManager.default()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        fetchContent()
        
        collectionView.register(GridCell.self, forCellWithReuseIdentifier: cellId)
        
        addSubview(collectionView)
        addConstraintsWithFormat("H:|[v0]|", views: collectionView)
        addConstraintsWithFormat("V:|[v0]|", views: collectionView)
        
        collectionView.heightAnchor.constraint(equalToConstant: 196).isActive = true
        
        let selectedIndexPath = IndexPath(item: 0, section: 0)
        collectionView.selectItem(at: selectedIndexPath, animated: false, scrollPosition: UICollectionViewScrollPosition())
    }
        
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets.count
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let length = frame.height / 2 - 2
        return CGSize.init(width: length, height: length)
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! GridCell
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors =  [NSSortDescriptor.init(key: "creationDate", ascending: true)]
        let fetchResult: PHFetchResult = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: fetchOptions)
        if fetchResult.count > 0 {
            manager.requestImageData(for: fetchResult.object(at: fetchResult.count - 1 - indexPath.row) as PHAsset, options: PHImageRequestOptions(), resultHandler: {contentData, string, orientation, hashable in
                if let data = contentData {
                    let info = Content()
                    info.data = data
                    
                    if (string?.contains(".gif"))! {
                        cell.imageView.image = UIImage.gif(data: data)
                        
                        info.type = .gif
                        cell.info = info
                        
                    } else {
                        cell.imageView.image = UIImage(data: data)
                        
                        info.type = .image
                        cell.info = info
                    }
                }
            })
            
        }
        
        
        return cell
    }
    
    var viewController : ViewController?
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as? GridCell
        if let content = cell?.info {
            viewController?.content = content
            // edit the image
            viewController?.openPhotoEditor(data: content.data!)
        }
    }
    
    func fetchContent(){}
    
//    func getURL(ofPhotoWith mPhasset: PHAsset, completionHandler : @escaping ((_ responseURL : URL?) -> Void)) {
//
//        if mPhasset.mediaType == .image {
//            let options: PHContentEditingInputRequestOptions = PHContentEditingInputRequestOptions()
//            options.canHandleAdjustmentData = {(adjustmeta: PHAdjustmentData) -> Bool in
//                return true
//            }
//            mPhasset.requestContentEditingInput(with: options, completionHandler: { (contentEditingInput, info) in
//                completionHandler(contentEditingInput!.fullSizeImageURL)
//            })
//        } else if mPhasset.mediaType == .video {
//            let options: PHVideoRequestOptions = PHVideoRequestOptions()
//            options.version = .original
//            PHImageManager.default().requestAVAsset(forVideo: mPhasset, options: options, resultHandler: { (asset, audioMix, info) in
//                if let urlAsset = asset as? AVURLAsset {
//                    let localVideoUrl = urlAsset.url
//                    completionHandler(localVideoUrl)
//                } else {
//                    completionHandler(nil)
//                }
//            })
//        }
//
//    }
}


class GridCell: BaseCell {
    let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor.purple
        
        return iv
    }()
    
    var info : Content?
    
    override func setupViews() {
        super.setupViews()
        
        addSubview(imageView)
        addConstraintsWithFormat("H:|[v0]|", views: imageView)
        addConstraintsWithFormat("V:|[v0]|", views: imageView)
    }
}

