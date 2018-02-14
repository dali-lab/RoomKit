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
		private var rangingMaps = [Map]()
		
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
			
			self.locationManager.startMonitoring(for: region)
		}
		
		func startingRangingMap(map: RoomKit.Map) {
			let uuid = UUID(uuidString: map.uuid)!
			let region = CLBeaconRegion(proximityUUID: uuid, identifier: map.id)
			self.locationManager.startRangingBeacons(in: region)
		}
		
		func stopRangingMap(map: RoomKit.Map) {
			let uuid = UUID(uuidString: map.uuid)!
			let region = CLBeaconRegion(proximityUUID: uuid, identifier: map.id)
			self.locationManager.stopRangingBeacons(in: region)
		}
		
		func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
			
		}
		
		func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
			
		}
		
		func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
			
		}
	}
}
