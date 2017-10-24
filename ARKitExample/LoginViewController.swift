//
//  LoginViewController.swift
//  ARKitExample
//
//  Created by Andreas Dias on 8/15/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import FirebaseAuth
import FirebaseDatabase

class LoginViewController: UIViewController, FBSDKLoginButtonDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.white
        
        let loginWelcome = UILabel()
        loginWelcome.text = "Welcome to Picto!"
        loginWelcome.textColor = UIColor.black
        loginWelcome.font = loginWelcome.font.withSize(30)
        loginWelcome.frame = CGRect(x: 16, y: view.frame.height/12, width: view.frame.width - 32, height: 100)
        view.addSubview(loginWelcome)
        
        let loginButton = FBSDKLoginButton()
        view.addSubview(loginButton)
        // add constraints not frames
        loginButton.frame = CGRect(x: 16, y: view.frame.height/2 - 50, width: view.frame.width - 32, height: 70)
        
        loginButton.delegate = self
        loginButton.readPermissions = ["email", "public_profile"]
        
//        //add our custom fb login button here
//        let customFBButton = UIButton(type: .system)
//        customFBButton.backgroundColor = .blue
//        customFBButton.frame = CGRect(x: 16, y: 116, width: view.frame.width - 32, height: 50)
//        customFBButton.setTitle("Custom FB Login here", for: .normal)
//        customFBButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
//        customFBButton.setTitleColor(.white, for: .normal)
//        view.addSubview(customFBButton)
//
//        customFBButton.addTarget(self, action: #selector(handleCustomFBLogin), for: .touchUpInside)
    }
    
//    @objc func handleCustomFBLogin() {
//        FBSDKLoginManager().logIn(withReadPermissions: ["email", "public_profile"], from: self) { (result, err) in
//            if err != nil {
//                print("Custom FB Login failed:", err!)
//                return
//            }
//
//            self.startSignIn()
//            let registerViewController = RegisterViewController()
//            self.present(registerViewController, animated: true, completion: nil)
//        }
//    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("Did log out of facebook")
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if error != nil {
            print(error)
            return
        }
        
        startSignIn()
    }
    
    func startSignIn() {
        let accessToken = FBSDKAccessToken.current()
        guard let accessTokenString = accessToken?.tokenString else {
            return
        }
        let credentials = FacebookAuthProvider.credential(withAccessToken: accessTokenString)
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.main.async(group: group) {
            Auth.auth().signIn(with: credentials) { (user, error) in
                if let error = error {
                    print("Something went wrong with our FB user: ", error)
                    return
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            FBSDKGraphRequest(graphPath: "/me", parameters: ["fields": "id, name, email"]).start {
                (connection, result, err) in
                if err != nil {
                    print("Failed to start graph request:", err!)
                    return
                }
                
                let dict = result as! NSDictionary
                let name = dict.object(forKey: "name") as! String
                let email = dict.object(forKey: "email") as! String
                self.createFirebaseUser(name: name, email: email)
            }
        }
    }
    
    func createFirebaseUser(name: String, email: String) {
        let databaseRef = Database.database().reference()
        
        Auth.auth().addStateDidChangeListener { (auth, user) in
            if user != nil {
                let userID = Auth.auth().currentUser!.uid
                
                databaseRef.child("users/\(userID)").observeSingleEvent(of: .value, with: { (snapshot) in
                    // check if user has signed up before and has inputted a username
                    // if so redirect to main page after login
                    if snapshot.hasChild("username") {
                        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                        let mainViewController = mainStoryboard.instantiateInitialViewController()
                        self.present(mainViewController!, animated: true, completion: nil)
                    // otherwise redirect to register page
                    } else {
                        DispatchQueue.main.async {
                            let user: [String: Any] = [
                                "name": name,
                                "email": email,
                                ]
                            let userChildUpdates: [String: Any] = ["/users/\(userID)": user]
                            databaseRef.updateChildValues(userChildUpdates)
                        }
                        let registerViewController = RegisterViewController()
                        self.present(registerViewController, animated: true, completion: nil)
                    }
                })
            } else {
                // No user is signed in.
            }
        }
    }
}
