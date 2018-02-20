//
//  ViewController.swift
//  RoomKit
//
//  Created by johnlev on 02/01/2018.
//  Copyright (c) 2018 johnlev. All rights reserved.
//

import UIKit
import RoomKit

class ViewController: UIViewController {
	@IBOutlet weak var connectButton: UIButton!
	@IBOutlet weak var adminKeyTextField: UITextField!
	@IBOutlet weak var userKeyTextField: UITextField!
	@IBOutlet weak var loader: UIActivityIndicatorView!
	
	var dict = ["serverURL": "https://roomkit.herokuapp.com"]
	
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
		dict["adminKey"] = UserDefaults.standard.string(forKey: "adminKey") ?? dict["adminKey"]
		dict["userKey"] = UserDefaults.standard.string(forKey: "userKey") ?? dict["userKey"]
		self.authenticate()
    }
	
	func authenticate() {
		guard dict["adminKey"] != nil && dict["userKey"] != nil else {
			return
		}
		adminKeyTextField.resignFirstResponder()
		userKeyTextField.resignFirstResponder()
		adminKeyTextField.isEnabled = false
		userKeyTextField.isEnabled = false
		connectButton.isEnabled = false
		
		loader.startAnimating()
		
		let config = RoomKit.Config(dict: dict)!
		RoomKit.configure(config: config) { (error) in
			self.loader.stopAnimating()
			if let error = error {
				self.adminKeyTextField.isEnabled = true
				self.userKeyTextField.isEnabled = true
				self.updateConnectEnabled()
				print(error)
				self.show(UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert), sender: nil)
			}else{
				self.performSegue(withIdentifier: "authenticated", sender: nil)
			}
		}
	}
	
	@IBAction func textFeildChanged(_ sender: UITextField) {
		self.updateConnectEnabled()
	}
	
	@IBAction func connectButtonPressed(_ sender: Any) {
		UserDefaults.standard.set(adminKeyTextField.text, forKey: "adminKey")
		UserDefaults.standard.set(userKeyTextField.text, forKey: "userKey")
		dict["adminKey"] = adminKeyTextField.text
		dict["userKey"] = userKeyTextField.text
		self.authenticate()
	}
	
	func updateConnectEnabled() {
		connectButton.isEnabled = adminKeyTextField.text! != "" && userKeyTextField.text! != ""
	}
	
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

