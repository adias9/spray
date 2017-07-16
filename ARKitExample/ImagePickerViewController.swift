//
//  ImagePickerViewController.swift
//  ARKitExample
//
//  Created by Andrew Jay Zhou on 7/14/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit

class ImagePickerViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    weak var delegate: ImagePickerViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .photoLibrary
        print("--------------------------------------------------------------------1")
        self.present(imagePicker, animated: true, completion: nil)
                print("--------------------------------------------------------------------2")
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        var img: UIImage?
        let pickedImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        img = pickedImage
        print("img size: \(img!.size)")
        
        print("----------------------------------------------------------------------------------------------------------------!!")
        delegate?.imagePickerViewController(self, didSelectImage: img!)
        self.dismiss(animated: true, completion: nil)
    }
  
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        delegate?.imagePickerViewControllerDidCancel(self)
        self.dismiss(animated: true, completion: nil)
        print("i'm here")
    }
    
}

// MARK: - ImagePickerViewControllerDelegate
protocol ImagePickerViewControllerDelegate: class {
    func imagePickerViewController(_: ImagePickerViewController, didSelectImage image: UIImage)
    func imagePickerViewControllerDidCancel(_: ImagePickerViewController)
    
}

