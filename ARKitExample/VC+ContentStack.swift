//
//  ContentStack.swift
//  ARKitExample
//
//  Created by Andrew Jay Zhou on 8/16/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit
import SwiftIconFont

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
        selectionButton.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        selectionButton.widthAnchor.constraint(equalToConstant: buttonWidth).isActive = true
        selectionButton.heightAnchor.constraint(equalToConstant: 16).isActive = true
        selectionButton.translatesAutoresizingMaskIntoConstraints = false
        selectionButton.addTarget(self, action: #selector(controlStack), for: .touchUpInside)
        selectionButton.setImage(UIImage(named: "detailsBlack"), for: .normal)
        selectionButton.setImage(UIImage(named: "triangleBlack"), for: .selected)
        selectionButton.imageView?.contentMode = .scaleAspectFill
        selectionButton.layer.cornerRadius = 0.05 * buttonWidth

        
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
        
        setupEditBoard()
        
        setupButtonsForDrawing()
    }
    
    func setupEditBoard() {
        let length = UIScreen.main.bounds.width * 0.90
        let wMargin = (UIScreen.main.bounds.width - length) / 2
        let hMargin = 3 * wMargin
        view.addSubview(editBoard)
        view.addConstraintsWithFormat("H:|-\(wMargin)-[v0(\(length))]-\(wMargin)-|", views: editBoard)
        view.addConstraintsWithFormat("V:|-\(hMargin)-[v0(\(length))]|", views: editBoard)
        
        let translation = CGAffineTransform(translationX: 0, y: UIScreen.main.bounds.height - hMargin)
        let scale = CGAffineTransform(scaleX: 0.2, y: 0.2)
        editBoard.transform = scale.concatenating(translation)
        editBoard.alpha = 0
    }
    
    func dismissEditBoard() {
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
            let length = UIScreen.main.bounds.width * 0.90
            let wMargin = (UIScreen.main.bounds.width - length) / 2
            let hMargin = 3 * wMargin
            let translation = CGAffineTransform(translationX: 0, y: UIScreen.main.bounds.height - hMargin)
            let scale = CGAffineTransform(scaleX: 0.2, y: 0.2)
            self.editBoard.transform = scale.concatenating(translation)
            self.editBoard.alpha = 0
        }, completion: nil)
    }
    
    func showEditBoard() {
        UIView.animate(withDuration:
            0.5, delay: 0, options: .curveEaseOut, animations: {
                self.editBoard.transform = .identity
                self.editBoard.alpha = 1
        }, completion: nil)
    }
    
    func showGrid(type : ContentType) {
        let grid = contentStack.subviews[contentStack.subviews.count - 2]
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
            self.clearButton.isHidden = false
        }, completion: nil)
        
        configureGesturesForState(state: .selection)
    }
    
    
    func hideContentStack() {
        UIView.animate(withDuration: 1.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.contentStack.transform = CGAffineTransform(translationX: 0, y: self.view.frame.height)
            self.clearButton.isHidden = true
        }, completion: nil)
        
        configureGesturesForState(state: .view)
        hideEditingBUttons()
    }
    
    func setupButtonsForEditing(){
        let hMargin: CGFloat = -0.18 * UIScreen.main.bounds.height
        let wMargin: CGFloat = 16
        let buttonLength: CGFloat = 64
        
        view.addSubview(drawButton)
        drawButton.setImage(UIImage(named: "brushBlack"), for: .normal)
        drawButton.setBackgroundImage(UIImage.from(color: UIColor.white.withAlphaComponent(0.9)), for: .normal)
        drawButton.setBackgroundImage(UIImage.from(color: UIColor.gray.withAlphaComponent(0.9)), for: .selected)
        drawButton.addTarget(self, action: #selector(handleDrawButton), for: .touchUpInside)
        drawButton.heightAnchor.constraint(equalToConstant: buttonLength).isActive = true
        drawButton.widthAnchor.constraint(equalToConstant: buttonLength).isActive = true
        drawButton.layer.cornerRadius = 0.5 * buttonLength
        drawButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: hMargin).isActive = true
        drawButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: wMargin).isActive = true
        drawButton.translatesAutoresizingMaskIntoConstraints = false
        drawButton.clipsToBounds = true
        drawButton.alpha = 0
        
        view.addSubview(finishButton)
        finishButton.setImage(UIImage(named: "ic_check_white"), for: .normal)
        finishButton.layer.cornerRadius = 0.5 * buttonLength
        finishButton.setBackgroundImage(UIImage.from(color:
            UIColor(hue: 202/360, saturation: 100/100, brightness: 100/100, alpha: 0.9)),
                                        for: .normal)
        finishButton.setBackgroundImage(UIImage.from(color:
            UIColor(hue: 202/360, saturation: 100/100, brightness: 50/100, alpha: 0.9)),
                                        for: .highlighted)
        finishButton.addTarget(self, action: #selector(handleFinishButton), for: .touchUpInside)
        finishButton.heightAnchor.constraint(equalToConstant: buttonLength).isActive = true
        finishButton.widthAnchor.constraint(equalToConstant: buttonLength).isActive = true
        finishButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: hMargin).isActive = true
        finishButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -wMargin).isActive = true
        finishButton.translatesAutoresizingMaskIntoConstraints = false
        finishButton.clipsToBounds = true
        finishButton.alpha = 0
      
        
        view.addSubview(textButton)
        textButton.setImage(UIImage(named: "ic_closed_caption"), for: .normal)
        textButton.layer.cornerRadius = 0.5 * buttonLength
        textButton.setBackgroundImage(UIImage.from(color: UIColor.white.withAlphaComponent(0.9)), for: .normal)
        textButton.setBackgroundImage(UIImage.from(color: UIColor.gray.withAlphaComponent(0.9)), for: .highlighted)
        textButton.addTarget(self, action: #selector(handleTextButton), for: .touchUpInside)
        textButton.heightAnchor.constraint(equalToConstant: buttonLength).isActive = true
        textButton.widthAnchor.constraint(equalToConstant: buttonLength).isActive = true
        textButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: hMargin).isActive = true
        textButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        textButton.translatesAutoresizingMaskIntoConstraints = false
        textButton.clipsToBounds = true
        textButton.alpha = 0
     
        
        let scale = CGAffineTransform(scaleX: 0.2, y: 0.2)
        textButton.transform = scale
        let tX = UIScreen.main.bounds.width / 2 - wMargin
        var translation = CGAffineTransform(translationX: tX, y: 0)
        drawButton.transform = scale.concatenating(translation)
        translation = CGAffineTransform(translationX: -tX, y: 0)
        finishButton.transform = scale.concatenating(translation)
        
        view.addSubview(clearButton)
        clearButton.setImage(UIImage(named: "ic_clear_white"), for: .normal)
        clearButton.addTarget(self, action: #selector(handleClearButton), for: .touchUpInside)
        clearButton.heightAnchor.constraint(equalToConstant: buttonLength).isActive = true
        clearButton.widthAnchor.constraint(equalToConstant: buttonLength).isActive = true
        clearButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: wMargin)
        clearButton.topAnchor.constraint(equalTo: self.view.topAnchor, constant: wMargin)
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        clearButton.isHidden = true
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

    func setupButtonsForDrawing() {
        let hMargin: CGFloat = -0.18 * UIScreen.main.bounds.height
        let wMargin: CGFloat = 16
        let buttonLength: CGFloat = 64
        
        colorSlider.orientation = .horizontal
        colorSlider.previewEnabled = true
        view.addSubview(colorSlider)
        colorSlider.translatesAutoresizingMaskIntoConstraints = false
        colorSlider.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        colorSlider.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: hMargin).isActive = true
        colorSlider.widthAnchor.constraint(equalToConstant: 200).isActive = true
        colorSlider.heightAnchor.constraint(equalToConstant: 20).isActive = true
        colorSlider.alpha = 0
        colorSlider.delegate = editBoard.drawView
        
        view.addSubview(undoButton)
        undoButton.setImage(UIImage(named: "undo"), for: .normal)
        undoButton.layer.cornerRadius = 0.5 * (buttonLength / 2)
        undoButton.setBackgroundImage(UIImage.from(color: UIColor.white.withAlphaComponent(0.9)), for: .normal)
        undoButton.setBackgroundImage(UIImage.from(color: UIColor.gray.withAlphaComponent(0.9)), for: .selected)
        undoButton.addTarget(self, action: #selector(handleUndoButton), for: .touchUpInside)
        undoButton.heightAnchor.constraint(equalToConstant: buttonLength / 2).isActive = true
        undoButton.widthAnchor.constraint(equalToConstant: buttonLength / 2).isActive = true
        undoButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: hMargin).isActive = true
        undoButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -wMargin).isActive = true
        undoButton.translatesAutoresizingMaskIntoConstraints = false
        undoButton.clipsToBounds = true
        undoButton.alpha = 0
        
        
        let scale = CGAffineTransform(scaleX: 0.2, y: 0.2)
        textButton.transform = scale
        let tX = UIScreen.main.bounds.width / 2 - wMargin
        let translation = CGAffineTransform(translationX: -tX, y: 0)
        undoButton.transform = scale.concatenating(translation)
        colorSlider.transform = scale.concatenating(translation)
    }
    
    func showButtonsForDrawing() {
        UIView.animate(withDuration: 0.4, delay: 0.1, options: .curveEaseOut, animations: {
            self.undoButton.transform = .identity
            self.colorSlider.transform = .identity
            
            self.undoButton.alpha = 1
            self.colorSlider.alpha = 1
            
            self.finishButton.isHidden = true
            self.textButton.isHidden = true
        }, completion: nil)
        
        finishButton.isHidden = true
        textButton.isHidden = true
    }
    
    func hideButtonsForDrawing() {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            let wMargin: CGFloat = 32
            let scale = CGAffineTransform(scaleX: 0.2, y: 0.2)
            let tX = UIScreen.main.bounds.width / 2 - wMargin
            let translation = CGAffineTransform(translationX: -tX, y: 0)
            self.undoButton.transform = scale.concatenating(translation)
            self.colorSlider.transform = scale.concatenating(translation)
            self.undoButton.alpha = 0
            self.colorSlider.alpha = 0
            
            self.finishButton.isHidden = false
            self.textButton.isHidden = false
        }, completion: nil)
    }
}
