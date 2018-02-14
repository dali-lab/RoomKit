//
//  BeaconManager.swift
//  Nimble
//
//  Created by John Kotz on 2/5/18.
//

import Foundation
import CoreLocation

extension RoomKit {
	class BeaconManager: NSObject, CLLocationManagerDelegate {
		static var instance: BeaconManager?
		private let locationManager = CLLocationManager()
		private var rangingMaps = Set<Map>()
		private var monitoredMaps = Set<Map>()
		private var regionMapping: [CLRegion:Map] = [:]
		
		override init() {
			super.init()
			BeaconManager.instance = self
			locationManager.delegate = self
		}
		
		static func getInstance() -> BeaconManager {
			return instance ?? BeaconManager()
		}
		
		func monitorMap(map: RoomKit.Map) {
			let uuid = UUID(uuidString: map.uuid)!
			let region = CLBeaconRegion(proximityUUID: uuid, identifier: map.id)
			regionMapping[region] = map
			monitoredMaps.insert(map)
			self.locationManager.startMonitoring(for: region)
		}
		
		func stopMonitoring(map: RoomKit.Map) {
			let uuid = UUID(uuidString: map.uuid)!
			let region = CLBeaconRegion(proximityUUID: uuid, identifier: map.id)
			monitoredMaps.remove(map)
			self.locationManager.stopMonitoring(for: region)
		}
		
		func startingRangingMap(map: RoomKit.Map) {
			if rangingMaps.insert(map).inserted {
				let uuid = UUID(uuidString: map.uuid)!
				let region = CLBeaconRegion(proximityUUID: uuid, identifier: map.id)
				regionMapping[region] = map
				self.locationManager.startRangingBeacons(in: region)
			}
		}
		
		func stopRangingMap(map: RoomKit.Map) {
			if rangingMaps.remove(map) != nil {
				let uuid = UUID(uuidString: map.uuid)!
				let region = CLBeaconRegion(proximityUUID: uuid, identifier: map.id)
				self.locationManager.stopRangingBeacons(in: region)
			}
		}
		
		func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
			if let map = regionMapping[region], monitoredMaps.contains(map) {
				for delegate in RoomKit.delegates {
					if let delegate = delegate {
						delegate.enteredMappedRegion(map: map)
					}
				}
			}
		}
		
		func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
			if let map = regionMapping[region], monitoredMaps.contains(map) {
				for delegate in RoomKit.delegates {
					if let delegate = delegate {
						delegate.exitedMappedRegion(map: map)
					}
				}
			}
		}
		
		func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
			if let map = regionMapping[region], monitoredMaps.contains(map) {
				NotificationCenter.default.post(name: NSNotification.Name.RoomKit.BeaconsDidRange, object: map, userInfo: ["beacons": beacons])
			}
		}
	}
}
