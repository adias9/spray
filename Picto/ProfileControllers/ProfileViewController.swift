//
//  ProfileViewController.swift
//  ARKitExample
//
//  Created by Andreas Dias on 11/8/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class ProfileViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    let username : UILabel = {
        let username = UILabel()
        username.text = "username"
        username.numberOfLines = 0
        username.lineBreakMode = .byWordWrapping
        username.textColor = UIColor.black
        username.textAlignment = .center
        username.font = UIFont.init(name: "MarkerFelt-Wide", size: 30)
        username.translatesAutoresizingMaskIntoConstraints = false
        username.layer.masksToBounds = true
        return username
    }()
    
    let preferencesButton : UIButton = {
        let button = UIButton(frame: CGRect(x: 100, y: 100, width: 100, height: 50))
//        button.setBackgroundImage(UIImage.init(named: "settings"), for: UIControlState.normal)
        button.setTitle("logout", for: .normal)
        button.setTitleColor(UIColor.black, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(clickPreferences), for: .touchUpInside)
        return button
    }()
    
    let backButton : UIButton = {
        let button = UIButton(frame: CGRect(x: 100, y: 100, width: 100, height: 50))
//        let button = UIButton()
//        button.setBackgroundImage(UIImage.init(named: "settings"), for: UIControlState.normal)
        button.setTitle("back", for: .normal)
        button.setTitleColor(UIColor.black, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(clickBack), for: .touchUpInside)
        return button
    }()
    
    let school : UILabel = {
        let school = UILabel()
        school.text = "School: "
        school.numberOfLines = 0
        school.lineBreakMode = .byWordWrapping
        school.textColor = UIColor.black
        school.textAlignment = .left
        school.font = UIFont.init(name: "MarkerFelt-Wide", size: 15)
        school.translatesAutoresizingMaskIntoConstraints = false
        school.layer.masksToBounds = true
        return school
    }()
    
    var images: [dbPicture]?
    
    let postsView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize.init(width: 0, height: 0)
        layout.minimumLineSpacing = 0
        let collView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collView.backgroundColor = UIColor.init(r: 215, g: 215, b: 215)
        collView.translatesAutoresizingMaskIntoConstraints = false
        collView.layer.cornerRadius = 5
        collView.layer.masksToBounds = true
        return collView
    }()
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellId", for: indexPath) as! ImageCell
        
        cell.image = images?[indexPath.item]
        
        return cell
    }
    
    // have this to get size of view after loaded then modify
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize.init(width: (view.frame.width-34) / 2, height: 150)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func fetchUsername() {
        let databaseRef = Database.database().reference()
        let uid = Auth.auth().currentUser?.uid
        let userRef = databaseRef.child("/users/\(uid!)")
        userRef.observeSingleEvent(of: .value, with :{ (snapshot) in
            if snapshot.exists() {
                let userDict = snapshot.valueInExportFormat() as! NSDictionary
                
                self.username.text = userDict["username"] as? String
                if let schoolText = userDict["school"] as? String {
                    self.school.text = "School: " + schoolText
                }
                
            } else {
                
            }
        })
    }
    
    func fetchImages() {
        //get images from firebase
        self.images = [dbPicture]()
        
        let databaseRef = Database.database().reference()
        let uid = Auth.auth().currentUser?.uid  //"ZKJQPItATMbw1mkDezoMmSxHU103"
        let picRef = databaseRef.child("/users/\(uid!)/pictures")
        
        let group = DispatchGroup()
        group.enter()
        
        picRef.observeSingleEvent(of: .value, with :{ (snapshot) in
            if snapshot.exists() {
                let picUrls = snapshot.valueInExportFormat() as! NSDictionary

                var count = 0
                for (picID, _) in picUrls {
                    databaseRef.child("/pictures/\(picID)/url").observeSingleEvent(of: .value, with :{ (snapshot) in
                        if snapshot.exists() {
                            let url = snapshot.valueInExportFormat() as! String
                            let pic = dbPicture()
                            pic.url = url
                            self.images?.append(pic)
                            count += 1
                            if count == picUrls.count {
                                group.leave()
                            }
                        }
                    })
                }
               
            } else {
                
            }
        })
        
        group.notify(queue: .main) {
            DispatchQueue.main.async {
                self.postsView.reloadData()
            }
        }
        
        
    }
    
    @objc func clickPreferences() {
//        let window = UIWindow.init(frame: UIScreen.main.bounds)
//        LoginFlowHandler().handleLogout(withWindow: window)
        do {
            try Auth.auth().signOut();
            print("signed out")
        } catch {
            print("Error signing out")
        }
        
        let loginStoryboard: UIStoryboard = UIStoryboard(name: "Login", bundle: nil)
        let loginViewController = loginStoryboard.instantiateViewController(withIdentifier: "LoginViewController")
        present(loginViewController, animated: true, completion: nil)
        
//        let preferenceViewController = PreferenceViewController()
//        present(preferenceViewController, animated: true, completion: nil)
    }
    
    @objc func clickBack() {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchUsername()
        fetchImages()
        
        view.addSubview(username)
        view.addSubview(preferencesButton)
        view.addSubview(backButton)
        view.addSubview(school)
        view.addSubview(postsView)
        
        postsView.delegate = self
        postsView.dataSource = self
        postsView.register(ImageCell.self, forCellWithReuseIdentifier: "cellId")
        
        setupTopSection()
        setupPostsView()
    }
    
    func setupTopSection() {
        username.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        username.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        username.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        preferencesButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -24).isActive = true
        preferencesButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 40).isActive = true
        
        backButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 24).isActive = true
        backButton.topAnchor.constraint(equalTo: preferencesButton.topAnchor).isActive = true
        
        school.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        school.topAnchor.constraint(equalTo: username.bottomAnchor).isActive = true
        school.heightAnchor.constraint(equalToConstant: 50).isActive = true
        school.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 24).isActive = true
    }
    
    func setupPostsView() {
        //need x, y, width, height constraints
        postsView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        postsView.topAnchor.constraint(equalTo: school.bottomAnchor).isActive = true
        postsView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -24).isActive = true
        postsView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -24).isActive = true
    }
}
