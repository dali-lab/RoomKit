//
//  MapTrainer.swift
//  Nimble
//
//  Created by John Kotz on 2/5/18.
//

import Foundation
import CoreLocation
import SwiftyJSON

extension RoomKit {
	public class Trainer {
		private static let optimalNumEntries = 500
		static var instance: RoomKit.Trainer!
		public var delegate: TrainingDelegate?
		var trainingMap: Map?
		var currentRoom: String?
		var paused = false
		var entriesSavedForRoom: [String: Int] = [:]
		var locationManager = CLLocationManager()
		var dataBackup: [(room: String, beacons: [CLBeacon])] = []
		public var progress: [String: Float] {
			var progress = [String:Float]()
			for (room, numEntries) in self.entriesSavedForRoom {
				progress[room] = Float(numEntries) / Float(Trainer.optimalNumEntries)
			}
			return progress
		}
		
		private init?() {
			if RoomKit.Trainer.instance != nil {
				return nil
			}
			RoomKit.Trainer.instance = self
		}
		
		public static func getInstance() -> Trainer {
			return Trainer() ?? RoomKit.Trainer.instance
		}
		
		public func startTraining(map: RoomKit.Map, room: String) throws {
			assert(map.rooms.contains(room), "Map's room's must contain the given room")
			if trainingMap != nil {
				throw error.AlreadyTrainingMap
			}
			currentRoom = room
			trainingMap = map
			dataBackup.removeAll()
			paused = false
			BeaconManager.getInstance().startingRangingMap(map: map)
			NotificationCenter.default.addObserver(self, selector: #selector(beaconsDidRange(notification:)), name: Notification.Name.RoomKit.BeaconsDidRange, object: map)
		}
		
		@objc private func beaconsDidRange(notification: Notification) {
			guard !paused, let beacons = notification.userInfo?["beacons"] as? [CLBeacon], let adminKey = RoomKit.config.adminKey else {
				return
			}
			
			dataBackup.append((currentRoom!, beacons))
			
			var request = generateDataSaveRequest()
			request.addValue("application/json", forHTTPHeaderField: "Content-Type")
			request.addValue(adminKey, forHTTPHeaderField: "authorization")
			
			URLSession.shared.dataTask(with: request) { (data, response, error) in
				guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
					// Failed, I think, so add to backlog
					self.dataBackup.append((room: self.currentRoom!, beacons: beacons))
					return
				}
				
				self.entriesSavedForRoom[self.currentRoom!] = (self.entriesSavedForRoom[self.currentRoom!] ?? 0) + self.dataBackup.count
				if let delegate = self.delegate {
					DispatchQueue.main.async {
						delegate.trainingUpdate(progress: self.progress)
					}
				}
				self.dataBackup.removeAll()
			}.resume()
		}
		
		private func generateDataSaveRequest() -> URLRequest {
			var data: [[String:Any]] = []
			for beaconSet in dataBackup {
				var entry = [String:Any]()
				entry["room"] = beaconSet.room
				var entryBeacons = [[String:Any]]()
				for beacon in beaconSet.beacons {
					entryBeacons.append(["major": beacon.major, "minor": beacon.minor, "strength": beacon.accuracy])
				}
				entry["readings"] = entryBeacons
				data.append(entry)
			}
			
			var request = URLRequest(url: URL(string: "\(RoomKit.config.server)/maps/\(trainingMap!.id!)")!)
			request.httpMethod = "PUT"
			if let data = try? JSON(data).rawData() {
				request.httpBody = data
			}
			
			return request
		}
		
		public func pauseTraining() {
			paused = true
		}
		
		public func resume(with room: String?) {
			if let room = room {
				currentRoom = room
			}
			paused = false
		}
		
		public func forceSaveData(timeout: TimeInterval, callback: @escaping (_ success: Bool) -> Void) {
			guard dataBackup.count > 0 else {
				callback(true)
				return
			}
			guard let adminKey = RoomKit.config.adminKey else {
				callback(false)
				return
			}
			var request = generateDataSaveRequest()
			request.addValue(adminKey, forHTTPHeaderField: "authorization")
			request.timeoutInterval = timeout
			
			URLSession.shared.dataTask(with: request) { (data, response, error) in
				guard let httpResponse = response as? HTTPURLResponse else {
					callback(false)
					return
				}
				if httpResponse.statusCode == 200 {
					self.dataBackup.removeAll()
				}
				callback(httpResponse.statusCode == 200)
			}
		}
		
		public func completeTraining(callback: @escaping (_ success: Bool, _ error: Error?) -> Void) {
			guard let adminKey = RoomKit.config.adminKey else {
				return
			}
			
			var request = URLRequest(url: URL(string: "\(RoomKit.config.server)/maps/\(trainingMap!.id!)/train")!)
			request.httpMethod = "POST"
			request.addValue(adminKey, forHTTPHeaderField: "authorization")
			
			self.forceSaveData(timeout: 20) { (success) in
				if !success {
					callback(false, nil)
					return
				}
				
				URLSession.shared.dataTask(with: request) { (data, response, error) in
					guard let httpResponse = response as? HTTPURLResponse else {
						callback(false, error)
						return
					}
					
					callback(httpResponse.statusCode == 200, error)
				}.resume()
			}
		}
		
		public func purgeTrainingData() {
			if let trainingMap = trainingMap {
				BeaconManager.getInstance().stopMonitoring(map: trainingMap)
			}
			trainingMap = nil
			currentRoom = nil
			dataBackup.removeAll()
			NotificationCenter.default.removeObserver(self)
		}
	}
}
