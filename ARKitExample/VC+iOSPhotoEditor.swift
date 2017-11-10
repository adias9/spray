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
        
        //PhotoEditorDelegate
        photoEditor.photoEditorDelegate = self as? PhotoEditorDelegate
        
        //The image to be edited
        photoEditor.image =  UIImage(data:data,scale:1.0)
        
        //Stickers that the user will choose from to add on the image
//        photoEditor.stickers.append(UIImage(named: "sticker" )!)
        
        //possible controls .clear, .crop, .draw, .save, .share, sticker, .text
        photoEditor.hiddenControls = [.share]
        
        //Optional: Colors for drawing and Text, If not set default values will be used
        //        photoEditor.colors = [.red,.blue,.green]
        
        //Present the View Controller
        present(photoEditor, animated: true, completion: nil)
    }
    
    func doneEditing(image: UIImage) {
        setPreview(content: image)
        showPreview()
        contentStack.isHidden = true
    }
    
    func setPreview(content: UIImage) {
        preview.image = content
    }
    
    func canceledEditing() {
        print("Canceled")
    }
}
