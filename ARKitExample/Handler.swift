//
//  Handler.swift
//  ARKitExample
//
//  Created by Andrew Jay Zhou on 8/16/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit

extension ViewController {
    
    @objc func keyboardWillShow(notification: NSNotification) {
        configureGesturesForState(state: .keyboard)
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue{
            print(keyboardSize)
            if let constraint = contentStackBotAnchor {
                let topLeftPos = view.frame.height - contentStack.frame.origin.y
                if topLeftPos == contentStack.frame.height{
                    //                stack.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = false
                    ////                stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -keyboardSize.height).isActive = true
                    //                self.stack.frame.origin.y -= keyboardSize.height
                    UIView.animate(withDuration: 1.5, animations: {
                        //                    constraint.constant = -keyboardSize.height
                        // TODO: SoftCode this
                        constraint.constant = -226.0
                        self.view.layoutIfNeeded()
                    })
                }
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        configureGesturesForState(state: .selection)
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue{
            if let constraint = contentStackBotAnchor{
                let topLeftPos = view.frame.height - contentStack.frame.origin.y
                if topLeftPos != contentStack.frame.height{
                    //                self.contentStack.frame.origin.y += keyboardSize.height
                    ////                stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -keyboardSize.height).isActive = false
                    //                contentStack.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
                    UIView.animate(withDuration: 1.5, animations: {
                        constraint.constant = 0
                        self.view.layoutIfNeeded()
                    })
                }
            }
        }
    }
    
    
    
    
}
