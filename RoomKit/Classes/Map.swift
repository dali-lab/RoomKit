//
//  Map.swift
//  Nimble
//
//  Created by John Kotz on 2/5/18.
//

import Foundation
import SwiftyJSON
import CoreLocation
import FutureKit
import EmitterKit

extension RoomKit {
	public class Map: Hashable {
		private static let DATA_BUFFER_SIZE = 5
		private static let CLASSIFICATION_BUFFER_SIZE = 1
        
		public let id: String!
		public let name: String
		internal let uuid: String
        public private(set) var rooms: [Room]?
        
        public let roomDeterminedEvent = Event<Room>()
        public let regionStatusEvent = Event<CLRegionState>()
        internal let beaconsDidRange = Event<[CLBeacon]>()
        private var beaconsDidRangeListener: Listener?
        
		private var dataBuffer: [String:(major: NSNumber, minor: NSNumber, accuracy: Double, num: Int)] = [:]
		private var dataBufferCount = 0
		private var classificationBuffer: [(index: Int, name: String)] = []
        public var hashValue: Int { return id.hashValue }

		private init(name: String, uuid: String) {
			id = nil
			self.name = name
			self.uuid = uuid
		}
        
        private init(name: String, id: String, uuid: String) {
            self.id = id
            self.name = name
            self.uuid = uuid
        }
        
        private convenience init?(json: JSON) {
            guard let dict = json.dictionary,
                let id = dict["id"]?.string,
                let name = dict["name"]?.string,
                let uuid = dict["uuid"]?.string else {
                return nil
            }
            
            self.init(name: name, id: id, uuid: uuid)
        }
        
        // MARK: - Static methods
		
        /**
         Create a new map with the given name or uuid
         
         - parameter name: The name of the map
         - parameter uuid: UUID the beacons are configured with on the map
         */
		public static func createNew(name: String, uuid: UUID) -> Future<Map> {
			guard let adminKey = RoomKit.config.adminKey else {
				fatalError("RoomKit: Admin Key missing! You can't use 'createNew' function if you don't have an admin key")
			}
			
			let dict: [String : Any] = ["name": name, "uuid": uuid.uuidString]
			
			guard let data = try? JSON(dict).rawData() else {
                return Future(fail: RoomKit.error.FailedToSerializeData)
			}
			
			let url = URL(string: "\(RoomKit.config.server)/maps")!
			var request = URLRequest(url: url)
			request.addValue("application/json", forHTTPHeaderField: "Content-Type")
			request.addValue(adminKey, forHTTPHeaderField: "authorization")
			request.httpMethod = "POST"
			request.httpBody = data
            
            let promise = Promise<Map>()
			
			URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let data = data, let json = try? JSON(data: data), let map = Map(json: json) {
                    DispatchQueue.main.async { promise.completeWithSuccess(map) }
                } else {
                    DispatchQueue.main.async { promise.completeWithFail(RoomKit.error.ActionFailed) }
                }
			}.resume()
            
            return promise.future
		}
        
        /// Get all the maps
        public static func getAll() -> Future<[Map]> {
            let url = URL(string: "\(RoomKit.config.server)/maps")!
            var request = URLRequest(url: url)
            request.addValue(RoomKit.config.userKey, forHTTPHeaderField: "authorization")
            request.httpMethod = "GET"
            
            let promise = Promise<[Map]>()
            promise.dispatchQueue = OperationQueue.current?.underlyingQueue
            promise.main = promise.dispatchQueue == nil
            
            URLSession.shared.dataTask(with: request) { (data, response, error) in
                guard let data = data, let json = try? JSON(data: data), let array = json.array else {
                    promise.completeWithFail(RoomKit.error.ActionFailed)
                    return
                }
                
                promise.completeWithSuccess(array.compactMap({ (json) -> Map? in
                    let map = Map(json: json)
                    _ = map?.getRooms()
                    return map
                }))
                }.resume()
            
            return promise.future
        }
        
        /// Get a single map using the given id
        static public func getMap(for id: String) -> Future<Map> {
            let promise = Promise<Map>()
            
            // Put together a request
            var request = URLRequest(url: URL(string: "\(config.server)/maps/\(id)")!)
            request.addValue(config.userKey, forHTTPHeaderField: "authorization")
            
            URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let data = data, let json = try? JSON(data: data), let map = Map(json: json) {
                    promise.completeWithSuccess(map)
                }else{
                    promise.completeWithFail(RoomKit.error.UnknownError)
                }
                }.resume()
            
