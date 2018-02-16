//
//  RoomsTablewViewController.swift
//  RoomKit_Example
//
//  Created by John Kotz on 2/15/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import RoomKit
import UIKit

class RoomsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var button: UIButton!
	
	var map: RoomKit.Map!
	
	override func viewDidLoad() {
		self.title = "\(map.name): Rooms"
		
		navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Test", style: .plain, target: self, action: #selector(goToTest))
	}
	
	override func viewWillAppear(_ animated: Bool) {
		tableView.reloadData()
		
		RoomKit.BeaconManager.requestPermissions(background: false) { (success) in
			if !success {
				let alert = UIAlertController(title: "Enable Location Services", message: "Location services are required!", preferredStyle: .alert)
				self.present(alert, animated: true, completion: nil)
			}
		}
	}
	
	@objc func goToTest() {
		self.performSegue(withIdentifier: "goTest", sender: nil)
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return map.rooms.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
		cell.textLabel?.text = map.rooms[indexPath.row]
		var progress: Float? = RoomKit.Trainer.getInstance().progress[map.rooms[indexPath.row]]
		if progress != nil {
			progress = progress! * 100
		}
		cell.detailTextLabel?.text = "\(progress == nil ? 0 : Int(progress!))%"
		cell.accessoryType = .disclosureIndicator
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		self.performSegue(withIdentifier: "showRoom", sender: indexPath.row)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let destination = segue.destination as? TrainRoomViewController {
			destination.map = self.map
			destination.room = sender as! Int
		} else if let destination = segue.destination as? TestViewController {
			destination.map = map
		}
	}
	
	@IBAction func trainButtonPressed(_ sender: UIButton) {
		let view = UIVisualEffectView(frame: self.view.frame)
		let activityIndicator = UIActivityIndicatorView()
		activityIndicator.hidesWhenStopped = true
		activityIndicator.startAnimating()
		activityIndicator.center = self.view.center
		self.view.addSubview(activityIndicator)
		self.view.addSubview(view)
		
		UIView.animate(withDuration: 1) {
			view.effect = UIBlurEffect(style: .dark)
		}
		
		try! RoomKit.Trainer.getInstance().startTraining(map: map, room: map.rooms[0])
		RoomKit.Trainer.getInstance().pauseTraining()
		
		RoomKit.Trainer.getInstance().completeTraining { (success, error) in
			let alert = UIAlertController(title: success ? "Success!" : "ERROR", message: success ? "The model is trained!" : error?.localizedDescription ?? "", preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
			self.present(alert, animated: true, completion: {
				UIView.animate(withDuration: 1, animations: {
					view.effect = nil
				}, completion: { (_) in
					view.removeFromSuperview()
				})
				activityIndicator.stopAnimating()
			})
		}
	}
}
