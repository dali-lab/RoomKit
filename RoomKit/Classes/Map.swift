//
//  Map.swift
//  Nimble
//
//  Created by John Kotz on 2/5/18.
//

import Foundation
import SwiftyJSON
import CoreLocation

extension RoomKit {
	public class Map: Hashable {
		private static let DATA_BUFFER_SIZE = 5
		private static let CLASSIFICATION_BUFFER_SIZE = 1
		public let id: String!
		public let name: String
		public let rooms: [String]
		internal let uuid: String
		private var dataBuffer: [String:(major: NSNumber, minor: NSNumber, accuracy: Double, num: Int)] = [:]
		private var dataBufferCount = 0
		private var classificationBuffer: [(index: Int, name: String)] = []

		private init(name: String, rooms: [String], uuid: String) {
			id = nil
			self.name = name
			self.rooms = rooms
			self.uuid = uuid
		}
		
		public static func createNew(name: String, rooms: [String], uuid: String, callback: @escaping (Map?, Error?) -> Void) throws {
			guard let adminKey = RoomKit.config.adminKey else {
				fatalError("RoomKit: Admin Key missing! You can't use 'createNew' function if you don't have an admin key")
			}
			
			let dict: [String : Any] = ["name": name, "rooms": rooms, "uuid": uuid]
			
			guard let data = try? JSON(dict).rawData() else {
				throw(RoomKit.error.FailedToSerializeData)
			}
			
			let url = URL(string: "\(RoomKit.config.server)/maps")!
			var request = URLRequest(url: url)
			request.addValue("application/json", forHTTPHeaderField: "Content-Type")
			request.addValue(adminKey, forHTTPHeaderField: "authorization")
			request.httpMethod = "POST"
			request.httpBody = data
			
			URLSession.shared.dataTask(with: request) { (data, response, error) in
				guard let response = response as? HTTPURLResponse else {
					DispatchQueue.main.async {
						callback(nil, RoomKit.error.UnknownError)
					}
					return
				}
				
				if let data = data {
					if let map = Map.parse(json: JSON(data)) {
						DispatchQueue.main.async {
							callback(map, nil)
						}
						return
					}
				}
				
				DispatchQueue.main.async {
					callback(nil, response.statusCode == 200 ? nil : RoomKit.error.ActionFailed)
				}
			}.resume()
		}

		private init(name: String, id: String, uuid: String, rooms: [String]) {
			self.id = id
			self.name = name
			self.rooms = rooms
			self.uuid = uuid
		}

		private static func parse(json: JSON) -> Map? {
			guard let dict = json.dictionary, let id = dict["id"]?.string, let name = dict["name"]?.string, let uuid = dict["uuid"]?.string, let roomsArray = dict["rooms"]?.array else {
				return nil
			}
			
			var rooms = [String]()
			for item in roomsArray {
				if let item = item.string {
					rooms.append(item)
				}
			}
			
			return Map(name: name, id: id, uuid: uuid, rooms: rooms)
		}
		
