//
//  RoomKit.swift
//  Nimble
//
//  Created by John Kotz on 2/2/18.
//

import Foundation
import CoreLocation
import EmitterKit

public class RoomKit {
	private static var unProtConfig: RoomKit.Config!
	public static var config: RoomKit.Config {
		if self.unProtConfig == nil {
			fatalError("RoomKit: Config missing! You are required to have a configuration\n" +
				"Run:\nlet config = RoomKit.Config(dict: NSDictionary(contentsOfFile: filePath))\n" +
				"DALIapi.configure(config)\n" +
				"before you use it")
		}
		return unProtConfig!
	}
    public static let mapRegionStateChange = Event<(map: Map, state: CLRegionState)>()
	
	public static func configure(config: RoomKit.Config, callback: ((RoomKit.error?) -> Void)?) {
		RoomKit.unProtConfig = config
		config.validate { (success, reason) in
			DispatchQueue.main.async {
				if !success {
					if let callback = callback {
						callback(RoomKit.error.ConfigValidationFailed(reason: reason ?? "unknown"))
					}else{
						fatalError("Config validation failed! Reason: \(reason ?? "unknown")")
					}
				}else{
					RoomKit.unProtConfig = config
					callback?(nil)
					startMonitoring()
				}
			}
		}
	}
	
	private static func startMonitoring() {
        _ = Map.getAll().onSuccess { (maps) in
            for map in maps {
                BeaconManager.instance.monitorMap(map: map)
            }
        }
	}
    
    internal static func emitOnMain(event: Event<Any>, value: Any) {
        event.emit(value)
    }
}
