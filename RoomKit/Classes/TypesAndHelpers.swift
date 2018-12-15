//
//  RoomKitDelegate.swift
//  Nimble
//
//  Created by John Kotz on 2/5/18.
//

import Foundation

public protocol RoomKitDelegate {
	func enteredMappedRegion(map: RoomKit.Map)
    func determined(room: RoomKit.Room, on map: RoomKit.Map)
	func exitedMappedRegion(map: RoomKit.Map)
}

public typealias RoomKitDelegateID = Int

extension Notification.Name {
	enum RoomKit {
		static let BeaconsDidRange = Notification.Name("BeaconsDidRange")
	}
}
