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

class TestViewController: UIViewController, RoomKitDelegate {
	@IBOutlet weak var predictionLabel: UILabel!
	
	var map: RoomKit.Map!
	var delegateID: RoomKitDelegateID?
	var inside = false
	var room: String?
	
	override func viewWillAppear(_ animated: Bool) {
		delegateID = RoomKit.registerDelegate(delegate: self)
		map.startPredictingRooms()
		self.predictionLabel.text = "Loading..."
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		inside = false
		room = nil
		map.stopPredictingRooms()
		if let delegateID = delegateID {
			RoomKit.unregisterDelegate(i: delegateID)
		}
	}
	
	func enteredMappedRegion(map: RoomKit.Map) {
		inside = true
		self.update()
	}
	
	func determined(room: Int, with name: String, on map: RoomKit.Map) {
		self.room = name
		self.update()
	}
	
	func exitedMappedRegion(map: RoomKit.Map) {
		inside = false
		self.update()
	}
	
	func update() {
		predictionLabel.text = room ?? "Loading..."
	}
}
