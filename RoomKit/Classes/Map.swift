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
	public struct Map {
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
		
		public static func createNew(name: String, rooms: [String], uuid: String, callback: @escaping (Error?) -> Void) throws {
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
						callback(nil)
					}
					return
				}
				
				DispatchQueue.main.async {
					callback(response.statusCode == 200 ? nil : RoomKit.error.ActionFailed)
				}
			}.resume()
		}
		
		public func startTraining(startingRoom room: String) {
			assert(rooms.contains(room))
			
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
		
		public func predict(beacons: [CLBeacon]) {
			
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
	}
}

