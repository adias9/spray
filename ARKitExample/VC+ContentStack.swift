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
        showEditingButtons()
    }
    
    
    func hideContentStack() {
        UIView.animate(withDuration: 1.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.contentStack.transform = CGAffineTransform(translationX: 0, y: self.view.frame.height)
        }, completion: nil)
        
        configureGesturesForState(state: .view)
        hideEditingBUttons()
    }
    
    func setupButtonsForEditing(){
        drawButton.setImage(UIImage(named: "draw"), for: .normal)
        drawButton.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        drawButton.addTarget(self, action: #selector(handleDrawButton), for: .touchUpInside)
        drawButton.heightAnchor.constraint(equalToConstant: 16).isActive = true
        drawButton.widthAnchor.constraint(equalToConstant: 16).isActive = true
        view.addSubview(drawButton)
        view.addConstraintsWithFormat("V:|-10-[v0(32)]|", views: drawButton)
        drawButton.isHidden = true
        
        undoButton.setImage(UIImage(named: "undo"), for: .normal)
        undoButton.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        undoButton.addTarget(self, action: #selector(handleUndoButton), for: .touchUpInside)
        undoButton.heightAnchor.constraint(equalToConstant: 16).isActive = true
        undoButton.widthAnchor.constraint(equalToConstant: 16).isActive = true
        view.addSubview(undoButton)
        view.addConstraintsWithFormat("V:|-10-[v0(32)]|", views: undoButton)
        undoButton.isHidden = true
        
        textButton.setImage(UIImage(named: "text"), for: .normal)
        textButton.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        textButton.addTarget(self, action: #selector(handleTextButton), for: .touchUpInside)
        textButton.heightAnchor.constraint(equalToConstant: 16).isActive = true
        textButton.widthAnchor.constraint(equalToConstant: 16).isActive = true
        view.addSubview(textButton)
        view.addConstraintsWithFormat("V:|-10-[v0(32)]|", views: textButton)
        textButton.isHidden = true
        
        clearButton.setImage(UIImage(named: "clear"), for: .normal)
        clearButton.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        clearButton.addTarget(self, action: #selector(handleClearButton), for: .touchUpInside)
        clearButton.heightAnchor.constraint(equalToConstant: 16).isActive = true
        clearButton.widthAnchor.constraint(equalToConstant: 16).isActive = true
        view.addSubview(clearButton)
        view.addConstraintsWithFormat("V:|-10-[v0(32)]|", views: clearButton)
        clearButton.isHidden = true
        
        finishButton.setImage(UIImage(named: "done"), for: .normal)
        finishButton.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        finishButton.addTarget(self, action: #selector(handleFinishButton), for: .touchUpInside)
        finishButton.heightAnchor.constraint(equalToConstant: 16).isActive = true
        finishButton.widthAnchor.constraint(equalToConstant: 16).isActive = true
        view.addSubview(finishButton)
        view.addConstraintsWithFormat("V:|-10-[v0(32)]|", views: finishButton)
        finishButton.isHidden = true
        
        
        // TODO: Change this layout
        view.addConstraintsWithFormat("H:|-10-[v0(32)]-50-[v1(32)]-10-[v2(32)]-10-[v3(32)]-10-[v4(32)]|",
                                      views: clearButton, undoButton, drawButton, textButton, finishButton )
        
    }
    
    func showEditingButtons() {
        drawButton.isHidden = false
        clearButton.isHidden = false
        finishButton.isHidden = false
        textButton.isHidden = false
//        undoButton.isHidden = false
    }
    
    func hideEditingBUttons() {
        drawButton.isHidden = true
        clearButton.isHidden = true
        finishButton.isHidden = true
        textButton.isHidden = true
        undoButton.isHidden = true
    }
    
    @objc func controlStack(sender: UIButton!) {
        
        if !selectionButton.isSelected {
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
                self.contentStack.transform = CGAffineTransform(translationX: 0, y: self.contentStack.bounds.height - self.contentStack.subviews[0].bounds.height)
            }, completion: nil)
        } else {
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
                self.contentStack.transform = .identity
            }, completion: nil)
        }
        selectionButton.isSelected = !selectionButton.isSelected
    }

    
}
