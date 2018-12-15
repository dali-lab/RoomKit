//
//  NewMapTableViewController.swift
//  RoomKit_Example
//
//  Created by John Kotz on 2/14/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import RoomKit

class NewMapTableViewController: UITableViewController {
	var name: String?
	var uuid: UUID?
	var uuidString: String?
	
	override func viewDidLoad() {
		tableView.reloadData()
		
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed))
	}
	
	@objc func doneButtonPressed() {
		guard let name = name, let uuid = uuid else {
			let controller = UIAlertController(title: "Error", message: "Missing some value", preferredStyle: .alert)
			controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
			self.present(controller, animated: true, completion: nil)
			return
		}
		
        RoomKit.Map.createNew(name: name, uuid: uuid.uuidString).onSuccess { (map) in
            self.navigationController?.popViewController(animated: true)
        }.onFail { (error) in
            let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return "General"
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 2
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        cell.textLabel?.text = indexPath.row == 0 ? "Name" : "UUID"
        cell.detailTextLabel?.text = indexPath.row == 0 ? name : uuidString
        return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
			let controller = UIAlertController(title: "Name", message: "Enter the name of the map", preferredStyle: .alert)
			var field: UITextField!
			controller.addTextField(configurationHandler: { (textField) in
				field = textField
			})
			controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
			controller.addAction(UIAlertAction(title: "Set", style: .default, handler: { (action) in
				self.name = field.text
				tableView.reloadData()
			}))
			self.present(controller, animated: true, completion: nil)
			tableView.deselectRow(at: indexPath, animated: true)
		}else if indexPath.row == 1 {
			let controller = UIAlertController(title: "UUID", message: "Enter the uuid that will be tracked for this map", preferredStyle: .alert)
			var field: UITextField!
			controller.addTextField(configurationHandler: { (textField) in
				field = textField
			})
			controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
			controller.addAction(UIAlertAction(title: "Set", style: .default, handler: { (action) in
				if let uuid = UUID(uuidString: field.text!) {
					self.uuid = uuid
					self.uuidString = field.text
					tableView.reloadData()
				}else{
					let controller = UIAlertController(title: "Error", message: "Invalid UUID", preferredStyle: .alert)
					controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
					self.present(controller, animated: true, completion: nil)
				}
			}))
			self.present(controller, animated: true, completion: nil)
			tableView.deselectRow(at: indexPath, animated: true)
		}else{
			tableView.deselectRow(at: indexPath, animated: false)
		}
	}
}
