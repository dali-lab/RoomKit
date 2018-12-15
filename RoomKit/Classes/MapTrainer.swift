//
//  MapTrainer.swift
//  Nimble
//
//  Created by John Kotz on 2/5/18.
//

import Foundation
import CoreLocation
import SwiftyJSON
import FutureKit
import EmitterKit

extension RoomKit {
	public class Trainer {
        private static var _instance: RoomKit.Trainer?
        public static var instance: RoomKit.Trainer {
            if _instance == nil {
                _instance = Trainer()
            }
            return _instance!
        }
        
		private static let optimalNumEntries = 500
        public let progressEvent = Event<[Room: Float]>()
		var trainingMap: Map?
		var currentRoom: Room?
		var paused = false
		var entriesSavedForRoom: [Room: Int] = [:]
		var locationManager = CLLocationManager()
		var dataBackup: [(room: Room, beacons: [CLBeacon])] = []
		public var progress: [Room: Float] {
			var progress = [Room:Float]()
			for (room, numEntries) in self.entriesSavedForRoom {
				progress[room] = Float(numEntries) / Float(Trainer.optimalNumEntries)
			}
			return progress
		}
		
		private init() {
            progressEvent.main = true
        }
		
		public func startTraining(map: RoomKit.Map, room: Room) throws {
			if trainingMap != nil {
				throw error.AlreadyTrainingMap
			}
			currentRoom = room
			trainingMap = map
			dataBackup.removeAll()
			paused = false
			BeaconManager.instance.startRangingMap(map: map)
			NotificationCenter.default.addObserver(self, selector: #selector(beaconsDidRange(notification:)), name: Notification.Name.RoomKit.BeaconsDidRange, object: map)
		}
		
		@objc private func beaconsDidRange(notification: Notification) {
			guard !paused, let beacons = notification.userInfo?["beacons"] as? [CLBeacon], let adminKey = RoomKit.config.adminKey else {
				return
			}
			
			dataBackup.append((currentRoom!, beacons))
			
			let request = generateDataSaveRequest(adminKey: adminKey)
			
			URLSession.shared.dataTask(with: request) { (data, response, error) in
				guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
					// Failed, I think, so add to backlog
					self.dataBackup.append((room: self.currentRoom!, beacons: beacons))
					return
				}
				
				self.entriesSavedForRoom[self.currentRoom!] = (self.entriesSavedForRoom[self.currentRoom!] ?? 0) + self.dataBackup.count
				self.progressEvent.emit(self.progress)
				self.dataBackup.removeAll()
			}.resume()
		}
		
		private func generateDataSaveRequest(adminKey: String) -> URLRequest {
			var data: [[String:Any]] = []
			for beaconSet in dataBackup {
				var entry = [String:Any]()
				entry["room"] = beaconSet.room.name
				var entryBeacons = [[String:Any]]()
				for beacon in beaconSet.beacons {
					entryBeacons.append(["major": beacon.major, "minor": beacon.minor, "strength": beacon.accuracy])
				}
				entry["readings"] = entryBeacons
				data.append(entry)
			}
			
			var request = URLRequest(url: URL(string: "\(RoomKit.config.server)/maps/\(trainingMap!.id!)")!)
			request.addValue("ios", forHTTPHeaderField: "os")
			request.addValue("application/json", forHTTPHeaderField: "Content-Type")
			request.addValue(adminKey, forHTTPHeaderField: "authorization")
			request.httpMethod = "PUT"
			if let data = try? JSON(data).rawData() {
				request.httpBody = data
			}
			
			return request
		}
		
		public func pauseTraining() {
			paused = true
		}
		
		public func resume(with room: Room?) {
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
			var request = generateDataSaveRequest(adminKey: adminKey)
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
		
		public func completeTraining() -> Future<Void> {
            guard let adminKey = RoomKit.config.adminKey else {
                return Future<Void>(fail: RoomKit.error.AdminKeyRequired)
            }
            
            let promise = Promise<Void>()
            promise.main = true
			
			var request = URLRequest(url: URL(string: "\(RoomKit.config.server)/maps/\(trainingMap!.id!)/train")!)
			request.httpMethod = "POST"
			request.addValue(adminKey, forHTTPHeaderField: "authorization")
			request.addValue("ios", forHTTPHeaderField: "os")
			
			self.forceSaveData(timeout: 20) { (success) in
				guard success else {
                    promise.failIfNotCompleted(RoomKit.error.FailedToConnect)
					return
				}
				
				URLSession.shared.dataTask(with: request) { (data, response, error) in
					if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                        promise.completeWithSuccess(Void())
                    } else {
                        promise.completeWithFail(error ?? RoomKit.error.UnknownError)
                    }
				}.resume()
			}
            
            return promise.future
		}
		
		public func purgeTrainingData() {
			if let trainingMap = trainingMap {
				BeaconManager.instance.stopMonitoring(map: trainingMap)
			}
			trainingMap = nil
			currentRoom = nil
			dataBackup.removeAll()
			NotificationCenter.default.removeObserver(self)
		}
	}
}
