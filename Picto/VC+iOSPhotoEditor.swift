//
//  VC+iOSPhotoEditor.swift
//  ARKitExample
//
//  Created by Andreas Dias on 10/30/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import iOSPhotoEditor

extension ViewController : PhotoEditorDelegate {
    func openPhotoEditor(data: Data) {
        let photoEditor = PhotoEditorViewController(nibName:"PhotoEditorViewController",bundle: Bundle(for: PhotoEditorViewController.self))
        
        photoEditor.modalPresentationStyle = .popover
        let popover = photoEditor.popoverPresentationController
        photoEditor.preferredContentSize = CGSize(width: sceneView.bounds.size.width - 20, height: sceneView.bounds.size.height - 50)
        popover?.delegate = self
        popover?.sourceView = self.view
        popover?.permittedArrowDirections = UIPopoverArrowDirection.init(rawValue: 0)
        popover?.sourceRect = CGRect.init(x: 10, y: 10, width: 100, height: 100)
       
        
        //PhotoEditorDelegate
        photoEditor.photoEditorDelegate = self as? PhotoEditorDelegate
        
        //The image to be edited
        photoEditor.image =  UIImage(data:data,scale:1.0)
        
        //Stickers that the user will choose from to add on the image
//        photoEditor.stickers.append(UIImage(named: "sticker" )!)
        
        //possible controls .clear, .crop, .draw, .save, .share, sticker, .text
        photoEditor.hiddenControls = [.share, .save, .crop]
        
        //Optional: Colors for drawing and Text, If not set default values will be used
        //        photoEditor.colors = [.red,.blue,.green]
        
        //Present the View Controller
        present(photoEditor, animated: true, completion: nil)
    }
    
    func doneEditing(image: UIImage) {
        content?.data = UIImagePNGRepresentation(image)
        content?.type = .image
        setPreview(content: content!)
        showPreview()
        contentStack.isHidden = true
    }
    
    func setPreview(content: Content) {
        guard let content = self.content else {
            return
        }
        if content.type == .gif {
            if let data = content.data {
                preview.image = UIImage.gif(data: data)
            }
        } else {
            if let data = content.data {
                preview.image = UIImage(data: data)
            }
        }
    }
    
    func canceledEditing() {
        print("Canceled")
    }
}
