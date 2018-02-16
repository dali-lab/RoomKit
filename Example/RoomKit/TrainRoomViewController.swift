//
//  TrainRoomViewController.swift
//  RoomKit_Example
//
//  Created by John Kotz on 2/15/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import RoomKit

class TrainRoomViewController: UIViewController, TrainingDelegate {
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	@IBOutlet weak var progressBar: UIProgressView!
	@IBOutlet weak var progressLabel: UILabel!
	
	var map: RoomKit.Map!
	var room: Int!
	var collecting = false
	
	override func viewWillAppear(_ animated: Bool) {
		progressBar.progress = RoomKit.Trainer.getInstance().progress[map.rooms[room]] ?? 0
		progressLabel.text = "\(RoomKit.Trainer.getInstance().progress[map.rooms[room]] ?? 0)"
		try! RoomKit.Trainer.getInstance().startTraining(map: map, room: map.rooms[room])
		RoomKit.Trainer.getInstance().pauseTraining()
		
		RoomKit.Trainer.getInstance().delegate = self
		
		self.title = "\(map.name): \(map.rooms[room])"
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		RoomKit.Trainer.getInstance().forceSaveData(timeout: 5) { (success) in
			RoomKit.Trainer.getInstance().purgeTrainingData()
		}
	}
	
	func trainingUpdate(progress: [String : Float]) {
		progressBar.progress = progress[map.rooms[room]] ?? 0
		progressLabel.text = "\((progress[map.rooms[room]] ?? 0) * 100)%"
	}
	
	@IBAction func collectionButtonPressed(_ sender: UIButton) {
		if !collecting {
			collecting = true
			sender.setTitle("Stop collecting data", for: .normal)
			activityIndicator.startAnimating()
			navigationItem.hidesBackButton = true
			RoomKit.Trainer.getInstance().resume(with: nil)
		}else{
			collecting = false
			sender.setTitle("Start collecting data", for: .normal)
			activityIndicator.stopAnimating()
			navigationItem.hidesBackButton = false
			RoomKit.Trainer.getInstance().pauseTraining()
		}
	}
}
