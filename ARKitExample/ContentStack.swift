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
        let menuBar = MenuBar()
        menuBar.viewController = self
        libraryGrid.viewController = self
        memeGrid.viewController = self
        gifGrid.viewController = self
        stickerGrid.viewController = self
        
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
        
        canvas.backgroundColor = UIColor.white
        canvas.heightAnchor.constraint(equalToConstant: 320).isActive = true
    
        contentStack.addArrangedSubview(editBoard)
        contentStack.addArrangedSubview(menuBar)
        contentStack.addArrangedSubview(container)
        
        let marginEditBoard = (UIScreen.main.bounds.width - editBoard.length) / 2
        contentStack.addConstraintsWithFormat("H:|-\(marginEditBoard)-[v0]-\(marginEditBoard)-|", views: editBoard)
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
        contentStack.setCustomSpacing(marginEditBoard * 3, after: editBoard)
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
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.contentStack.transform = .identity
        }, completion: nil)
        
        configureGesturesForState(state: .selection)
    }
    
    
    func hideContentStack() {
        UIView.animate(withDuration: 1.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.contentStack.transform = CGAffineTransform(translationX: 0, y: self.view.frame.height)
        }, completion: nil)
        
        configureGesturesForState(state: .view)
    }

    
}
