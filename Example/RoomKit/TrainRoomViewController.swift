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
    
    override func viewDidLoad() {
        listener = RoomKit.Trainer.instance.progressEvent.on { (tuple) in
            DispatchQueue.main.async {
                self.updateView(progress: tuple.progress)
            }
        }
    }
	
	override func viewWillAppear(_ animated: Bool) {
        self.title = "\(map.name): \(room.name)"
        updateView(progress: Float(room!.percentTrained))
        listener?.isListening = true
        
        // WHY DO I DO THIS!
        try? RoomKit.Trainer.instance.startTraining(map: map, room: room)
        RoomKit.Trainer.instance.pauseTraining()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
        listener?.isListening = false
        RoomKit.Trainer.instance.forceSaveData(timeout: 5).onSuccess { (_) in
            RoomKit.Trainer.instance.purgeTrainingData()
        }.onFail { (error) in
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Failed to save data", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Done", style: .default, handler: nil))
                alert.show(self.navigationController!, sender: nil)
            }
        }
	}
    
    func updateView(progress: Float) {
        progressBar.progress = progress
        progressLabel.text = "\(round(progress * 1000) / 10)%"
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
