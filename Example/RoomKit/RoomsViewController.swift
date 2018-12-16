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
import CoreLocation

/**
 Shows a list of rooms in the given map
 */
class RoomsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var button: UIButton!
	
	var map: RoomKit.Map!
    var rooms: [RoomKit.Room]?
	
	override func viewDidLoad() {
		self.title = "\(map.name): Rooms"
        self.rooms = map.rooms
		
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newRoom))
	}
	
	override func viewWillAppear(_ animated: Bool) {
        self.reloadData()
		
        _ = RoomKit.BeaconManager.requestPermissions().onSuccess { (status) in
            if status == CLAuthorizationStatus.denied {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Enable Location Services", message: "Location services are required!", preferredStyle: .alert)
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
	}
    
    func reloadData() {
        _ = map.getRooms().onSuccess { (rooms) in
            self.rooms = rooms
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }.onFail { (error)  in
            print(error)
        }
    }
    
    @objc func newRoom() {
        let alert = UIAlertController(title: "Name of room", message: "What is the name of the room?", preferredStyle: .alert)
        
        var savedTextField: UITextField?
        alert.addTextField { (textField) in
            textField.autocapitalizationType = UITextAutocapitalizationType.words
            savedTextField = textField
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Add Room", style: .default, handler: { (action) in
            _ = self.map.newRoom(with: savedTextField!.text!).onSuccess { (_) in
                self.reloadData()
            }
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
	
	@IBAction func goToTest() {
		self.performSegue(withIdentifier: "goTest", sender: nil)
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return rooms?.count ?? 0
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
		cell.textLabel?.text = rooms?[indexPath.row].name
		var progress: Double? = rooms?[indexPath.row].percentTrained
		if progress != nil {
			progress = progress! * 100
		}
		cell.detailTextLabel?.text = "\(progress == nil ? 0 : Int(progress!))%"
		cell.accessoryType = .disclosureIndicator
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		self.performSegue(withIdentifier: "showRoom", sender: rooms?[indexPath.row])
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let destination = segue.destination as? TrainRoomViewController {
			destination.map = self.map
			destination.room = sender as? RoomKit.Room
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
		
        // WHY DO I DO THIS!
        try? RoomKit.Trainer.instance.startTraining(map: map, room: rooms![0])
		RoomKit.Trainer.instance.pauseTraining()
		
        RoomKit.Trainer.instance.completeTraining().onComplete { (result) in
            let success = result.isSuccess
            let error = result.error
            
            DispatchQueue.main.async {
                let alert = UIAlertController(title: success ? "Success!" : "ERROR", message: success ? "The model is trained!" : error?.localizedDescription ?? "", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                
                self.present(alert, animated: true, completion: {
                    UIView.animate(withDuration: 2, animations: {
                        view.effect = nil
                    }, completion: { (_) in
                        view.removeFromSuperview()
                    })
                    activityIndicator.stopAnimating()
                })
            }
        }
	}
}
