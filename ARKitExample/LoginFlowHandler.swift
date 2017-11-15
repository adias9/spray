//
//  LoginFlowHandler.swift
//  ARKitExample
//
//  Created by Andreas Dias on 8/16/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit
import FirebaseAuth

class LoginFlowHandler {
    
    func handleLogin(withWindow window: UIWindow?) {
        
        let user = Auth.auth().currentUser
        if user != nil {
            //User has logged in before, cache and continue
            self.showMainApp(withWindow: window)
        } else {
            //No user information, show login flow
            self.showLogin(withWindow: window)
        }
//        self.showRegister(withWindow: window)
    }

    // fix this function
//    func handleLogout(withWindow window: UIWindow?) {
//        do {
//            try Auth.auth().signOut();
//            print("signed out")
//        } catch {
//            print("Error signing out")
//        }
//
//        let loginStoryboard: UIStoryboard = UIStoryboard(name: "Login", bundle: nil)
//        let loginViewController = loginStoryboard.instantiateViewController(withIdentifier: "LoginViewController")
//
//    }
    
    func showLogin(withWindow window: UIWindow?) {
        window?.subviews.forEach { $0.removeFromSuperview() }
        window?.rootViewController = nil
        let loginStoryboard: UIStoryboard = UIStoryboard(name: "Login", bundle: nil)
        window?.rootViewController = loginStoryboard.instantiateViewController(withIdentifier: "LoginViewController")
        window?.makeKeyAndVisible()
    }
    
    //delete -- this is only for testing
//    func showRegister(withWindow window: UIWindow?) {
//        window?.subviews.forEach { $0.removeFromSuperview() }
//        window?.rootViewController = nil
//        let loginStoryboard: UIStoryboard = UIStoryboard(name: "Profile", bundle: nil)
//        window?.rootViewController = loginStoryboard.instantiateViewController(withIdentifier: "ProfileViewController")
//        window?.makeKeyAndVisible()
//    }
    
    
    
    func showMainApp(withWindow window: UIWindow?) {
        window?.rootViewController = nil
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        window?.rootViewController = mainStoryboard.instantiateInitialViewController()
        window?.makeKeyAndVisible()
    }
}