            return promise.future
        }
        
        // MARK: - Rooms
        
        public func newRoom(with name: String) -> Future<Room> {
            guard let adminKey = RoomKit.config.adminKey else {
                return Future<Room>(fail: RoomKit.error.AdminKeyRequired)
            }
            
            let promise = Promise<Room>()
            
            var request = URLRequest(url: URL(string: "\(RoomKit.config.server)/maps/\(id!)/rooms")!)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue(adminKey, forHTTPHeaderField: "authorization")
            let dict: [String:Any] = ["name": name]
            guard let data = try? JSON(dict).rawData() else { return Future(fail: RoomKit.error.FailedToSerializeData ) }
            request.httpBody = data
            
            URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let error = error {
                    promise.completeWithFail(error)
                    return
                }
                
                guard let data = data, let json = try? JSON(data: data), let room = Room(json: json) else {
                    promise.completeWithFail(RoomKit.error.ActionFailed)
                    return
                }
                promise.completeWithSuccess(room)
            }.resume()
            
            return promise.future
        }
        
        public func getRooms() -> Future<[RoomKit.Room]> {
            let promise = Promise<[RoomKit.Room]>()
            
            let urlString = "\(RoomKit.config.server)/maps/\(id!)/rooms"
            var request = URLRequest(url: URL(string: urlString)!)
            request.addValue(RoomKit.config.userKey, forHTTPHeaderField: "authorization")
            request.addValue("ios", forHTTPHeaderField: "os")
            
            URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let error = error {
                    DispatchQueue.main.async {
                        promise.completeWithFail(error)
                    }
                }
                
                guard let data = data, let json = try? JSON(data: data), let array = json.array else {
                    DispatchQueue.main.async {
                        promise.completeWithFail("Failed to parse data")
                    }
                    return
                }
                
                var rooms = [RoomKit.Room]()
                for data in array {
                    if let room = Room(json: data) {
                        rooms.append(room)
                    }
                }
                
                self.rooms = rooms
                DispatchQueue.main.async {
                    promise.completeWithSuccess(rooms)
                }
            }.resume()
            
            return promise.future
        }
        
        // MARK: - Predictions
		
		public func startPredictingRooms() {
			BeaconManager.instance.stopMonitoring(map: self)
			BeaconManager.instance.startRangingMap(map: self)
            beaconsDidRangeListener = beaconsDidRange.on { (beacons) in
                self.beaconsDidRange(beacons)
            }
		}
		
		public func stopPredictingRooms() {
			BeaconManager.instance.stopRangingMap(map: self)
			BeaconManager.instance.stopMonitoring(map: self)
			beaconsDidRangeListener?.isListening = false
		}
		
        func beaconsDidRange(_ beacons: [CLBeacon]) {
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
		
        /// Classify the data buffer
		private func classify() {
			var dict = [[String: Any]]()
			for (_, beacon) in dataBuffer {
				dict.append(["major": beacon.major, "minor": beacon.minor, "strength": beacon.accuracy])
			}
            guard let data = try? JSON(dict).rawData() else {
                print("Failed to serialize data for classification!")
                return
            }
			
			let url = URL(string: "\(RoomKit.config.server)/maps/\(id!)")!
			var request = URLRequest(url: url)
            request.httpMethod = "POST"
			request.addValue("application/json", forHTTPHeaderField: "Content-Type")
			request.addValue(RoomKit.config.userKey, forHTTPHeaderField: "authorization")
			request.addValue("ios", forHTTPHeaderField: "os")
			request.httpBody = data
			
			URLSession.shared.dataTask(with: request) { (data, response, error) in
                guard let data = data, let json = try? JSON(data: data) else {
					return
				}
				guard let dict = json.dictionary, let roomIndex = dict["roomLabel"]?.number?.intValue, let room = dict["room"]?.string else {
					return
				}
				
				var maxClass = 0
				if Map.CLASSIFICATION_BUFFER_SIZE > 1 {
					self.classificationBuffer.append((index: roomIndex, name: room))
					
                    // Count each room index that we got back
					var countArray = [Int](repeating: 0, count: self.classificationBuffer.count)
					for item in self.classificationBuffer {
						countArray[item.index] = countArray[item.index] + 1
					}
                    
                    // Remove something from the buffer if it overflows
					if self.classificationBuffer.count > Map.CLASSIFICATION_BUFFER_SIZE {
						self.classificationBuffer.removeFirst()
					}
					
                    // Get the index with the highest count
                    maxClass = countArray.enumerated().max(by: { (tuple1, tuple2) -> Bool in
                        return tuple1.element > tuple2.element
                    })!.offset
				}else{
					maxClass = roomIndex
				}
				
                DispatchQueue.main.async {
                    self.roomDeterminedEvent.emit(self.rooms![maxClass])
                }
			}.resume()
		}
        
        // MARK: - Hashable
        
        /// Is equal
        public static func ==(lhs: RoomKit.Map, rhs: RoomKit.Map) -> Bool {
            return lhs.id == rhs.id
        }
	}
}

