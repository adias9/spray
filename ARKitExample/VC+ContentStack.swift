//
//  ContentStack.swift
//  ARKitExample
//
//  Created by Andrew Jay Zhou on 8/16/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit

extension ViewController {
    
    enum ContentType {
        case library
        case meme
        case gif
        case sticker
    }
    
    func setupMenuBar() {
        let buttonWidth: CGFloat = 64
        selectionButton.bounds = CGRect(x: 0, y: 0, width: buttonWidth, height: 0)
        selectionButton.backgroundColor = UIColor.yellow
        selectionButton.widthAnchor.constraint(equalToConstant: buttonWidth).isActive = true
        selectionButton.heightAnchor.constraint(equalToConstant: 16).isActive = true
        selectionButton.translatesAutoresizingMaskIntoConstraints = false
        selectionButton.addTarget(self, action: #selector(controlStack), for: .touchUpInside)
        selectionButton.setImage(UIImage(named: "settings"), for: .normal)
        selectionButton.setImage(UIImage(named: "settingsPressed"), for: .highlighted)

        
        let container = UIView()
        container.addSubview(libraryGrid)
        container.addConstraintsWithFormat("H:|[v0]|", views: libraryGrid)
        container.addConstraintsWithFormat("V:|[v0]|", views: libraryGrid)
        container.addSubview(memeGrid)
        container.addConstraintsWithFormat("H:|[v0]|", views: memeGrid)
        container.addConstraintsWithFormat("V:|[v0]|", views: memeGrid)
        container.addSubview(gifGrid)
        container.addConstraintsWithFormat("H:|[v0]|", views: gifGrid)
        container.addConstraintsWithFormat("V:|[v0]|", views: gifGrid)
        container.addSubview(stickerGrid)
        container.addConstraintsWithFormat("H:|[v0]|", views: stickerGrid)
        container.addConstraintsWithFormat("V:|[v0]|", views: stickerGrid)
        
        let menuBar = MenuBar()
        menuBar.viewController = self
        libraryGrid.viewController = self
        memeGrid.viewController = self
        gifGrid.viewController = self
        stickerGrid.viewController = self
        
        contentStack.addArrangedSubview(selectionButton)
        contentStack.addArrangedSubview(container)
        contentStack.addArrangedSubview(menuBar)
        
        let marginButton = (self.view.bounds.width - buttonWidth) / 2
        contentStack.addConstraintsWithFormat("H:|-\(marginButton)-[v0(\(buttonWidth))]|", views: selectionButton)
        contentStack.addConstraintsWithFormat("H:|[v0]|", views: container)
        contentStack.addConstraintsWithFormat("H:|[v0]|", views: menuBar)
        
        view.addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStackBotAnchor = contentStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        contentStackBotAnchor!.isActive = true
        contentStack.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        contentStack.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        contentStack.axis = .vertical
        contentStack.spacing = 0
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.transform = CGAffineTransform(translationX: 0, y: view.frame.height)
    }
    
    func showGrid(type : ContentType) {
        let grid = contentStack.subviews[contentStack.subviews.count - 1]
        if type == .library {
            grid.bringSubview(toFront: libraryGrid)
        } else if type == .meme{
            grid.bringSubview(toFront: memeGrid)
        } else if type == .gif{
            grid.bringSubview(toFront: gifGrid)
        } else {
            grid.bringSubview(toFront: stickerGrid)
        }
    }
    
    func showContentStack() {
        UIView.animate(withDuration: 0.5, delay: 0.2, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.contentStack.transform = .identity
        }, completion: nil)
        
        configureGesturesForState(state: .selection)
    }
    
    
    func hideContentStack() {
        UIView.animate(withDuration: 1.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.contentStack.transform = CGAffineTransform(translationX: 0, y: self.view.frame.height)
        }, completion: nil)
        
