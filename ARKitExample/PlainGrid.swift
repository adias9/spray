//
//  PlainGrid.swift
//  ARKitExample
//
//  Created by Andreas Dias on 10/17/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit

class PlainGrid : UIView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    
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
    var assets = [UIImage]()
    
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
    
    func fetchContent() {
        let resourcePath = Bundle.main.resourcePath! + "/gradients"
        var resourcesContent : [String] {
            var result = [String]()
            do {
                result = try FileManager().contentsOfDirectory(atPath: resourcePath)
            } catch {
                print(error)
            }
            return result
        }
        count = resourcesContent.count
        for img in resourcesContent {
            assets.append(UIImage.init(contentsOfFile: resourcePath + "/" + img)!)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return count
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let length = frame.height / 2 - 2
        return CGSize.init(width: length, height: length)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! GridCell
        
        guard let data = try? UIImageJPEGRepresentation(assets[indexPath.item], 1.0) else {
            print("Error with content data")
            return cell
        }
        let content = assets[indexPath.item]
        cell.imageView.backgroundColor = UIColor.clear
        cell.imageView.image = content
        
        let info = Content()
        info.data = data
        info.type = .image
        cell.info = info
        
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
        }
        viewController?.contentStack.isHidden = true
        viewController?.showPreview()
    }
}

