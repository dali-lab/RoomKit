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
    
    var adminKey: String?
    var userKey: String?
	
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
		adminKey = UserDefaults.standard.string(forKey: "adminKey") ?? adminKey
		userKey = UserDefaults.standard.string(forKey: "userKey") ?? userKey
		self.authenticate()
    }
	
	func authenticate() {
		guard let adminKey = adminKey, let userKey = userKey else {
			return
		}
		adminKeyTextField.resignFirstResponder()
		userKeyTextField.resignFirstResponder()
		adminKeyTextField.isEnabled = false
		userKeyTextField.isEnabled = false
		connectButton.isEnabled = false
		
		loader.startAnimating()
		
        let config = RoomKit.Config(userKey: userKey, adminKey: adminKey)
		RoomKit.configure(config: config) { (error) in
			self.loader.stopAnimating()
			if let error = error {
				self.adminKeyTextField.isEnabled = true
				self.userKeyTextField.isEnabled = true
				self.updateConnectEnabled()
				print(error)
                
                let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Done", style: .default, handler: nil))
				self.show(alert, sender: nil)
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
		adminKey = adminKeyTextField.text
		userKey = userKeyTextField.text
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

