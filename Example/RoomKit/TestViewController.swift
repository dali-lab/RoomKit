//
//  TestViewController.swift
//  RoomKit_Example
//
//  Created by John Kotz on 2/15/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import RoomKit
import EmitterKit
import CoreLocation

class TestViewController: UIViewController {
	@IBOutlet weak var predictionLabel: UILabel!
	
	var map: RoomKit.Map!
	var inside = false
	var room: RoomKit.Room?
    var roomDeterminedListener: Listener?
    var regionStateListener: Listener?
    
    override func viewDidLoad() {
        roomDeterminedListener = map.roomDeterminedEvent.on { (room) in
            self.room = room
            self.update()
        }
        regionStateListener = map.regionStatusEvent.on { (state) in
            self.inside = (state == .inside)
            self.update()
        }
    }
    
	override func viewWillAppear(_ animated: Bool) {
		map.startPredictingRooms()
		predictionLabel.text = "Loading..."
        regionStateListener?.isListening = true
        roomDeterminedListener?.isListening = true
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		inside = false
		room = nil
		map.stopPredictingRooms()
        regionStateListener?.isListening = false
        roomDeterminedListener?.isListening = false
	}
	
	func update() {
		predictionLabel.text = room?.name ?? "Loading..."
	}
}
