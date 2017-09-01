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
        sender.isSelected = !sender.isSelected
        
        switch editBoard.drawState {
            
        case .drawing:
            editBoard.pauseDrawing()
        case .paused:
            editBoard.resumeDrawing()
        case .inactive:
            editBoard.beginDrawing()
            
        }
        
        if sender.isSelected {
            showButtonsForDrawing()
        } else {
            hideButtonsForDrawing()
        }
    }
    
    @objc func handleUndoButton(sender: UIButton!) {
        editBoard.undoDrawing()
    }
    
    @objc func handleTextButton(sender: UIButton!) {
        editBoard.pauseDrawing()
        editBoard.addText()
    }
    
    @objc func handleClearButton(sender: UIButton!) {
        editBoard.reset()
        hideContentStack()
        
        dismissEditBoard()
        
        UIView.animate(withDuration: 0.1, delay: 0.3, options: .curveEaseOut, animations: {
            self.addObjectButton.alpha = 1
            self.addObjectButton.transform = .identity
        }, completion: nil)
        
        let selectionButton = contentStack.subviews[0] as! UIButton
        selectionButton.isSelected = false
    
    }
    
    @objc func handleFinishButton(sender: UIButton!) {
        if isGif {
            setPreview(content: UIImage.gif(data: (content?.data)!)!)
        } else {
        
            UIGraphicsBeginImageContextWithOptions(editBoard.bounds.size, false, UIScreen.main.scale)
            editBoard.layer.render(in: UIGraphicsGetCurrentContext()!)
            let image = UIGraphicsGetImageFromCurrentImageContext()!
            setPreview(content: image)
            UIGraphicsEndImageContext()
        }
        hideContentStack()
        showPreview()
        dismissEditBoard() 
    }
    
    
    
    
}
