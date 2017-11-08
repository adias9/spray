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

class RegisterViewController: UIViewController, UITextFieldDelegate {
    
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
        button.backgroundColor = UIColor.init(r: 77, g: 218, b: 238)
        button.setTitle("Next", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel?.font = UIFont.init(name: "Arial", size: 20)
        
        button.addTarget(self, action: #selector(addUsername), for: .touchUpInside)
        
        return button
    }()
    
    let usernameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Username"
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.enablesReturnKeyAutomatically = false
        tf.borderStyle = .none
        tf.font = UIFont.init(name: "Arial", size: 30)
        tf.textAlignment = .center
        return tf
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        view.addSubview(inputsContainerView)
        view.addSubview(loginRegisterButton)
        
        self.hideKeyboard()
        
        let loginWelcome = UILabel()
        loginWelcome.text = "Create a Username"
        loginWelcome.numberOfLines = 0
        loginWelcome.lineBreakMode = .byWordWrapping
        loginWelcome.textColor = UIColor.black
        loginWelcome.textAlignment = .center
        loginWelcome.font = loginWelcome.font.withSize(20)
        loginWelcome.frame = CGRect(x: 16, y: view.frame.height/2 - 50, width: view.frame.width - 32, height: 20)
        view.addSubview(loginWelcome)
        
        self.usernameTextField.delegate = self
        
        setupInputsContainerView()
        setupLoginRegisterButton()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameTextField {
            textField.resignFirstResponder()
            self.addUsername()
            return false
        }
        return true
    }
    
    func hideKeyboard() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(self.dismissKeyboard))
        
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func setupInputsContainerView() {
        //need x, y, width, height constraints
        inputsContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        inputsContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        inputsContainerView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -24).isActive = true
        inputsContainerView.heightAnchor.constraint(equalToConstant: 75).isActive = true
        
        inputsContainerView.addSubview(usernameTextField)
        //need x, y, width, height constraints
        usernameTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        usernameTextField.topAnchor.constraint(equalTo: inputsContainerView.topAnchor).isActive = true
        usernameTextField.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        usernameTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: 1).isActive = true
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
        if usernameTextField.text!.count >= 10 {
            print("username must be less than 11 characters")
            return
        }
        let letters = NSCharacterSet.letters
        let range = usernameTextField.text!.rangeOfCharacter(from: letters)
        if let test = range {
        } else {
            print("username must contain letters")
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
        
        let welcomeViewController = WelcomeViewController()
        present(welcomeViewController, animated: true, completion: nil)
    }
}

extension UIColor {
    convenience init(r: CGFloat, g: CGFloat, b:CGFloat) {
        self.init(red: r/255, green: g/255, blue: b/255, alpha: 1)
    }
}
