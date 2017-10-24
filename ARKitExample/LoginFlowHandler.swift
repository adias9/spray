//
//  LoginFlowHandler.swift
//  ARKitExample
//
//  Created by Andreas Dias on 8/16/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit
import FirebaseAuth

protocol LoginFlowHandler {
    func handleLogin()
    func handleLogout()
}

extension LoginFlowHandler {
    
    func handleLogin(withWindow window: UIWindow?) {
        
        let user = Auth.auth().currentUser
        if user != nil {
            //User has logged in before, cache and continue
            self.showMainApp(withWindow: window)
        } else {
            //No user information, show login flow
            self.showLogin(withWindow: window)
        }
    
    }
    
    func handleLogout(withWindow window: UIWindow?) {
        do {
            try Auth.auth().signOut();
            print("signed out")
        } catch {
            print("Error signing out")
        }
        
        showLogin(withWindow: window)
    }
    
    func showLogin(withWindow window: UIWindow?) {
        window?.subviews.forEach { $0.removeFromSuperview() }
        window?.rootViewController = nil
        let loginStoryboard: UIStoryboard = UIStoryboard(name: "Login", bundle: nil)
        window?.rootViewController = loginStoryboard.instantiateViewController(withIdentifier: "LoginViewController")
        window?.makeKeyAndVisible()
    }
    
    func showMainApp(withWindow window: UIWindow?) {
        window?.rootViewController = nil
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        window?.rootViewController = mainStoryboard.instantiateInitialViewController()
        window?.makeKeyAndVisible()
    }
}
