//
//  File.swift
//  ARKitExample
//
//  Created by Andrew Jay Zhou on 8/16/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit

extension ViewController {
    
    func setupPreview() {
        preview.backgroundColor = UIColor.black
        view.addSubview(preview)
        
        let viewWidth = view.frame.width
        let viewHeight = view.frame.height
        let previewWidth = CGFloat(80)
        let previewHeight = CGFloat(80 )
        let bottomMargin = CGFloat(15)
        
        view.addConstraintsWithFormat("H:|-\((viewWidth - previewWidth)/2)-[v0]-\((viewWidth - previewWidth)/2)-|", views: preview)
        view.addConstraintsWithFormat("V:|-\(viewHeight - bottomMargin - previewHeight)-[v0]-\(bottomMargin)-|", views: preview)
        
        preview.isHidden = true
        preview.isUserInteractionEnabled = true
    }
    
    func showPreview() {
//        guard let content = self.content else {
//            return
//        }
//        if content.type == .gif {
//            if let data = content.data {
//                preview.image = UIImage.gif(data: data)
//            }
//        } else {
//            if let data = content.data {
//                preview.image = UIImage(data: data)
//            }
//        }
        
        configureGesturesForState(state: .place)
        showPlaceObjectButton(bool: false)
        preview.isHidden = false
    }
    
    func hidePreview() {
        preview.isHidden = true
        showPlaceObjectButton(bool: true)
    }
    
    func setPreview(content: UIImage) {
        preview.image = content
        input = content
    }
    
    
}
