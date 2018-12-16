//
//  BeaconManager.swift
//  Nimble
//
//  Created by John Kotz on 2/5/18.
//

import Foundation
import CoreLocation
import EmitterKit
import FutureKit

extension RoomKit {
    /**
     Controls all beacon related information
     */
	public class BeaconManager: NSObject, CLLocationManagerDelegate {
		private static var _instance: BeaconManager?
        public static var instance: BeaconManager {
            if _instance == nil {
                _instance = BeaconManager()
            }
            return _instance!
        }
        
        /// The location manager used to retrieve this information
		private let locationManager = CLLocationManager()
        /// The maps that are being ranged
		private var rangingMaps = Set<Map>()
        /// The maps being monitored
		private var monitoredMaps = Set<Map>()
        /// The maps for each region
		private var regionMapping: [UUID:Map] = [:]
        /// The current status of permissions
		private var permissionsStatus: CLAuthorizationStatus!
        /// The status of the permisison changed
        public var permissionStatusChanged = Event<CLAuthorizationStatus>()
		
        /// Setup
		override init() {
			super.init()
			locationManager.delegate = self
		}
		
        /**
         Monitor this given map
         
         - parameter map: The map to monitor
         */
		func monitorMap(map: RoomKit.Map) {
			let uuid = UUID(uuidString: map.uuid)!
			let region = CLBeaconRegion(proximityUUID: uuid, identifier: map.id)
			regionMapping[uuid] = map
			monitoredMaps.insert(map)
			locationManager.startMonitoring(for: region)
		}
		
        /**
         End monitoring

         - parameter map: Cancel the map monitoring
         */
		func stopMonitoring(map: RoomKit.Map) {
			let uuid = UUID(uuidString: map.uuid)!
			let region = CLBeaconRegion(proximityUUID: uuid, identifier: map.id)
			monitoredMaps.remove(map)
			self.locationManager.stopMonitoring(for: region)
		}
		
        /**
         Range the becons for the given map
         */
		internal func startRangingMap(map: RoomKit.Map) {
			if rangingMaps.insert(map).inserted {
				let uuid = UUID(uuidString: map.uuid)!
				let region = CLBeaconRegion(proximityUUID: uuid, identifier: map.id)
				regionMapping[region.proximityUUID] = map
				self.locationManager.startRangingBeacons(in: region)
			}
		}
		
        /**
         Cancel ranging for the map
         */
		internal func stopRangingMap(map: RoomKit.Map) {
			if rangingMaps.remove(map) != nil {
				let uuid = UUID(uuidString: map.uuid)!
				let region = CLBeaconRegion(proximityUUID: uuid, identifier: map.id)
				self.locationManager.stopRangingBeacons(in: region)
			}
		}
		
        /// Region state
        public func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
            guard let beaconRegion = region as? CLBeaconRegion else {
                return
            }
            // If monitoring a map for this region...
            if let map = regionMapping[beaconRegion.proximityUUID], monitoredMaps.contains(map) {
                RoomKit.mapRegionStateChange.emit((map, state))
            }
        }
		
        /// Beacon ranging received
		public func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
			if let map = regionMapping[region.proximityUUID] {
                map.beaconsDidRange.emit(beacons)
			}
		}
        
        /// Request permissions for access to location
        public func requestPermissions() -> Future<CLAuthorizationStatus> {
            let promise = Promise<CLAuthorizationStatus>()
            permissionStatusChanged.once { (status) in
                promise.completeWithSuccess(status)
            }
            return promise.future
        }
		
        /// Request permissions for access to location
		public static func requestPermissions() -> Future<CLAuthorizationStatus> {
			return BeaconManager.instance.requestPermissions()
		}
		
        private func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
			permissionsStatus = status
			permissionStatusChanged.emit(status)
		}
	}
}