        configureGesturesForState(state: .view)
        hideEditingBUttons()
    }
    
    func setupButtonsForEditing(){
        let hMargin: CGFloat = -0.2 * UIScreen.main.bounds.height
        let wMargin: CGFloat = 32
        
        view.addSubview(drawButton)
        drawButton.setImage(UIImage(named: "draw"), for: .normal)
        drawButton.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        drawButton.addTarget(self, action: #selector(handleDrawButton), for: .touchUpInside)
        drawButton.heightAnchor.constraint(equalToConstant: 32).isActive = true
        drawButton.widthAnchor.constraint(equalToConstant: 32).isActive = true
        drawButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: hMargin).isActive = true
        drawButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: wMargin).isActive = true
        drawButton.translatesAutoresizingMaskIntoConstraints = false
        drawButton.alpha = 0
       
        
        view.addSubview(finishButton)
        finishButton.setImage(UIImage(named: "done"), for: .normal)
        finishButton.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        finishButton.addTarget(self, action: #selector(handleFinishButton), for: .touchUpInside)
        finishButton.heightAnchor.constraint(equalToConstant: 32).isActive = true
        finishButton.widthAnchor.constraint(equalToConstant: 32).isActive = true
        finishButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: hMargin).isActive = true
        finishButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -wMargin).isActive = true
        finishButton.translatesAutoresizingMaskIntoConstraints = false
        finishButton.alpha = 0
      
        
        view.addSubview(textButton)
        textButton.setImage(UIImage(named: "text"), for: .normal)
        textButton.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        textButton.addTarget(self, action: #selector(handleTextButton), for: .touchUpInside)
        textButton.heightAnchor.constraint(equalToConstant: 32).isActive = true
        textButton.widthAnchor.constraint(equalToConstant: 32).isActive = true
        textButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: hMargin).isActive = true
        textButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        textButton.translatesAutoresizingMaskIntoConstraints = false
        textButton.alpha = 0
     
        
        let scale = CGAffineTransform(scaleX: 0.2, y: 0.2)
        textButton.transform = scale
    
        let tX = UIScreen.main.bounds.width / 2 - wMargin
        var translation = CGAffineTransform(translationX: tX, y: 0)
        drawButton.transform = scale.concatenating(translation)
        
        translation = CGAffineTransform(translationX: -tX, y: 0)
        finishButton.transform = scale.concatenating(translation)
        
        
        
        
//        undoButton.setImage(UIImage(named: "undo"), for: .normal)
//        undoButton.backgroundColor = UIColor.white.withAlphaComponent(0.9)
//        undoButton.addTarget(self, action: #selector(handleUndoButton), for: .touchUpInside)
//        undoButton.heightAnchor.constraint(equalToConstant: 16).isActive = true
//        undoButton.widthAnchor.constraint(equalToConstant: 16).isActive = true
//        view.addSubview(undoButton)
//        view.addConstraintsWithFormat("V:|-10-[v0(32)]|", views: undoButton)
//        undoButton.isHidden = true
//
//        clearButton.setImage(UIImage(named: "clear"), for: .normal)
//        clearButton.backgroundColor = UIColor.white.withAlphaComponent(0.9)
//        clearButton.addTarget(self, action: #selector(handleClearButton), for: .touchUpInside)
//        clearButton.heightAnchor.constraint(equalToConstant: 16).isActive = true
//        clearButton.widthAnchor.constraint(equalToConstant: 16).isActive = true
//        view.addSubview(clearButton)
//        view.addConstraintsWithFormat("V:|-10-[v0(32)]|", views: clearButton)
//        clearButton.isHidden = true
    }
    
    func showEditingButtons() {
        UIView.animate(withDuration: 0.4, delay: 0.1, options: .curveEaseOut, animations: {
            self.drawButton.transform = .identity
            self.textButton.transform = .identity
            self.finishButton.transform = .identity
            
            self.drawButton.alpha = 1
            self.textButton.alpha = 1
            self.finishButton.alpha = 1
        }, completion: nil)
    }
    
    func hideEditingBUttons() {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            let wMargin: CGFloat = 32
            let scale = CGAffineTransform(scaleX: 0.2, y: 0.2)
            self.textButton.transform = scale
            
            let tX = UIScreen.main.bounds.width / 2 - wMargin
            var translation = CGAffineTransform(translationX: tX, y: 0)
            self.drawButton.transform = scale.concatenating(translation)
            
            translation = CGAffineTransform(translationX: -tX, y: 0)
            self.finishButton.transform = scale.concatenating(translation)
            
            self.drawButton.alpha = 0
            self.textButton.alpha = 0
            self.finishButton.alpha = 0
        }, completion: nil)
    }
    
    @objc func controlStack(sender: UIButton!) {
        
        if !selectionButton.isSelected {
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
                self.contentStack.transform = CGAffineTransform(translationX: 0, y: self.contentStack.bounds.height - self.contentStack.subviews[0].bounds.height)
            }, completion: nil)
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
                let translation = CGAffineTransform(translationX: 0, y: 0.1 * self.editBoard.center.y)
                let scale = CGAffineTransform(scaleX: 1.1, y: 1.1)
                self.editBoard.transform = scale.concatenating(translation)
            }, completion: nil)
            showEditingButtons()
        } else {
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
                self.contentStack.transform = .identity
                self.editBoard.transform = .identity
            }, completion: nil)
            hideEditingBUttons()
        }
        selectionButton.isSelected = !selectionButton.isSelected
    }

    
}
