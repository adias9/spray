//
//  RegisterViewController.swift
//  ARKitExample
//
//  Created by Andreas Dias on 8/16/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class RegisterViewController: UIViewController {
    
    let inputsContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        return view
    }()
    
    let loginRegisterButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(r: 80, g: 101, b: 161)
        button.setTitle("Register", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        
        button.addTarget(self, action: #selector(addUsername), for: .touchUpInside)
        
        return button
    }()
    
    let usernameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Username"
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(r: 61, g: 91, b: 151)
        
        view.addSubview(inputsContainerView)
        view.addSubview(loginRegisterButton)
        
        setupInputsContainerView()
        setupLoginRegisterButton()
    }
    
    func setupInputsContainerView() {
        //need x, y, width, height constraints
        inputsContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        inputsContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        inputsContainerView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -24).isActive = true
        inputsContainerView.heightAnchor.constraint(equalToConstant: 150).isActive = true
        
        inputsContainerView.addSubview(usernameTextField)
        //need x, y, width, height constraints
        usernameTextField.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor, constant: 12).isActive = true
        usernameTextField.topAnchor.constraint(equalTo: inputsContainerView.topAnchor).isActive = true
        usernameTextField.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        usernameTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1/3).isActive = true
    }
    
    func setupLoginRegisterButton() {
        //need x, y, width, height constraints
        loginRegisterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loginRegisterButton.topAnchor.constraint(equalTo: inputsContainerView.bottomAnchor, constant: 12).isActive = true
        loginRegisterButton.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        loginRegisterButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    @objc func addUsername() {
        guard let username = usernameTextField.text else {
            print("Form is not valid")
            return
        }
        if usernameTextField.text! == "" {
            print("Field cannot be empty")
            return
        }
        
        
        let databaseRef = Database.database().reference()
        Auth.auth().addStateDidChangeListener { (auth, user) in
            if user != nil {
                let userID = Auth.auth().currentUser!.uid
                let userChildUpdates: [String: Any] = ["/users/\(userID)/username": username]
                databaseRef.updateChildValues(userChildUpdates)
            } else {
                
            }
        }
        
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let mainViewController = mainStoryboard.instantiateInitialViewController()
        present(mainViewController!, animated: true, completion: nil)
    }
}

extension UIColor {
    convenience init(r: CGFloat, g: CGFloat, b:CGFloat) {
        self.init(red: r/255, green: g/255, blue: b/255, alpha: 1)
    }
}
