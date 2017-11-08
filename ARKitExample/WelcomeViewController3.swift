//
//  WelcomeViewController3.swift
//  ARKitExample
//
//  Created by Andreas Dias on 11/7/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit

class WelcomeViewController3: UIViewController {
    
    
    let loginRegisterButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor.init(r: 77, g: 218, b: 238)
        button.setTitle("Get Started", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel?.font = UIFont.init(name: "Arial", size: 20)
        
        button.addTarget(self, action: #selector(clickNext), for: .touchUpInside)
        
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        view.addSubview(loginRegisterButton)
        
        let loginWelcome = UILabel()
        loginWelcome.text = "Welcome to"
        loginWelcome.numberOfLines = 0
        loginWelcome.lineBreakMode = .byWordWrapping
        loginWelcome.textColor = UIColor.black
        loginWelcome.textAlignment = .center
        loginWelcome.font = loginWelcome.font.withSize(20)
        loginWelcome.frame = CGRect(x: 16, y: 50, width: view.frame.width - 32, height: 20)
        view.addSubview(loginWelcome)
        
        let logo = UIImageView(frame: CGRect(x: 16, y: 80, width: view.frame.width - 32, height: 50))
        logo.image = UIImage.init(named: "picto.png")
        logo.contentMode = .scaleAspectFit
        view.addSubview(logo)
        
        let gif = UIImageView(frame: CGRect(x: 0, y: view.frame.height/3 - 50, width: view.frame.width, height: view.frame.height / 3))
        gif.image = UIImage.gif(name: "wow")
        gif.contentMode = .scaleAspectFit
        view.addSubview(gif)
        
        let message = UILabel()
        message.text = "Be amazed by all of the cool stuff on the cube"
        message.numberOfLines = 0
        message.textColor = UIColor.black
        message.textAlignment = .center
        message.font = loginWelcome.font.withSize(20)
        message.frame = CGRect(x: 16, y: view.frame.height/2 + 80, width: view.frame.width - 32, height: 60)
        view.addSubview(message)
        
        setupLoginRegisterButton()
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func setupLoginRegisterButton() {
        //need x, y, width, height constraints
        loginRegisterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loginRegisterButton.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -24).isActive = true
        loginRegisterButton.topAnchor.constraint(equalTo: view.centerYAnchor, constant: 200).isActive = true
        loginRegisterButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    @objc func clickNext() {
        
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let mainViewController = mainStoryboard.instantiateInitialViewController()
        present(mainViewController!, animated: true, completion: nil)
    }
}


