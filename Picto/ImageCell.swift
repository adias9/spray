//
//  ImageCell.swift
//  ARKitExample
//
//  Created by Andreas Dias on 11/13/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit
import SDWebImage

class ImageCell: UICollectionViewCell {
    
    var image : dbPicture? {
        didSet {
            setupThumbnailImage()
        }
    }
    
    func setupThumbnailImage() {
        if let imageURL = image?.url {
            
            DispatchQueue.main.async {
                self.thumbnailImageView.sd_setImage(with: URL(string: imageURL))
//                self.thumbnailImageView.loadImageUsingUrlString(urlString: imageURL)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    let thumbnailImageView: CustomImageView = {
        let imageView = CustomImageView.init(frame: CGRect.zero)
        imageView.backgroundColor = UIColor.red
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    func setupViews() {
        contentView.addSubview(thumbnailImageView)
        let layoutGuide = contentView.layoutMarginsGuide
        
        thumbnailImageView.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor).isActive = true
        thumbnailImageView.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor).isActive = true
        thumbnailImageView.widthAnchor.constraint(equalTo: layoutGuide.widthAnchor).isActive = true
        thumbnailImageView.topAnchor.constraint(equalTo: layoutGuide.topAnchor, constant: -1).isActive = true
        thumbnailImageView.bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor, constant: 1).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
