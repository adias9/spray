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
    
    @objc func handleDrawButton(sender: UIButton!) {
        drawView.isActive = true
        editBoard.addSubview(drawView)
        editBoard.addConstraintsWithFormat("H:|[v0]|", views: drawView)
        editBoard.addConstraintsWithFormat("V:|[v0]|", views: drawView)
    }
    
    @objc func handleUndoButton(sender: UIButton!) {
        drawView.undo()
    }
    
    @objc func handleTextButton(sender: UIButton!) {
        drawView.isActive = false
        editBoard.addSubview(textView)
        textView.frame = CGRect.init(x: 0, y: 0, width: 62, height: 62)
        textView.center = editBoard.center
    }
    
    @objc func handleClearButton(sender: UIButton!) {
        editBoard.reset()
        drawView.reset()
        hideContentStack()
    }
    
    @objc func handleFinishButton(sender: UIButton!) {
        UIGraphicsBeginImageContextWithOptions(editBoard.bounds.size, false, UIScreen.main.scale)
        editBoard.layer.render(in: UIGraphicsGetCurrentContext()!)
        preview.image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        hideContentStack()
        showPreview()
    }
    
    
    
    
}
