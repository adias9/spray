//
//  EditBoard.swift
//  ARKitExample
//
//  Created by Andrew Jay Zhou on 8/17/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit

class EditBoard : UIView{
    
    let length : CGFloat = UIScreen.main.bounds.width * 0.93
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.black
        alpha = 0.8
        
        widthAnchor.constraint(equalToConstant: length).isActive = true
        heightAnchor.constraint(equalToConstant: length).isActive = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
