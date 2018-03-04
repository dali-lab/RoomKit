//
//  MapsTableViewController.swift
//  RoomKit_Example
//
//  Created by John Kotz on 2/14/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import RoomKit

class MapsTableViewController: UITableViewController {
	var maps: [RoomKit.Map] = []
	
	override func viewDidLoad() {
		
	}
	
	@IBAction func addButtonPressed(_ sender: Any) {
		self.performSegue(withIdentifier: "newMap", sender: nil)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		RoomKit.Map.getAll { (maps, error) in
			self.maps = maps
			print(maps.first?.id)
			self.tableView.reloadData()
		}
	}
	
	@IBAction func logoutPressed(_ sender: Any) {
		UserDefaults.standard.removeObject(forKey: "adminKey")
		UserDefaults.standard.removeObject(forKey: "userKey")
		self.performSegue(withIdentifier: "logout", sender: nil)
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return maps.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
		cell.textLabel?.text = maps[indexPath.row].name
		cell.accessoryType = .disclosureIndicator
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		self.performSegue(withIdentifier: "showRooms", sender: maps[indexPath.row])
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let dest = segue.destination as? RoomsViewController {
			dest.map = sender as! RoomKit.Map
		}
	}
}
