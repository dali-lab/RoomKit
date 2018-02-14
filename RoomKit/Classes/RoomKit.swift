//
//  RoomKit.swift
//  Nimble
//
//  Created by John Kotz on 2/2/18.
//

import Foundation
import CoreLocation

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
	internal static var delegates: [RoomKitDelegate?] = []
	
	public static func configure(config: RoomKit.Config, callback: ((RoomKit.error?) -> Void)?) {
		RoomKit.unProtConfig = config
		config.validate { (success, reason) in
			if !success {
				if let callback = callback {
					callback(RoomKit.error.ConfigValidationFailed(reason: reason ?? "unknown"))
				}else{
					fatalError("Config validation failed! Reason: \(reason ?? "unknown")")
				}
			}else{
				callback?(nil)
				startMonitoring()
			}
		}
	}
	
	public static func registerDelegate(delegate: RoomKitDelegate) -> RoomKitDelegateID {
		delegates.append(delegate)
		return delegates.count - 1
	}
	
	public static func unregisterDelegate(i: RoomKitDelegateID) {
		if i < delegates.count {
			delegates[i] = nil
		}
	}
	
	private static func startMonitoring() {
		Map.getAll { (maps, error) in
			guard error != nil else {
				return
			}
			
			for map in maps {
				BeaconManager.getInstance().monitorMap(map: map)
			}
		}
	}
}
