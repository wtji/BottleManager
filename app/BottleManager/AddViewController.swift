//
//  AddViewController.swift
//  BottleManager
//
//  Created by Weiting Ji on 11/19/20.
//  Copyright © 2020 ucla. All rights reserved.
//
//  The framework of this alert app is based on the reminder app project
//  created by IOSAcademy https://github.com/AfrazCodes/SimpleReminders with modification
//  in notification trigger algorithm and with extension in Bluetooth Low Energy functionality

import UIKit

class AddViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var pillNameField: UITextField!
    @IBOutlet var timePicker: UIDatePicker!
    
    // hand back the reminder information to the tableView
    public var saveComplete: ((String, Date) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        pillNameField.delegate = self
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(didTapSave))

    }
    
    @objc func didTapSave() {
        if let pillName = pillNameField.text, !pillName.isEmpty {
            let targetTime = timePicker.date
            
            saveComplete?(pillName, targetTime)
        }
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        pillNameField.resignFirstResponder()
        return true
    }

}
