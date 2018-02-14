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
		public let id: String!
		public let name: String
		public let rooms: [String]
		internal let uuid: String

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
			
			guard let data = try? JSON(["name": name, "rooms": rooms, "uuid": uuid]).rawData() else {
				throw(RoomKit.error.FailedToSerializeData)
			}
			
			let url = URL(string: "\(RoomKit.config.server)/maps")!
			var request = URLRequest(url: url)
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
			BeaconManager.getInstance().startingRangingMap(map: self)
			NotificationCenter.default.addObserver(self, selector: #selector(beaconsDidRange(notification:)), name: Notification.Name.RoomKit.BeaconsDidRange, object: self)
		}
		
		public func stopPredictingRooms() {
			BeaconManager.getInstance().stopMonitoring(map: self)
			NotificationCenter.default.removeObserver(self)
		}
		
		@objc private func beaconsDidRange(notification: Notification) {
			guard let beacons = notification.userInfo?["beacons"] as? [CLBeacon] else {
				return
			}
			
			var dict = [[String: Any]]()
			for beacon in beacons {
				dict.append(["major": beacon.major, "minor": beacon.minor, "strength": beacon.accuracy])
			}
			
			let url = URL(string: "\(RoomKit.config.server)/maps/\(id)")!
			var request = URLRequest(url: url)
			request.addValue(RoomKit.config.userKey, forHTTPHeaderField: "authorization")
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
				guard let roomIndex = json["roomIndex"].int, let room = json["room"].string else {
					return
				}
				
				for delegate in RoomKit.delegates {
					if let delegate = delegate {
						delegate.determined(room: roomIndex, with: room, on: self)
					}
				}
			}
		}
		
		public static func getAll(callback: @escaping ([Map], error?) -> Void) {
			let url = URL(string: "\(RoomKit.config.server)/maps")!
			var request = URLRequest(url: url)
			request.addValue(RoomKit.config.userKey, forHTTPHeaderField: "authorization")
			request.httpMethod = "GET"
			
			URLSession.shared.dataTask(with: request) { (data, response, error) in
				guard let data = data, let json = try? JSON(data: data), let array = json.array else {
					callback([], RoomKit.error.ActionFailed)
					return
				}
				
				var maps = [Map]()
				for item in array {
					if let map = Map.parse(json: item) {
						maps.append(map)
					}
				}
				
				callback(maps, nil)
			}.resume()
		}
		
		public var hashValue: Int {
			return id.hashValue
		}
		
		public static func ==(lhs: RoomKit.Map, rhs: RoomKit.Map) -> Bool {
			return lhs.id == rhs.id
		}
	}
}