		public func startPredictingRooms() {
			BeaconManager.getInstance().stopMonitoring(map: self)
			BeaconManager.getInstance().startingRangingMap(map: self)
			NotificationCenter.default.addObserver(self, selector: #selector(beaconsDidRange(notification:)), name: Notification.Name.RoomKit.BeaconsDidRange, object: self)
		}
		
		public func stopPredictingRooms() {
			BeaconManager.getInstance().stopRangingMap(map: self)
			BeaconManager.getInstance().stopMonitoring(map: self)
			NotificationCenter.default.removeObserver(self)
		}
		
		@objc private func beaconsDidRange(notification: Notification) {
			guard let beacons = notification.userInfo?["beacons"] as? [CLBeacon] else {
				return
			}
			
			for beacon in beacons {
				if let thing = dataBuffer["\(beacon.major):\(beacon.minor)"] {
					let accuracy = beacon.accuracy * 1/Double(thing.num) + thing.accuracy * Double((thing.num - 1))/Double(thing.num)
					dataBuffer["\(beacon.major):\(beacon.minor)"] = (major: beacon.major, minor: beacon.minor, accuracy: accuracy, num: thing.num + 1)
				}else {
					dataBuffer["\(beacon.major):\(beacon.minor)"] = (major: beacon.major, minor: beacon.minor, accuracy: beacon.accuracy, num: 1)
				}
			}
			dataBufferCount += 1
			if dataBufferCount > Map.DATA_BUFFER_SIZE {
				self.classify()
				self.dataBuffer.removeAll()
				dataBufferCount = 0
			}
		}
		
		private func classify() {
			
			var dict = [[String: Any]]()
			for (_, beacon) in dataBuffer {
				dict.append(["major": beacon.major, "minor": beacon.minor, "strength": beacon.accuracy])
			}
			
			let url = URL(string: "\(RoomKit.config.server)/maps/\(id!)")!
			var request = URLRequest(url: url)
			request.addValue("application/json", forHTTPHeaderField: "Content-Type")
			request.addValue(RoomKit.config.userKey, forHTTPHeaderField: "authorization")
			request.addValue("ios", forHTTPHeaderField: "client_os")
			request.httpMethod = "POST"
			guard let data = try? JSON(dict).rawData() else {
				return
			}
			request.httpBody = data
			
			URLSession.shared.dataTask(with: request) { (data, response, error) in
				guard let data = data else {
					return
				}
				let json = JSON(data)
				guard let dict = json.dictionary, let roomIndex = dict["roomIndex"]?.int, let room = dict["room"]?.string else {
					return
				}
				
				var maxClass = 0
				if Map.CLASSIFICATION_BUFFER_SIZE > 1 {
				
					self.classificationBuffer.append((index: roomIndex, name: room))
					
					var countDict = [Int](repeating: 0, count: self.classificationBuffer.count)
					for item in self.classificationBuffer {
						countDict[item.index] = countDict[item.index] + 1
					}
					if self.classificationBuffer.count > Map.CLASSIFICATION_BUFFER_SIZE {
						self.classificationBuffer.removeFirst()
					}
					
					var max = 0
					for i in 0..<countDict.count {
						if max < countDict[i] {
							max = countDict[i]
							maxClass = i
						}
					}
				}else{
					maxClass = roomIndex
				}
				
				for delegate in RoomKit.delegates {
					if let delegate = delegate {
						DispatchQueue.main.async {
							delegate.determined(room: maxClass, with: self.rooms[maxClass], on: self)
						}
					}
				}
			}.resume()
		}
		
		public static func getAll(callback: @escaping ([Map], error?) -> Void) {
			let url = URL(string: "\(RoomKit.config.server)/maps")!
			var request = URLRequest(url: url)
			request.addValue(RoomKit.config.userKey, forHTTPHeaderField: "authorization")
			request.httpMethod = "GET"
			
			URLSession.shared.dataTask(with: request) { (data, response, error) in
				guard let data = data, let json = try? JSON(data: data), let array = json.array else {
					DispatchQueue.main.async {
						callback([], RoomKit.error.ActionFailed)
					}
					return
				}
				
				var maps = [Map]()
				for item in array {
					if let map = Map.parse(json: item) {
						maps.append(map)
					}
				}
				
				DispatchQueue.main.async {
					callback(maps, nil)
				}
			}.resume()
		}
		
		public var hashValue: Int {
			return id.hashValue
		}
		
		public static func ==(lhs: RoomKit.Map, rhs: RoomKit.Map) -> Bool {
			return lhs.id == rhs.id
		}
		
		static public func getMap(for id: String, callback: ((Map?) -> Void)?) {
			var request = URLRequest(url: URL(string: "\(config.server)/maps/\(id)")!)
			request.addValue(config.userKey, forHTTPHeaderField: "authorization")
			
			URLSession.shared.dataTask(with: request) { (data, response, error) in
				if let data = data {
					let object = JSON(data)
					if let callback = callback {callback(Map.parse(json: object))}
				}else{
					if let callback = callback {callback(nil)}
				}
			}.resume()
		}
	}
}

