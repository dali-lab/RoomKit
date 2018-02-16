//
//  BeaconManager.swift
//  Nimble
//
//  Created by John Kotz on 2/5/18.
//

import Foundation
import CoreLocation

extension RoomKit {
	public class BeaconManager: NSObject, CLLocationManagerDelegate {
		static var instance: BeaconManager?
		private let locationManager = CLLocationManager()
		private var rangingMaps = Set<Map>()
		private var monitoredMaps = Set<Map>()
		private var regionMapping: [String:Map] = [:]
		private var permissionsStatus: CLAuthorizationStatus!
		
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
			regionMapping[region.proximityUUID.uuidString] = map
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
				regionMapping[region.proximityUUID.uuidString] = map
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
		
		public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
			if let map = regionMapping[(region as! CLBeaconRegion).proximityUUID.uuidString], monitoredMaps.contains(map) {
				for delegate in RoomKit.delegates {
					if let delegate = delegate {
						delegate.enteredMappedRegion(map: map)
					}
				}
			}
		}
		
		public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
			if let map = regionMapping[(region as! CLBeaconRegion).proximityUUID.uuidString], monitoredMaps.contains(map) {
				for delegate in RoomKit.delegates {
					if let delegate = delegate {
						delegate.exitedMappedRegion(map: map)
					}
				}
			}
		}
		
		public func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
			if let map = regionMapping[region.proximityUUID.uuidString] {
				NotificationCenter.default.post(name: NSNotification.Name.RoomKit.BeaconsDidRange, object: map, userInfo: ["beacons": beacons])
			}
		}
		
		var permissionsCallback: ((_ success: Bool) -> Void)? = nil
		public static func requestPermissions(background: Bool, callback: @escaping (_ success: Bool) -> Void) {
			let instance = BeaconManager.getInstance()
			if instance.permissionsStatus != nil && instance.permissionsStatus != CLAuthorizationStatus.notDetermined {
				callback(true)
				return
			}
			
			if background {
				instance.locationManager.requestAlwaysAuthorization()
			}else{
				instance.locationManager.requestWhenInUseAuthorization()
			}
			instance.permissionsCallback = callback
		}
		
		public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
			permissionsStatus = status
			if status == .authorizedAlways || status == .authorizedWhenInUse {
				if let permissionsCallback = permissionsCallback {
					permissionsCallback(true)
				}
			}else if status == .denied || status == .restricted {
				if let permissionsCallback = permissionsCallback {
					permissionsCallback(false)
				}
			}
		}
	}
}
