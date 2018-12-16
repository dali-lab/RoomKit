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
        
        public let progressEvent = Event<(room: Room, progress: Float)>()
        private var beaconsDidRangeListner: Listener?
		var trainingMap: Map?
		var currentRoom: Room?
		var paused = false
		var locationManager = CLLocationManager()
		var dataBackup: [(room: Room, beacons: [CLBeacon])] = []
		
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
            beaconsDidRangeListner = map.beaconsDidRange.on { (beacons) in
                self.beaconsDidRange(beacons)
            }
		}
        
        public func pauseTraining() {
            paused = true
            beaconsDidRangeListner?.isListening = false
        }
        
        public func resume(with room: Room?) {
            if let room = room {
                currentRoom = room
            }
            paused = false
            beaconsDidRangeListner?.isListening = true
        }
		
        private func beaconsDidRange(_ beacons: [CLBeacon]) {
			guard let adminKey = RoomKit.config.adminKey, !paused else {
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
                guard let data = data, let json = try? JSON(data: data), let dict = json.dictionary else {
                    return
                }
                guard let progress = dict[self.currentRoom!.name]?.float else {
                    return
                }
				
				self.progressEvent.emit((self.currentRoom!, progress))
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
		
        /**
         Save the data on server with the given timeout
         
         - parameter timeout: Ammount of time to wait
         - returns: The future
         */
		public func forceSaveData(timeout: TimeInterval) -> Future<Void> {
			guard dataBackup.count > 0 else {
				return Future(success: Void())
			}
			guard let adminKey = RoomKit.config.adminKey else {
				return Future(fail: RoomKit.error.AdminKeyRequired)
			}
            let promise = Promise<Void>()
			var request = generateDataSaveRequest(adminKey: adminKey)
			request.timeoutInterval = timeout
			
			URLSession.shared.dataTask(with: request) { (data, response, error) in
				guard let httpResponse = response as? HTTPURLResponse else {
					promise.completeWithFail(RoomKit.error.UnknownError)
					return
				}
				if httpResponse.statusCode == 200 {
					self.dataBackup.removeAll()
                    promise.completeWithSuccess(Void())
                } else {
                    promise.completeWithFail(error ?? RoomKit.error.ActionFailed)
                }
			}.resume()
            return promise.future
		}
		
		public func completeTraining() -> Future<Void> {
            guard let adminKey = RoomKit.config.adminKey else {
                return Future<Void>(fail: RoomKit.error.AdminKeyRequired)
            }
            
            let promise = Promise<Void>()
            promise.main = true
			
            let urlString = "\(RoomKit.config.server)/maps/\(trainingMap!.id!)/train"
			var request = URLRequest(url: URL(string: urlString)!)
			request.httpMethod = "POST"
			request.addValue(adminKey, forHTTPHeaderField: "authorization")
			request.addValue("ios", forHTTPHeaderField: "os")
			
            forceSaveData(timeout: 20).onSuccess { (_) in
                URLSession.shared.dataTask(with: request) { (data, response, error) in
                    if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                        promise.completeWithSuccess(Void())
                    } else {
                        promise.completeWithFail(error ?? RoomKit.error.UnknownError)
                    }
                }.resume()
            }.onFail { (error) in
                promise.completeWithFail(error)
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
            beaconsDidRangeListner?.isListening = false
		}
	}
}
