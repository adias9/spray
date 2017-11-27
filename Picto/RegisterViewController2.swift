//
//  RegisterViewController2.swift
//  ARKitExample
//
//  Created by Andreas Dias on 11/10/17.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class RegisterViewController2: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    let loginWelcome: UILabel = {
        let welcome = UILabel()
        welcome.text = "Choose Your School"
        welcome.numberOfLines = 0
        welcome.lineBreakMode = .byWordWrapping
        welcome.textColor = UIColor.black
        welcome.textAlignment = .center
        welcome.font = welcome.font.withSize(20)
        welcome.translatesAutoresizingMaskIntoConstraints = false
        welcome.layer.masksToBounds = true
        return welcome
    }()
    
    let schoolRegisterButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor.init(r: 77, g: 218, b: 238)
        button.setTitle("Next", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel?.font = UIFont.init(name: "Arial", size: 20)
        
        button.addTarget(self, action: #selector(addSchool), for: .touchUpInside)
        
        return button
    }()
    
    let otherSchoolTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "School Name"
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.enablesReturnKeyAutomatically = false
        tf.borderStyle = .none
        tf.font = UIFont.init(name: "Arial", size: 30)
        tf.textAlignment = .center
        return tf
    }()
    
    let pickerData = ["UC Berkeley","Stanford","Princeton","Other"]
    let schoolPickView: UIPickerView = {
        let pv = UIPickerView()
        pv.translatesAutoresizingMaskIntoConstraints = false
        pv.layer.masksToBounds = true
        return pv
    }()
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let formattedTitle = NSAttributedString(string: pickerData[row], attributes: [NSAttributedStringKey.font: UIFont(name: "Arial", size: 30)!, NSAttributedStringKey.foregroundColor: UIColor.black])
        return formattedTitle
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 30.0
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        view.addSubview(loginWelcome)
        view.addSubview(schoolPickView)
        view.addSubview(schoolRegisterButton)
        
        self.schoolPickView.delegate = self
        self.schoolPickView.dataSource = self
        
        setupSchoolPickView()
        setupLoginWelcome()
        setupLoginRegisterButton()
    }
    
    func setupSchoolPickView() {
        //need x, y, width, height constraints
        schoolPickView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        schoolPickView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        schoolPickView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -24).isActive = true
        schoolPickView.heightAnchor.constraint(equalToConstant: 100).isActive = true
    }
    
    func setupLoginWelcome() {
        loginWelcome.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loginWelcome.bottomAnchor.constraint(equalTo: schoolPickView.topAnchor).isActive = true
        loginWelcome.widthAnchor.constraint(equalTo: schoolPickView.widthAnchor).isActive = true
        schoolRegisterButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    func setupLoginRegisterButton() {
        //need x, y, width, height constraints
        schoolRegisterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        schoolRegisterButton.topAnchor.constraint(equalTo: schoolPickView.bottomAnchor).isActive = true
        schoolRegisterButton.widthAnchor.constraint(equalTo: schoolPickView.widthAnchor).isActive = true
        schoolRegisterButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    func showOtherSchoolScreen() {
        let alertController = UIAlertController(title: "Want Picto at your school?", message: "Add your school name and once we get enough users we will add a cube to your school (You can still view the existing cubes):", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Next", style: .default) { (_) in
            let field = alertController.textFields![0]
            
            guard let otherSchool = field.text else {
                print("Form is not valid")
                return
            }
            if otherSchool == "" {
                print("Field cannot be empty")
                return
            }
            
            // store your data
            let databaseRef = Database.database().reference()
            let userID = Auth.auth().currentUser?.uid
            let upcomingSchoolChildUpdates: [String: Any] = ["/schools/\(otherSchool)/\(userID!)": true]
            databaseRef.updateChildValues(upcomingSchoolChildUpdates)
            
            let welcomeViewController = WelcomeViewController()
            self.present(welcomeViewController, animated: true, completion: nil)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Input School"
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc func addSchool() {
        let index = schoolPickView.selectedRow(inComponent: 0)
        let school = pickerData[index]
        if school == "Other" {
            showOtherSchoolScreen()
            return
        }
        
        let databaseRef = Database.database().reference()
        
        // memory leak here? didn't remove listener?
        Auth.auth().addStateDidChangeListener { (auth, user) in
            if user != nil {
                let userID = Auth.auth().currentUser!.uid
                let userChildUpdates: [String: Any] = ["/users/\(userID)/school": school]
                databaseRef.updateChildValues(userChildUpdates)
            } else {
                print("no user")
            }
        }
        
        let welcomeViewController = WelcomeViewController()
        present(welcomeViewController, animated: true, completion: nil)
    }
}
