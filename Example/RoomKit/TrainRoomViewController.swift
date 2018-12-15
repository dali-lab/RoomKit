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
import EmitterKit

class TrainRoomViewController: UIViewController {
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	@IBOutlet weak var progressBar: UIProgressView!
	@IBOutlet weak var progressLabel: UILabel!
	
	var map: RoomKit.Map!
	var room: RoomKit.Room!
	var collecting = false
    var listener: Listener?
	
	override func viewWillAppear(_ animated: Bool) {
        
        // WHY DO I DO THIS!
		try! RoomKit.Trainer.instance.startTraining(map: map, room: room)
		RoomKit.Trainer.instance.pauseTraining()
		
		self.title = "\(map.name): \(room.name)"
        updateView(progress: RoomKit.Trainer.instance.progress[room] ?? 0)
        
        listener = RoomKit.Trainer.instance.progressEvent.on { (progress) in
            self.updateView(progress: progress[self.room] ?? 0)
        }
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		RoomKit.Trainer.instance.forceSaveData(timeout: 5) { (success) in
			RoomKit.Trainer.instance.purgeTrainingData()
		}
	}
    
    func updateView(progress: Float) {
        progressBar.progress = progress
        let percent = round(progress * 1000) / 10
        progressLabel.text = "\(percent)%"
    }
	
	@IBAction func collectionButtonPressed(_ sender: UIButton) {
		if !collecting {
			collecting = true
			sender.setTitle("Stop collecting data", for: .normal)
			activityIndicator.startAnimating()
			navigationItem.hidesBackButton = true
			RoomKit.Trainer.instance.resume(with: nil)
		}else{
			collecting = false
			sender.setTitle("Start collecting data", for: .normal)
			activityIndicator.stopAnimating()
			navigationItem.hidesBackButton = false
			RoomKit.Trainer.instance.pauseTraining()
		}
	}
}
